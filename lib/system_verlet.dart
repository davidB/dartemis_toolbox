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
library system_verlet;

import 'dart:math' as math;
import 'package:dartemis/dartemis.dart';
import 'package:vector_math/vector_math.dart';
import 'system_particles.dart';
import 'utils_math.dart' as math2;
import 'collisions.dart' as collisions;

/// Constraint is a class (vs a typedef of Function) to allow
/// others service, function to read data and use it in other way (eg: draw)
abstract class Constraint {
  relax(double stepCoef);
}

class Constraints extends Component {
  static final CT = ComponentTypeManager.getTypeFor(Constraints);
  final l = new List<Constraint>();
}

class Body extends Component {
  static final CT = ComponentTypeManager.getTypeFor(Body);

  final List<Vector3> shape;

  Body(this.shape);
}

class System_Simulator extends IntervalEntitySystem {
  ComponentMapper<Particles> _particlesMapper;
  ComponentMapper<Constraints> _constraintsMapper;
  ComponentMapper<Body> _bodiesMapper;
  var steps = 10;
  /// eg : gravity
  final globalForces = new Vector3(0.0, 0.0, 0.0);
  collisions.Space collSpace;
  final double interval; // = 1000.0/30.0;
  double _timestep = -1.0;
  double ndamping = 1.0;
  get damping => 1.0 - ndamping;
  set damping(double v){ ndamping = 1.0 - math2.clamp(v, 1.0, 0.0); }

  System_Simulator({this.steps : 3, interval0 : 1000.0/30, collisions.Space space0: null}) :
    super(interval0, Aspect.getAspectForAllOf([Particles, Constraints])),
    interval = interval0,
    collSpace = (space0 != null)? space0 : new collisions.Space_Noop()
    ;

  void initialize(){
    _particlesMapper = new ComponentMapper<Particles>(Particles, world);
    _constraintsMapper = new ComponentMapper<Constraints>(Constraints, world);
    _bodiesMapper = new ComponentMapper<Body>(Body, world);
  }

  void processEntities(ReadOnlyBag<Entity> entities) {
    var deplacement = new Vector3.zero();
    var forces = new Vector3.zero();
    collSpace.clear();
    //for (var pass = (delta ~/ interval) + 1; pass > 0; --pass) {
    //apply time corrected verlet [TCV](http://lonesock.net/article/verlet.html)
    var dt = delta.toDouble() / 1000;
    var timestepPrevious = (_timestep == -1) ?dt : _timestep;
    _timestep = dt  ;
    var deplacementScale = (_timestep / timestepPrevious) * ndamping;
    var timestep2 = _timestep * _timestep;
    entities.forEach((e){
      var ps = _particlesMapper.get(e);
      if (ps == null) return;
      for (var i = ps.length -1 ; i > -1; --i){
        var position3d = ps.position3d[i];
        var position3dPrevious = ps.position3dPrevious[i];
        // calculate velocity
        deplacement.setFrom(position3d).sub(position3dPrevious).scale(deplacementScale);

//        // ground friction
//        if (particles[i].pos.y >= this.height-1 && velocity.length2() > 0.000001) {
//          var m = velocity.length();
//          velocity.x /= m;
//          velocity.y /= m;
//          velocity.mutableScale(m*this.groundFriction);
//        }

        // forces (include gravity,...)
        // fs.l should be same length that ps.l
        forces.setFrom(globalForces);
        forces.add(ps.accForces[i]);
        // Position Verlet integration
        forces.scale(timestep2);
        deplacement.add(forces);
        // follow http://lolengine.net/blog/2011/12/14/understanding-motion-in-games
        // Velocity Verlet integration
        // vec3 OldVel = Vel;
        // Vel = Vel + Accel * dt;
        // Pos = Pos + (OldVel + Vel) * 0.5 * dt;
        // Pos = Pos + (2 * OldVel + Accel * dt) * 0.5 * dt;
        //forces.scale(_timestep1);
        //deplacement.scale(2.0).add(forces).scale(0.5 * _timestep1);


        // save last good state
        // TODO optim : store future pos in previous and swap previous (with future) and current values in one swap (swap the list), but this optimisation will break existing code that keep vector of position (eg constraint)
        position3dPrevious.setFrom(position3d);
        position3d.add(deplacement);
      }
      collSpace.addParticles(ps);
    });
    // iterate collisions + constraints
    var stepCoef = 1.0/steps;
    //var bodies = maps(entities, _bodiesMapper);
    var constraints = maps(entities, _constraintsMapper);

    for(int step = 0; step < steps; ++step ) { //Repeat this a few times to give more exact results
//    // bounds checking
//    //TODO define bounds as constraintes
//    for (c in this.composites) {
//      var particles = this.composites[c].particles;
//      for (i in particles)
//        this.bounds(particles[i]);
//    }

      //relax Constraints (include Edge) correction step
      //TODO optimize the loop
      //TODO check if relax should be done in the same loop as collision
      //TODO check if relax should be done once constraint per step or every constraint per step
      for (int i = 0; i < constraints.length; i++) {
        var c = constraints[i];
        if (c == null) continue;
        c.l.forEach((j) {
          j.relax(stepCoef);
        });
      };
    }

    for(var i = 0; i < constraints.length; ++i) {
      var cs = constraints[i];
      for(var j = 0; j < cs.l.length; ++j) {
        var c = cs.l[j];
        if(c is Constraint_Distance) {
          collSpace.addSegment(c.segment);
        }
      }
    }
    collSpace.handleCollision();

  }

  maps(entities, mapper) {
    var s = new List(entities.size);
    for(var i = 0; i < entities.size; i++) {
      var e = entities[i];
      var c = mapper.getSafe(e);
      if (c != null) {
        s[i] = c;
      }
    }
    return s;
  }

}

class Constraint_Distance implements Constraint {
  final Segment segment;
  double stiffness;
  double _distance2;
  Vector3 _stick = new Vector3.zero();

  Constraint_Distance(this.segment, this.stiffness) {
    _distance2 = (segment.ps.position3d[segment.i1] - segment.ps.position3d[segment.i2]).length;
  }

  factory Constraint_Distance.fromParticles(ps, i1, i2, stiffness, [collide = 0]) {
    return new   Constraint_Distance(new Segment(ps, i1, i2, collide), stiffness);
  }

  //get a => segment.ps.position3d[segment.i1];
  //get b => segment.ps.position3d[segment.i2];

  relax(stepCoef) {
    var a = segment.ps.position3d[segment.i1];
    var b = segment.ps.position3d[segment.i2];
    _stick.setFrom(a).sub(b);
    var l = _stick.length;
    var diff = ( _distance2 - l)/l;
    _stick.scale(diff *  stiffness * stepCoef);
    var ma = segment.ps.mass[segment.i1];
    var mb = segment.ps.mass[segment.i1];
    var mw = (ma + mb);// * stiffness;
    a.add(_stick.scale(ma / mw));
    b.sub(_stick.scale(mb / ma)); // _stick(mb / mw)
  }
}

class Constraint_Pin implements Constraint{
  /// position of the pin
  final Vector3 pin;
  final Vector3 a;

  Constraint_Pin(Vector3 v) : pin = v.clone(), a = v;

  relax(stepCoef) {
    a.setFrom(pin);
  }
}
///TODO support 3D
class Constraint_AngleXY implements Constraint {
  Vector3 a;
  Vector3 b;
  Vector3 c;
  double stiffness;
  double _angle;
  Constraint_AngleXY(this.a, this.b, this.c, this.stiffness) {
    _angle = _fangle2(b, a, c);
  }

  relax(stepCoef) {
    var angle = _fangle2(b, a, c);
    var diff = angle - _angle;

    if (diff <= - math.PI)
      diff += 2 * math.PI;
    else if (diff >= math.PI)
      diff -= 2 * math.PI;

    diff *= stepCoef * stiffness;

    a = _frotate(a, b, diff);
    c = _frotate(c, b, -diff);
    b = _frotate(b, a, diff);
    b = _frotate(b, c, -diff);
  }

  _fangle(Vector3 v0, Vector3 v1) =>
    math.atan2(v0.x * v1.y - v0.y * v1.x, v0.x * v1.x + v0.y * v1.y);

  _fangle2(Vector3 v0, vLeft, vRight) =>
    _fangle(vLeft - v0, vRight - v0);

  _frotate(Vector3 v0, Vector3 origin, theta) {
    var x = v0.x - origin.x;
    var y = v0.y - origin.y;
    return new Vector3( x * math.cos(theta) - y * math.sin(theta) + origin.x, x* math.sin(theta) + y* math.cos(theta) + origin.y, v0.z);
  }

}


Iterable<Component> makeTireXY(Vector3 origin, double radius, int segments, double spokeStiffness, double treadStiffness, ParticlesConstructor genP) {
  var stride = (2 * math.PI) / segments;

  // particles
  var ps = genP(segments + 1);
  for (var i=0; i < segments; ++i) {
    var theta = i * stride;
    var v = ps.position3d[i].setFrom(origin);
    v.x = v.x + math.cos(theta) * radius;
    v.y = v.y + math.sin(theta) * radius;
  }
  ps.position3d[segments].setFrom(origin);
  ps.copyPosition3dIntoPrevious();
  // constraints
  var cs = new Constraints();
  for (var i=0; i < segments; ++i) {
    cs.l.add(new Constraint_Distance.fromParticles(ps, i, (i + 1) % segments, treadStiffness));
    cs.l.add(new Constraint_Distance.fromParticles(ps, i, segments, spokeStiffness));
    cs.l.add(new Constraint_Distance.fromParticles(ps, i, (i + 5) % segments, treadStiffness));
  }
  return [ps,cs];
}

Iterable<Component> makeLineSegments(List<Vector3> vertices, double stiffness, bool closed, ParticlesConstructor genP) {
  var ps = genP(vertices.length);
  for(int i = 0; i < ps.length; ++i) {
    ps.position3d[i].setFrom(vertices[i]);
  }
  ps.copyPosition3dIntoPrevious();
  var cs = new Constraints();
  for (var i = 1; i < ps.position3d.length; ++i) {
    cs.l.add(new Constraint_Distance.fromParticles(ps, i, i-1, stiffness));
  }
  if (closed) {
    cs.l.add(new Constraint_Distance.fromParticles(ps, 0, ps.position3d.length - 1, stiffness));
  }
  return [ps, cs];
}

Iterable<Component>  makeParallelogram(Vector3 origin, Vector3 width, Vector3 height, double stiffness, ParticlesConstructor genP) {
  return makeLineSegments([origin, origin + width, origin + width + height, origin + height], stiffness, true, genP);
}

Iterable<Component> makeCloth(Vector3 origin, Vector3 width, Vector3 height, int segments, int pinMod, double stiffness, ParticlesConstructor genP) {
  var xStride = width / segments.toDouble();
  var yStride = height / segments.toDouble();
  var diag = width - height;
  var diagl = diag.length;
  var xStiffness = stiffness * width.length / diagl;
  var yStiffness = stiffness * height.length / diagl;

  var ps = genP(segments * segments);
  var cs = new Constraints();
  for (var y=0; y < segments; ++y) {
    var x0 = ps.position3d[y*segments + 0];
    x0.setFrom(yStride).scale(y.toDouble()).add(origin);
    if (y > 0)
      cs.l.add(new Constraint_Distance.fromParticles(ps, y*segments + 0, (y-1)*segments, yStiffness));
    for (var x = 1; x < segments; ++x) {
//      var px = origin.x + x*xStride - width/2 + xStride/2;
//      var py = origin.y + y*yStride - height/2 + yStride/2;
      var xi = ps.position3d[y*segments + x];
      xi.setFrom(xStride).scale(x.toDouble()).add(x0);
      cs.l.add(new Constraint_Distance.fromParticles(ps, y*segments + x, y*segments+x-1, xStiffness));
      if (y > 0) {
        cs.l.add(new Constraint_Distance.fromParticles(ps, y*segments + x, (y-1)*segments+x, yStiffness));
        //cs.l.add(new Constraint_Distance.fromParticles(ps, y*segments + x, (y-1)*segments+x-1, stiffness));
      }
    }
  }
  ps.copyPosition3dIntoPrevious();

  for (var x=0; x< segments; ++x) {
    if ( x % pinMod == 0)
      pinVector3(ps.position3d[x], cs);
  }

  return [ps, cs];
}


pinParticle(Entity e, int index) {
  pinVector3(
    (e.getComponent(Particles.CT) as Particles).position3d[index],
    e.getComponent(Constraints.CT)
  );
}

pinVector3(Vector3 v, Constraints cs) {
  cs.l.add(new Constraint_Pin(v));
}

setCollideOfSegment(Entity e, collide) {
  (e.getComponent(Constraints.CT) as Constraints).l.forEach((c){
    if (c is Constraint_Distance) c.segment.collide = collide;
  });
}