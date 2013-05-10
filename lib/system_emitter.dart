// This is free and unencumbered software released into the public domain.
//
// Anyone is free to copy, modify, publish, use, compile, sell, or
// distribute this software, either in source code form or as a compiled
// binary, for any purpose, commercial or non-commercial, and by any
// means.
//
// In jurisdictions that recognize copyright laws, the author or authors
// of this software dedicate any and all copyright interest in the
// software to the public domain. We make this dedication for the benefit
// of the public at large and to the detriment of our heirs and
// successors. We intend this dedication to be an overt act of
// relinquishment in perpetuity of all present and future rights to this
// software under copyright law.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
// IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
// OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
// ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
// OTHER DEALINGS IN THE SOFTWARE.
//
// For more information, please refer to <http://unlicense.org/>

///TODO lot of test (unit, ...)
///TODO benchmark, profiling, optimisation
library system_emitter;

import 'package:dartemis/dartemis.dart';
import 'dart:math' as math;
import 'package:dartemis_addons/transform.dart';
import 'package:dartemis_addons/system_particles.dart';
import 'package:vector_math/vector_math.dart';
import 'package:dartemis_addons/ease.dart' as ease;


/// https://github.com/richardlord/Flint/blob/master/src/org/flintparticles/common/initializers/Initializer.as
typedef  void Initializer(dt, Entity emitter, Iterable<Entity> product);

/// generate a number.
/// (eg. used by [Emitter] of particles to emit per [dt]).
/// [dt] is delta time since last call (the duration of the frame - used for time based updates).
typedef int IntGen(dt);

/// generate a [vec3]
/// (eg. used by [Emitter]'s [Initializer] to found the relative start position or initial velocity,...)).
/// [dt] is delta time since last call (the duration of the frame - used for time based updates).
typedef vec3 Vec3Gen(dt);

class Emitter extends Component {
  static final CT = ComponentTypeManager.getTypeFor(Emitter);

  final initializers = new List<Initializer>();
  IntGen counter = zero();

  /// true => generate one Entity with Particles
  /// false => genere several empty Entity (no Particles,...)
  bool genParticles = true;
}

class System_Emitters extends EntityProcessingSystem {
  ComponentMapper<Emitter> _emitterMapper;
  num _dt = 0;

  System_Emitters() : super(Aspect.getAspectForAllOf([Emitter]));

  void initialize(){
    _emitterMapper = new ComponentMapper<Emitter>(Emitter, world);
  }

  void begin(){
    //TODO use an injected timer
    _dt = world.delta;
  }

  void processEntity(Entity entity) {
    var em = _emitterMapper.get(entity);
    var nb = em.counter(_dt);
    var ne = em.genParticles ? _genParticles(nb) : _genEntities(nb);
    em.initializers.forEach((init) => init(_dt, entity, ne));
    ne.forEach((e) => world.addEntity(e));
//    em.particles.addAll(np);
//    em.activities.forEach((ue) => ue(_dt));
//    em.actions.forEach((up) => up(_dt, em.particles));
  }

  List<Entity> _genEntities( int nb) {
    return new List<Entity>.generate(nb, (i) => world.createEntity());
  }

  List<Entity> _genParticles(int nb) {
    var e = world.createEntity();
    e.addComponent(new Particles(nb));
    return new List<Entity>.filled(1, e);
  }
}

//--- Initializer --------------------------------------------------------------
Initializer particlesStartPosition(Vec3Gen gen, bool fromEmitter) => (dt, Entity emitter, List<Entity> es) {
  var tf = emitter.getComponent(Transform.CT) as Transform;
  var pos = tf.position3d;
  //print("init on ${es.length} entities");
  es.forEach((e) {
    var ps = e.getComponent(Particles.CT) as Particles;
    if (ps != null) {
      //print("init on ${ps.l.length} particles");
      ps.l.forEach((p) {
        p.position3d = gen(dt);
        //print(p.position3d);
        if (fromEmitter) p.position3d.add(pos);
      });
    }
  });
};

Initializer addComponents(List<Function> fs) => (dt, Entity emitter, List<Entity> es) {
  es.forEach((e){
    fs.forEach((f) => e.addComponent(f()));
  });
};

//--- IntGen -------------------------------------------------------------------

/// always return 0.
IntGen zero() => (dt) => 0;

/// [rate] The number of particles to emit per second.
IntGen steady(int rate) => (dt) => (rate * dt) ~/ 1000;

IntGen easingOverTime(ease.Ease easing, num change, num baseValue){
  num _acc = 0;
  return (dt){
    _acc += dt;
    return easing(_acc, change, baseValue).toInt();
  };
}

//--- Vec3Gen ------------------------------------------------------------------

/// always return 0.
Vec3Gen constant(vec3 x) => (dt) => x.clone();

Vec3Gen line(vec3 start, vec3 end, ease.Ease easing){
  var length = end - start;
  var acc = 0.0;
  print(length);
  return (dt){
    var b = length.scaled(easing(acc, 1.0, 0)).add(start);
    acc += dt;
    return b;
  };
}

final VZERO = new vec3.zero();
final VY_AXIS = new vec3(0.0, 1.0, 0.0);
final VX_AXIS = new vec3(1.0, 1.0, 0.0);

vec3 perpendicular(vec3 v) {
  if( v.x == 0 ) {
    return new vec3( 1.0, 0.0, 0.0 );
  } else {
    return new vec3( v.y, -v.x, 0 ).normalize();
  }
}

Vec3Gen cone({vec3 apex, vec3 axis, double angle : 0.0, double height : 10.0, double truncatedHeight : 0.0} ){
  apex = (apex == null) ? new vec3() : apex;
  axis = (axis  == null)?  VY_AXIS : axis;
  var _perp1 = perpendicular(axis);
  var _perp2 = axis.cross( _perp1 ).normalize();
  var random = new math.Random();
  return (dt){
    var h = random.nextDouble();
    h = truncatedHeight + ( 1 - h * h ) * ( height - truncatedHeight );

    var r = random.nextDouble();
    var radiusAtHeight = math.tan( angle / 2 ) * h;
    r = ( 1 - r * r ) * ( h ) * radiusAtHeight;

    var a = random.nextDouble() * 2 * math.PI;
    var p1 = _perp1.clone();
    p1.scale( r * math.cos( a ) );
    var p2  = _perp2.clone();
    p2.scale( r * math.sin( a ) );
    var ax  = axis.clone();
    ax.scale( h );
    p1.add( p2 );
    p1.add( ax );
    return p1.add(apex);
  };
}


