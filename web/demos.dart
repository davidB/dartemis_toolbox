import 'dart:html';
import 'package:web_ui/web_ui.dart';
import 'package:dartemis_addons/ease.dart' as ease;
import 'package:dartemis_addons/transform.dart';
import 'package:dartemis_addons/system_animator.dart';
import 'package:dartemis_addons/system_proto2d.dart' as proto;
import 'package:dartemis_addons/system_verlet.dart';
import 'package:dartemis_addons/system_emitter.dart';
import 'package:dartemis_addons/system_particles.dart';
import 'package:dartemis/dartemis.dart';
import 'dart:async';
import 'package:vector_math/vector_math.dart';

void main() {
  // Enable this to use Shadow DOM in the browser.
  //useShadowDom = true;
  // xtag is null until the end of the event loop (known dart web ui issue)
  new Timer(const Duration(), () {
    _setupRoutes();
  });
}

void _setupRoutes() {
  Window.hashChangeEvent.forTarget(window).listen((e) {
    _route(window.location.hash);
  });
  _route(window.location.hash);
}

void _route(String hash) {
  var k = (hash != null && hash.length < 2)? null : hash.substring(2);
  print("k :: ${k}");
  if (k == null) {
    window.location.hash = '/demo0';
    return;
  }
  var initEntities = initDemo[k];
  if (initEntities == null) {
    window.location.hash = '/demo0';
    return;
  }
  activeDemo = k;
  init(initEntities).then(start);
}

Future init(initEntities) => handleError((){
  var world = new World();
  var canvas = query('canvas#demo');
  world.addManager(new PlayerManager());
  world.addManager(new GroupManager());
  //world.addSystem(new System_Physics(false), passive : false);
  world.addSystem(new System_Animator());
  world.addSystem(new System_Emitters());
  world.addSystem(new System_Simulator(step:16));
  // Dart is single Threaded, and System doesn't run in // => component aren't
  // modified concurrently => Render3D.process like other System
  //world.addSystem(new System_Render3D(container), passive : false);
  world.addSystem(new proto.System_Renderer(canvas));
  //if (_audioManager != null) _world.addSystem(new System_Audio(_audioManager, clipProvider : (x) => _assetManager[x]), passive : false);
  //world.addSystem(_hud);
  //world.addSystem(new System_EntityState());
  world.initialize();
  world.deleteAllEntities();
  return initEntities(world);
});


start(world) {
  var lastT = -1;
  loop(num highResTime) => handleError((){
    try {
      world.delta = (lastT > 0)? highResTime - lastT : 0;
      world.process();
      lastT = highResTime;
      window.requestAnimationFrame(loop);
    } on Object catch(e,s) {
      print(e);
      print(s);
    }
  });
  window.requestAnimationFrame(loop);
}

handleError(f) {
  try {
    return f();
  } on Object catch(e,s) {
    print(e);
    print(s);
    throw e;
  }
}

addNewEntity(world, List<Component> cs, {String player, List<String> groups}) {
  var e = world.createEntity();
  cs.forEach((c) => e.addComponent(c));
  if (groups != null) {
    var gm = (world.getManager(GroupManager) as GroupManager);
    groups.forEach((group) => gm.add(e, group));
  }
  if (player != null) {
    (world.getManager(PlayerManager) as PlayerManager).setPlayer(e, player);
  }
  world.addEntity(e);
  return e;
}

Future initDemo0(world) {
  addNewEntity(world, [
    new Transform.w2d(50.0, 50.0, 0.0),
    new proto.Drawable(proto.rect(10.0,10.0, 'blue', 'red'))
  ]);
  return new Future.value(world);
}

@observable
var activeDemo = null;

@observable
final initDemo = {
  'demo0' : (world) {
    addNewEntity(world, [
      new Transform.w2d(50.0, 50.0, 0.0),
      new proto.Drawable(proto.rect(10.0,10.0, fillStyle : 'blue', strokeStyle : 'red'))
    ]);
    addNewEntity(world, [
      new Transform.w2d(0.0, 20.0, 0.0),
      new proto.Drawable(proto.text("Hello World", fillStyle : 'green', strokeStyle : 'yellow'))
    ]);
    return new Future.value(world);
  },
  'demo1' : (world) {
    addNewEntity(world, [
      new Transform.w2d(50.0, 50.0, 0.0),
      new proto.Drawable(proto.rect(10.0,10.0, fillStyle : 'blue', strokeStyle : 'red')),
      new Animatable()
        ..add(new Animation()
          ..onTick = (e, t, t0) {
            var tf = e.getComponent(Transform.CT);
            //Improvement cache ease.loop result
            // use t as ratio because periodicRatio will convert it 0..1
            tf.position3d.x = ease.periodicRatio(ease.linear, 10000)(t, 1000, 100);
            tf.position3d.y = ease.periodicRatio(ease.goback(ease.inElastic), 2000)(t, 100, 100);
            return true;
          }
        )
    ]);
    return new Future.value(world);
  },
  'demo2' : (world) {
//    var e0 = addNewEntity(world, [
//      new Transform.w2d(50.0, 50.0, 0.0),
//      new proto.Drawable(proto.rect(10.0,10.0, fillStyle : 'blue', strokeStyle : 'red')),
//      new Animatable()
//        ..add(new Animation()
//          ..onTick = (e, t, t0) {
//            var tf = e.getComponent(transformCT);
//            //Improvement cache ease.loop result
//            // use t as ratio because periodicRatio will convert it 0..1
//            tf.position3d.x = ease.periodicRatio(ease.linear, 10000)(t, 1000, 100);
//            tf.position3d.y = ease.periodicRatio(ease.goback(ease.inElastic), 2000)(t, 100, 100);
//            return true;
//          }
//        )
//    ]);
    var e1 = addNewEntity(world, [
      new Transform.w2d(50.0, 50.0, 0.0),
      new Emitter()
        ..genParticles = true
        ..counter = steady(10)
        ..initializers.add(particlesStartPosition(
            //constant(new vec3.zero())
            line(new vec3(0.0, 0.0, 0.0), new vec3(800.0, 100.0, 0.0), ease.periodicRatio(ease.random, 3000))
          , true
        ))
        ..initializers.add(addComponents([
          () => new proto.Drawable(proto.particles(3.0, fillStyle : 'red', strokeStyle : 'black')),
          () => new Animatable()
            ..add(new Animation()
              ..onTick = (e, t, t0) {
                var ps = e.getComponent(Particles.CT);
                var ratio = (t - t0) / 10000;
                ps.l.forEach((p) {
                //Improvement cache ease.loop result
                // use t as ratio because periodicRatio will convert it 0..1
                  p.position3d.y += ease.inBounce(ratio, 30, 0);
                });
                return (ratio < 1.0);
              }
              ..onEnd = (e, t, t0) {
                e.deleteFromWorld();
                return false;
              }
            )
        ])),
    ]);
    return new Future.value(world);
  },
//  'demo3' : (world) {
//    sim.friction = 1;
//
//    // entities
//    var segment = sim.lineSegments([new Vec2(20,10), new Vec2(40,10), new Vec2(60,10), new Vec2(80,10), new Vec2(100,10)], 0.02);
//    var pin = segment.pin(0);
//    var pin = segment.pin(4);
//
//    var tire1 = sim.tire(new Vec2(200,50), 50, 30, 0.3, 0.9);
//    var tire2 = sim.tire(new Vec2(400,50), 70, 7, 0.1, 0.2);
//    var tire3 = sim.tire(new Vec2(600,50), 70, 3, 1, 1);
//
//  }
};

