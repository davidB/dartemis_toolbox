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
library darticles;

import 'package:dartemis/dartemis.dart';
import 'dart:math' as math;
import 'package:dartemis_addons/system_particles.dart';
import 'package:vector_math/vector_math.dart';

/// Constraint is a class (vs a typedef of Function) to allow
/// others service, function to read data and use it in other way (eg: draw)
abstract class Constraint {
  relax(double stepCoef);
}

class Constraints extends Component {
  static final CT = ComponentTypeManager.getTypeFor(Constraints);
  final l = new List<Constraint>();
}

class System_Simulator extends EntitySystem {
  ComponentMapper<Particles> _particlesMapper;
  ComponentMapper<Constraints> _constraintsMapper;
  //var gravity = new vec3(0, 0.2, 0.0);
  double friction = 0.99;
  //var groundFriction = 0.8;
  var step = 10;

  System_Simulator({this.step}) : super(Aspect.getAspectForAllOf([Particles, Constraints]));

  void initialize(){
    _particlesMapper = new ComponentMapper<Particles>(Particles, world);
    _constraintsMapper = new ComponentMapper<Constraints>(Constraints, world);
  }

  bool checkProcessing() => true;

  void processEntities(ReadOnlyBag<Entity> entities) {
    var particlesG = new List();
    var constraintsG = new List();
    entities.forEach((e){
      var ps = _particlesMapper.get(e);
      if (ps != null) particlesG.add(ps);
      var cs = _constraintsMapper.get(e);
      if (cs != null) constraintsG.add(cs);
    });
    particlesG.forEach((c) {
      if (c == null) return;
      c.l.forEach((p) {
        if (p.position3dPrevious == null)
          p.position3dPrevious = p.position3d.clone();
        // calculate velocity
        var velocity = (p.position3d - p.position3dPrevious).scale(friction);

//        // ground friction
//        if (particles[i].pos.y >= this.height-1 && velocity.length2() > 0.000001) {
//          var m = velocity.length();
//          velocity.x /= m;
//          velocity.y /= m;
//          velocity.mutableScale(m*this.groundFriction);
//        }

        // save last good state
        p.position3dPrevious.setFrom(p.position3d);

        // gravity
        //p.position3d.add(this.gravity);

        // inertia
        p.position3d.add(velocity);
      });
    });

    // relax
    var stepCoef = 1/step;
    constraintsG.forEach((c) {
      for (var i=0; i<step; ++i) {
        c.l.forEach((j) {
          j.relax(stepCoef);
        });
      }
    });

//    // bounds checking
//    for (c in this.composites) {
//      var particles = this.composites[c].particles;
//      for (i in particles)
//        this.bounds(particles[i]);
//    }
  }


}

class Constraint_Distance implements Constraint {
  vec3 a;
  vec3 b;
  double distance2;
  double stiffness;

  Constraint_Distance(this.a, this.b, this.stiffness, [distance1]) {
    distance1 = (distance1 == null)? (a - b).length : distance1;
    distance2 = distance1 * distance1;
  }

  relax(stepCoef) {
    var normal = a - b;
    var m = normal.length2;
    normal.scale((( distance2 - m)/m) *  stiffness * stepCoef);
    a.add(normal);
    b.sub(normal);
  }
}


class Constraint_Pin implements Constraint{
  /// position of the pin
  final vec3 pin;
  final vec3 a;

  Constraint_Pin(vec3 v) : pin = v.clone(), a = v;

  relax(stepCoef) {
    a.setFrom(pin);
  }
}
///TODO support 3D
class Constraint_AngleXY implements Constraint {
  vec3 a;
  vec3 b;
  vec3 c;
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

  _fangle(vec3 v0, vec3 v1) =>
    math.atan2(v0.x * v1.y - v0.y * v1.x, v0.x * v1.x + v0.y * v1.y);

  _fangle2(vec3 v0, vLeft, vRight) =>
    _fangle(vLeft - v0, vRight - v0);

  _frotate(vec3 v0, vec3 origin, theta) {
    var x = v0.x - origin.x;
    var y = v0.y - origin.y;
    return new vec3( x * math.cos(theta) - y * math.sin(theta) + origin.x, x* math.sin(theta) + y* math.cos(theta) + origin.y, v0.z);
  }

}


Iterable<Component> makeTireXY(vec3 origin, double radius, int segments, double spokeStiffness, double treadStiffness) {
  var stride = (2 * math.PI) / segments;

  // particles
  var ps = new Particles(segments + 1);
  for (var i=0; i < segments; ++i) {
    var theta = i * stride;
    var v = ps.l[i].position3d.setFrom(origin);
    v.x = v.x + math.cos(theta) * radius;
    v.y = v.y + math.sin(theta) * radius;
  }
  ps.l[segments].position3d.setFrom(origin);

  // constraints
  var cs = new Constraints();
  for (var i=0; i < segments; ++i) {
    cs.l.add(new Constraint_Distance(ps.l[i].position3d, ps.l[(i + 1) % segments].position3d, treadStiffness));
    cs.l.add(new Constraint_Distance(ps.l[i].position3d, origin, spokeStiffness));
    cs.l.add(new Constraint_Distance(ps.l[i].position3d, ps.l[(i + 5) % segments].position3d, treadStiffness));
  }
  return [ps,cs];
}

pinParticle(Entity e, int index) {
  pinVec3(
    (e.getComponent(Particles.CT) as Particles).l[index].position3d,
    e.getComponent(Constraints.CT)
  );
}

pinVec3(vec3 v, Constraints cs) {
  cs.l.add(new Constraint_Pin(v));
}

Iterable<Component> makeLineSegments(List<vec3> vertices, double stiffness, bool closed) {
  var ps = new Particles();
  ps.l.addAll(vertices.map((x) => new Particle(x)));
  var cs = new Constraints();
  for (var i = 1; i < ps.l.length; ++i) {
    cs.l.add(new Constraint_Distance(ps.l[i].position3d, ps.l[i-1].position3d, stiffness));
  }
  if (closed) {
    cs.l.add(new Constraint_Distance(ps.l[0].position3d, ps.l[ps.l.length - 1].position3d, stiffness));
  }
  return [ps, cs];
}

Iterable<Component> makeCloth(vec3 origin, vec3 width, vec3 height, int segments, int pinMod, double stiffness) {
  var xStride = width / segments;
  var yStride = height / segments;

  var ps = new Particles();
  var cs = new Constraints();
  for (var y=0; y < segments; ++y) {
    var x0 = new Particle(origin + y * yStride);
    ps.l.add(x0);
    if (y > 0)
      cs.l.add(new Constraint_Distance(x0.position3d, ps.l[(y-1)*segments].position3d, stiffness));
    for (var x = 1; x < segments; ++x) {
//      var px = origin.x + x*xStride - width/2 + xStride/2;
//      var py = origin.y + y*yStride - height/2 + yStride/2;
      var xi = = new Particle(x0.position3d + x * xStride);
      ps.l.add(xi);
      cs.l.add(new Constraint_Distance(xi.position3d, ps.l[y*segments+x-1].position3d, stiffness));
      if (y > 0)
        cs.l.add(new Constraint_Distance(xi.position3d, ps.l[(y-1)*segments+x].position3d, stiffness));
    }
  }

  for (var x=0; x< segments; ++x) {
    if ( x % pinMod == 0)
      pinVec3(ps.l[x].position3d, cs);
  }

  return [ps, cs];
}