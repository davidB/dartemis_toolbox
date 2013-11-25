library system_verlet_test;

import 'package:unittest/unittest.dart';
import 'package:dartemis_toolbox/system_verlet.dart';
import 'package:dartemis_toolbox/system_particles.dart';
import 'package:dartemis_toolbox/collisions.dart' as collisions;
import 'package:dartemis/dartemis.dart';
import 'package:vector_math/vector_math.dart';

main() {
  var world = _makeWorld();
  group("basic movement",(){
    test("rest particles, no force => no move", (){
      var ps = new Particles(1, inertia0: 0.0);
      _addParticles(world, ps);
      _loop(world,1000/30,2 * 1000);
      expect(ps.position3d[0].x, equals(0.0));
      expect(ps.position3d[0].y, equals(0.0));
      expect(ps.position3d[0].z, equals(0.0));
    });
    test("linear single particles", (){
      var ps = new Particles(1, inertia0: 0.0, withAccs: true);
      var fs = new Forces()
      ..add(new Force_Constante(ps, -1, new Vector3(1.0, 0.0, 0.0)))
      ;
      _addParticles(world, ps, fs);
      _loop(world,1000/30,2 * 1000);
      //TODO what is the expected position x(t) = x(0) + v(0) * dt + a(0) * dt * dt ??
      expect(ps.position3d[0].x, greaterThan(0.0));
      expect(ps.position3d[0].y, equals(0.0));
      expect(ps.position3d[0].z, equals(0.0));
      //print(ps.position3d[0]);
    });
    test("linear 2 linked particles, force on both", (){
      var d = 1.0;
      var ps = new Particles(2, inertia0: 0.0, withAccs: true);
      ps.position3d[0].x = 0.5;
      ps.position3d[1].x = ps.position3d[0].x - d;
      ps.copyPosition3dIntoPrevious();
      var fs = new Forces()
      ..add(new Force_Constante(ps, -1, new Vector3(1.0, 0.0, 0.0)))
      ;
      _addParticles(world, ps, fs);
      _loop(world,1000/30,2 * 1000);
      for(var i = 0; i < 2; i++) {
        expect(ps.position3d[i].x, greaterThan(0.0));
        expect(ps.position3d[i].y, equals(0.0));
        expect(ps.position3d[i].z, equals(0.0));
      }
      expect(ps.position3d[1].x, closeTo(ps.position3d[0].x - d, 0.0001));
      //print(ps.position3d[0]);
    });
    test("linear 2 linked particles, force on one", (){
      var d = 1.0;
      var ps = new Particles(2, inertia0: 0.0, withAccs: true, acc0: new Vector3(0.0, 0.0, 0.0));
      ps.position3d[0].x = 0.5;
      ps.position3d[1].x = ps.position3d[0].x - d;
      ps.copyPosition3dIntoPrevious();
      ps.acc[0].setValues(1.0, 0.0, 0.0);
      var fs = new Forces()
      ..add(new Force_Spring(new Segment(ps, 0, 1), 1.0, 0.1))
      ;
      _addParticles(world, ps, fs);
      _loop(world,1000/30,2 * 1000);
      for(var i = 0; i < 2; i++) {
        //expect(ps.position3d[i].x, greaterThan(0.0));
        expect(ps.position3d[i].y, equals(0.0));
        expect(ps.position3d[i].z, equals(0.0));
      }
      expect(ps.position3d[1].x, closeTo(ps.position3d[0].x - d, 0.0001));
    });
    test("inertia of particles should stop it if no force applied", (){
      var ps = new Particles(1, inertia0: 0.0, withAccs: true);
      var mvt = new Force_Constante(ps, -1, new Vector3(1.0, 0.0, 0.0));
      var fs = new Forces()
      ..add(mvt)
      ;
      _addParticles(world, ps, fs);
      // create movement
      _loop(world,1000/30, 1.0 * 1000);
      var x1 = ps.position3d[0].x;
      expect(ps.position3d[0].x, greaterThan(0.0));
      expect(ps.position3d[0].x, greaterThan(ps.position3dPrevious[0].x));
      mvt.force.setZero(); // or fs.actions.clear()
      _loop(world,1000/30, 1.0 * 1000);
      expect(ps.position3d[0].x, equals(x1));
      expect(ps.position3d[0].x, equals(ps.position3dPrevious[0].x));
    });
  });
}

_makeWorld() {
  var world = new World();
  world.addSystem(new System_Simulator(steps:1));
  world.initialize();
  world.deleteAllEntities();

  world.getSystem(System_Simulator)
    //..globalAccs.y = 0.0
    ..steps = 3
    ..collSpace = new collisions.Space_XY0(new collisions.Checker_T1(), new collisions.Resolver_Backward())
  ;
  return world;
}

_addParticles(world, ps, [c]) {
  var e0 = world.createEntity()
  ..addComponent(ps)
  ;
  if (c != null) e0.addComponent(c);
  world.addEntity(e0);
}
_loop(world, delta, nbDelta) {
  for(var i = 0; i < nbDelta; i++) {
    world.delta = delta;
    world.process();
  }
}

_enableQuadtree(world, canvas, state, displayDebug) {
  var w = canvas.width;
  var h = canvas.height;
  var wm = 10;
  var hm = 10;
  var grid = new collisions.QuadTreeXYAabb(0.0 - wm, 0.0 - hm, w + 2 * wm, h + 2 *hm, 10);

  var sim = world.getSystem(System_Simulator);
  sim.collSpace = (state) ?
      new collisions.Space_QuadtreeXY(sim.collSpace.checker, sim.collSpace.resolver, grid : grid)
      : new collisions.Space_XY0(new collisions.Checker_T1(), new collisions.Resolver_Noop())
  ;
}