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

import 'dart:math' as math;
import 'package:dartemis/dartemis.dart';
import 'package:vector_math/vector_math.dart';
import 'system_particles.dart';
import 'system_transform.dart';
import 'ease.dart' as ease;
import 'utils_math.dart';


/// https://github.com/richardlord/Flint/blob/master/src/org/flintparticles/common/initializers/Initializer.as
typedef  void Initializer(dt, Entity emitter, Iterable<Entity> product);

/// generate a number.
/// (eg. used by [Emitter] of particles to emit per [dt]).
/// [dt] is delta time since last call (the duration of the frame - used for time based updates).
typedef int IntGen(dt);

/// generate a [Vector3]
/// (eg. used by [Emitter]'s [Initializer] to found the relative start position or initial velocity,...)).
/// [dt] is delta time since last call (the duration of the frame - used for time based updates).
typedef Vector3 Vector3GenInto(Vector3 v, dt);

class Emitter extends Component {
  static final CT = ComponentTypeManager.getTypeFor(Emitter);

  final initializers = new List<Initializer>();
  IntGen counter = zero();

  /// not null => generate one Entity with Particles
  /// null => genere several empty Entity (no Particles,...)
  ParticlesConstructor genParticles = null;
  bool once = false;

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
    var ne = (em.genParticles != null) ? _genParticles(nb, em.genParticles) : _genEntities(nb);
    em.initializers.forEach((init) => init(_dt, entity, ne));
    ne.forEach((e) => world.addEntity(e));
//    em.particles.addAll(np);
//    em.activities.forEach((ue) => ue(_dt));
//    em.actions.forEach((up) => up(_dt, em.particles));
    if (em.once) entity.deleteFromWorld();
  }

  List<Entity> _genEntities(int nb) {
    return new List<Entity>.generate(nb, (i) => world.createEntity());
  }

  List<Entity> _genParticles(int nb, ParticlesConstructor pc) {
    var e = world.createEntity();
    e.addComponent(pc(nb));
    return new List<Entity>.filled(1, e);
  }

}

//--- Initializer --------------------------------------------------------------
processParticules(List<Entity> es, f(Particules, i)) {
  es.forEach((e) {
    var ps = e.getComponent(Particles.CT) as Particles;
    if (ps != null) {
      //print("init on ${ps.l.length} particles");
      for(var i = 0; i < ps.length; i++) {
        f(ps, i);
      }
    }
  });
}
Initializer particlesStartPosition(Vector3GenInto gen, bool fromEmitter) => (dt, Entity emitter, List<Entity> es) {
  var tf = emitter.getComponent(Transform.CT) as Transform;
  var pos = tf.position3d;
  processParticules(es, (ps, i) {
    gen(ps.position3d[i], dt);
    //print(p.position3d);
    if (fromEmitter) ps.position3d[i].add(pos);
  });
};

/// used to define a initial velocity if Verlet Simulator, also add Constraints Component
/// should add after a Initializer that set position3d of particules
Initializer particlesStartPositionPrevious(Vector3GenInto gen, bool fromEmitter) => (dt, Entity emitter, List<Entity> es) {
  var m4 = new Matrix4.identity();
  if (fromEmitter) {
    var tf = emitter.getComponent(Transform.CT) as Transform;
    m4.rotateX(tf.rotation3d.x);
    m4.rotateY(tf.rotation3d.y);
    m4.rotateZ(tf.rotation3d.z);
  }
  processParticules(es, (ps, i) {
     var v = gen(ps.position3dPrevious[i], dt);
     v = m4.rotate3(v);
     v.add(ps.position3d[i]);
  });
};

Initializer addComponents(List<Function> fs) => (dt, Entity emitter, List<Entity> es) {
  es.forEach((e){
    fs.forEach((f) => e.addComponent(f()));
  });
};

Initializer particlesAddComponents(List<Function> fs) => (dt, Entity emitter, List<Entity> es) {
  es.forEach((e){
    var ps = e.getComponent(Particles.CT) as Particles;
    if (ps != null) {
      fs.forEach((f) => e.addComponent(f(ps.length)));
    }
  });
};

//--- IntGen -------------------------------------------------------------------

/// always return 0.
IntGen zero() => (dt) => 0;

IntGen singleWave(v) => ((dt) => (dt == 0) ? v : 0);

/// [rate] The number of particles to emit per second.
///TODO manage case where rate * dt < 1000
IntGen steady(int rate) {
  num _acc = 0;
  num _rateInv = (rate > 0)? 1000/rate : 0;
  return (dt){
    _acc += dt;
    var b = ((rate * _acc) / 1000).round();
    //print("${b * 1000/_acc} ---- ${b} --- ${_acc}");
    _acc -= b * _rateInv;
    return b;
  };
}
IntGen easingOverTime(ease.Ease easing, num change, num baseValue){
  num _acc = 0.0;
  return (dt){
    _acc += dt;
    return easing(_acc, change, baseValue).toInt();
  };
}

//--- Vector3Gen ------------------------------------------------------------------
final _random = new math.Random();

/// always return a clone of x.
Vector3GenInto constant(Vector3 x) => (v, dt) => v.setFrom(x);

Vector3GenInto box(Vector3 center, Vector3 offsets) => (v, dt){
  v.setFrom(center);
  v.x += (_random.nextDouble() - 0.5) * 2 * offsets.x;
  v.y += (_random.nextDouble() - 0.5) * 2 * offsets.y;
  v.z += (_random.nextDouble() - 0.5) * 2 * offsets.z;
  return v;
};

Vector3GenInto line(Vector3 start, Vector3 end, ease.Ease easing){
  var length = end - start;
  var acc = 0.0;
  return (v, dt){
    v.setFrom(length).scale(easing(acc, 1.0, 0)).add(start);
    acc += dt;
    return v;
  };
}

Vector3 perpendicular(Vector3 v) {
  if( v.x == 0 ) {
    return new Vector3( 1.0, 0.0, 0.0 );
  } else {
    return new Vector3( v.y, -v.x, 0.0 ).normalize();
  }
}

Vector3GenInto cone({Vector3 apex, Vector3 axis, double angle : 0.0, double height : 10.0, double truncatedHeight : 0.0} ){
  apex = (apex == null) ? new Vector3.zero() : apex;
  axis = (axis  == null)?  VY_AXIS : axis;
  var _perp1 = perpendicular(axis);
  var _perp2 = axis.cross( _perp1 ).normalize();
  return (v, dt){
    var h = _random.nextDouble();
    h = truncatedHeight + ( 1 - h * h ) * ( height - truncatedHeight );

    var r = _random.nextDouble();
    var radiusAtHeight = math.tan( angle / 2 ) * h;
    r = ( 1 - r * r ) * ( h ) * radiusAtHeight;

    var a = _random.nextDouble() * 2 * math.PI;
    var p1 = _perp1.clone();
    p1.scale( r * math.cos( a ) );
    var p2  = _perp2.clone();
    p2.scale( r * math.sin( a ) );
    return v.setFrom(axis)
      .scale( h )
      .add(p1)
      .add(p2)
      .add(apex)
      ;
  };
}


