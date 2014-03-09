// License [CC0](http://creativecommons.org/publicdomain/zero/1.0/)

///TODO lot of test (unit, ...)
///TODO benchmark, profiling, optimisation
library system_verlet;

import 'dart:math' as math;
import 'package:dartemis/dartemis.dart';
import 'package:vector_math/vector_math.dart';
import 'system_particles.dart';
import 'collisions.dart' as collisions;

/// [Force] is a class (vs a typedef of Function) to allow
/// others service, function to read data and use it in other way (eg: draw)
abstract class Force {
  var reaction = false;
  apply();
}

class Forces extends Component {
  static final CT = ComponentTypeManager.getTypeFor(Forces);
  final actions = new List<Force>();
  final reactions = new List<Force>();

  add(Force f) {
    if (f.reaction) {
      reactions.add(f);
    } else {
      actions.add(f);
    }
  }
}

//class Body extends Component {
//  static final CT = ComponentTypeManager.getTypeFor(Body);
//
//  final List<Vector3> shape;
//
//  Body(this.shape);
//}

class System_Simulator extends EntitySystem {
  /*Iterable<Particles>*/ var _particles;
  /*Iterable<Segments>*/ var _segments;
  /*Iterable<Forces>*/ var _forces;

  var steps = 10;
  /// eg : gravity
  final globalAccs = new Vector3(0.0, 0.0, 0.0);
  collisions.Space collSpace;
  double _timestep = -1.0;
  final _motion = new Vector3.zero();
  final _accs = new Vector3.zero();

  System_Simulator({this.steps : 3, collisions.Space space0: null}) :
    super(Aspect.getEmpty()),
    collSpace = (space0 != null)? space0 : new collisions.Space_Noop()
    ;

  void initialize(){
    _particles = world.componentManager.getComponentsByType(Particles.CT);
    _segments = world.componentManager.getComponentsByType(Segments.CT);
    _forces = world.componentManager.getComponentsByType(Forces.CT);
  }

  bool checkProcessing() => true;

  void processEntities(Iterable<Entity> entities) {
    _applyForces();
    _applyIntergrator();
//    _applyConstraintes();
    _applyCollision();
  }

  _applyIntergrator() {
    //for (var pass = (delta ~/ interval) + 1; pass > 0; --pass) {
    //apply time corrected verlet [TCV](http://lonesock.net/article/verlet.html)
    var dt = world.delta.toDouble() / 1000.0;
    if (dt == 0.0) return;
    var timestepPrevious = (_timestep == -1.0) ?dt : _timestep;
    _timestep = dt;
    var timeScale = (_timestep / timestepPrevious);
    var timestep2 = _timestep * _timestep;
    _particles.forEach((ps){
      if (ps == null) return;
      for (var i = ps.length -1 ; i > -1; --i){
        if (!ps.isSim[i]) continue;
        var position3d = ps.position3d[i];
        var position3dPrevious = ps.position3dPrevious[i];
        // calculate velocity
        _motion.setFrom(position3d).sub(position3dPrevious).scale(timeScale * ps.inertia[i]);
        _accs.setFrom(ps.acc[i]);
        // Position Verlet integration
        _accs.scale(timestep2);
        _motion.add(_accs);
        // follow http://lolengine.net/blog/2011/12/14/understanding-motion-in-games
        // Velocity Verlet integration
        // vec3 OldVel = Vel;
        // Vel = Vel + Accel * dt;
        // Pos = Pos + (OldVel + Vel) * 0.5 * dt;
        // Pos = Pos + (2 * OldVel + Accel * dt) * 0.5 * dt;
        //forces.scale(_timestep1);
        //_motion.scale(2.0).add(forces).scale(0.5 * _timestep1);


        // save last good state
        // TODO optim : store future pos in previous and swap previous (with future) and current values in one swap (swap the list), but this optimisation will break existing code that keep vector of position (eg constraint)
        position3dPrevious.setFrom(position3d);
        position3d.add(_motion);
        ps.acc[i].setValues(0.0, 0.0, 0.0);
      }
    });
  }

  _applyCollision() {
    collSpace.reset();
    _particles.forEach((ps){
      if (ps != null) collSpace.addParticles(ps);
    });
    _segments.forEach((e){
      if (e != null) e.l.forEach((s) => collSpace.addSegment(s));
    });
    collSpace.handleCollision();
  }

  _applyForces() {
    _particles.forEach((ps){
      if (ps != null) {
        for(var i=0; i < ps.length; i++) {
          ps.acc[i].setFrom(globalAccs);
        }
      }
    });
    _forces.forEach((fs){
      if (fs != null) fs.actions.forEach((x) => x.apply());
    });
    _forces.forEach((fs){
      if (fs != null) fs.reactions.forEach((x) => x.apply());
    });
  }
}

class Force_Constante extends Force {
  final reaction = false;
  final Particles ps;
  final int i;
  final Vector3 force;

  Force_Constante(this.ps, this.i, this.force);

  apply() {
    if (i < 0) {
      for (var j = 0; j < ps.length; j++) {
        ps.acc[j].add(force);
      }
    } else {
      ps.acc[i].add(force);
    }
  }
}

class Force_Spring extends Force {
  final Segment segment;
  final reaction = true;
  double stiffness;
  double damping;
  double stiffnessRatioLonger = 1.0;
  double _restLength;
  Vector3 _dir = new Vector3.zero();
  Vector3 _fa = new Vector3.zero();
  Vector3 _fb = new Vector3.zero();

  Force_Spring(this.segment, this.stiffness, this.damping, {restLength : -1}) {
    _restLength = (restLength < 0) ? (segment.ps.position3d[segment.i1] - segment.ps.position3d[segment.i2]).length : restLength;
  }

//  factory Force_Spring.fromParticles(ps, i1, i2, stiffness, damping, [collide = 0]) {
//    return new Force_Spring(new Segment(ps, i1, i2, collide), stiffness, damping);
//  }

  apply() {
    var a = segment.ps.position3d[segment.i1];
    var b = segment.ps.position3d[segment.i2];
    _dir.setFrom(a).sub(b);
    var l = _dir.length;
    if (l == 0) {
      //TODO
    } else {
      var diff = ( _restLength - l);
      if (diff == 0) return;
      _dir.normalize();
      // spring force
      //_fa.setFrom(segment.ps.acc[segment.i1]).add(segment.ps.acc[segment.i2]).scale(0.5);
      //print(_fa.dot(_dir).abs());
      var fs = stiffness * diff;
      if (diff < 0) fs *= stiffnessRatioLonger;
      // spring damping force
      //var fd = _fa.setFrom(segment.ps.acc[segment.i1]).sub(segment.ps.acc[segment.i2]).dot(_dir);
      _fa.setFrom(segment.ps.position3d[segment.i1]).sub(segment.ps.position3dPrevious[segment.i1]);
      _fb.setFrom(segment.ps.position3d[segment.i2]).sub(segment.ps.position3dPrevious[segment.i2]);
      //var fd = segment.ps.acc[segment.i1].dot(segment.ps.acc[segment.i2]);
      var fd = _fa.dot(_fb);
      fd = damping * fd;
      //if (fd != 0.0) print(fd);
      //TODO integrate
      _dir.scale(fs + fd);
      segment.ps.acc[segment.i1].add(_dir);
      segment.ps.acc[segment.i2].sub(_dir);
      //print(segment.ps.acc[segment.i1]);
    }
  }
}

Iterable<Component> makeTireXY(Vector3 origin, double radius, int segments, double spokeStiffness, double treadStiffness, double spokeDamping, double treadDamping, ParticlesConstructor genP) {
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
  var ss = new Segments();
  var fs = new Forces();
  for (var i = 0; i < segments; ++i) {
    var s = ss.add(new Segment(ps, i, (i + 1) % segments));
    fs.add(new Force_Spring(s, treadStiffness, treadDamping));
    s = ss.add(new Segment(ps, i, segments));
    fs.add(new Force_Spring(s, spokeStiffness, spokeDamping));
    if (segments > 5) {
      s = ss.add(new Segment(ps, i, (i + 2) % segments));
      fs.add(new Force_Spring(s, treadStiffness, treadDamping));
    }
  }
  return [ps,ss,fs];
}

Iterable<Component> makeLineSegments(List<Vector3> vertices, double stiffness, double damping, bool closed, ParticlesConstructor genP) {
  var ps = genP(vertices.length);
  for(int i = 0; i < ps.length; ++i) {
    ps.position3d[i].setFrom(vertices[i]);
  }
  ps.copyPosition3dIntoPrevious();
  var ss = new Segments();
  var fs = new Forces();
  for (var i = 1; i < ps.length; ++i) {
    var s = ss.add(new Segment(ps, i, i-1));
    fs.add(new Force_Spring(s, stiffness, damping));
  }
  if (closed) {
    var s = ss.add(new Segment(ps, 0, ps.length - 1));
    fs.add(new Force_Spring(s, stiffness, damping));
  }
  return [ps,ss,fs];
}

Iterable<Component>  makeParallelogram(Vector3 origin, Vector3 width, Vector3 height, double stiffness, double damping, ParticlesConstructor genP) {
  return makeLineSegments([origin, origin + width, origin + width + height, origin + height], stiffness, damping, true, genP);
}

Iterable<Component> makeCloth(Vector3 origin, Vector3 width, Vector3 height, int segments, int pinMod, double stiffness, double damping, ParticlesConstructor genP) {
  var xStride = width / segments.toDouble();
  var yStride = height / segments.toDouble();
  var diag = width - height;
  var diagl = diag.length;
  var xStiffness = stiffness * width.length / diagl;
  var yStiffness = stiffness * height.length / diagl;

  var ps = genP(segments * segments);
  var ss = new Segments();
  var fs = new Forces();
  for (var y=0; y < segments; ++y) {
    var x0 = ps.position3d[y*segments + 0];
    x0.setFrom(yStride).scale(y.toDouble()).add(origin);
    if (y > 0) {
      var s = ss.add(new Segment(ps, y*segments + 0, (y-1)*segments));
      fs.add(new Force_Spring(s, yStiffness, damping));
    }
    for (var x = 1; x < segments; ++x) {
//      var px = origin.x + x*xStride - width/2 + xStride/2;
//      var py = origin.y + y*yStride - height/2 + yStride/2;
      var xi = ps.position3d[y*segments + x];
      xi.setFrom(xStride).scale(x.toDouble()).add(x0);
      var s = ss.add(new Segment(ps, y*segments + x, y*segments+x-1));
      fs.add(new Force_Spring(s, xStiffness, damping));
      if (y > 0) {
        s = ss.add(new Segment(ps, y*segments + x, (y-1)*segments+x));
        fs.add(new Force_Spring(s, yStiffness, damping));
        //cs.l.add(new Constraint_Distance.fromParticles(ps, y*segments + x, (y-1)*segments+x-1, stiffness));
      }
    }
  }
  ps.copyPosition3dIntoPrevious();

  for (var x=0; x< segments; ++x) {
    if ( x % pinMod == 0)
      ps.isSim[x] = false;
  }

  return [ps,ss,fs];
}


pinParticle(Entity e, int index) {
  (e.getComponent(Particles.CT) as Particles).isSim[index] = false;
}

setCollideOfSegment(Entity e, collide) {
  var ss = e.getComponent(Segments.CT);
  if (ss != null) {
    ss.l.forEach((s) => s.collide = collide);
  }
}
