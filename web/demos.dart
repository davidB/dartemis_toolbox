import 'dart:html';
import 'dart:math' as math;
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

@observable
var activeDemo = null;
var activeCtrl = new Future.value(new Ctrl());
void _route(String hash) {
  var k = (hash != null && hash.length < 2)? null : hash.substring(2);
  print("k :: ${k}");
  if (k == null) {
    window.location.hash = '/${initDemo.keys.first}';
    return;
  }
  var initEntities = initDemo[k];
  if (initEntities == null) {
    window.location.hash = '/${initDemo.keys.first}';
    return;
  }
  activeDemo = k;
  activeCtrl.then((x) => x.running = false);
  activeCtrl = init(initEntities).then(start);
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

class Ctrl {
  var running = true;
}

start(world) {
  var lastT = -1;
  var ctrl = new Ctrl();
  loop(num highResTime) => handleError((){
    try {
      world.delta = (lastT > 0)? highResTime - lastT : 0;
      world.process();
      lastT = highResTime;
      if (ctrl.running) window.requestAnimationFrame(loop);
    } on Object catch(e,s) {
      print(e);
      print(s);
    }
  });
  window.requestAnimationFrame(loop);
  return ctrl;
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

const STYLE0 = '#e3e3f8';
const STYLE1 = '#f7e4ed'; //tetrad
const STYLE2 = '#f7f7e4';
const STYLE3 = '#e4f7ed';
const STYLE0_M0 = '#4040f7'; //monochromatique
const STYLE0_M1 = '#9295f7';
@observable
final initDemo = {
  'proto2d' : (world) {
    addNewEntity(world, [
      new Transform.w2d(50.0, 50.0, 0.0),
      new proto.Drawable(proto.rect(10.0,10.0, fillStyle : STYLE0_M1, strokeStyle : STYLE0))
    ]);
    addNewEntity(world, [
      new Transform.w2d(0.0, 20.0, 0.0),
      new proto.Drawable(proto.text("Hello World, choose an other demo in the list", strokeStyle : STYLE0, font: '16px sans-serif'))
    ]);
    return new Future.value(world);
  },
  'proto2d + animatable' : (world) {
    addNewEntity(world, [
      new Transform.w2d(50.0, 50.0, 0.0),
      new proto.Drawable(proto.rect(10.0, 20.0, fillStyle : STYLE0_M1, strokeStyle : STYLE0)),
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
  'proto2d + animatable + emitter (particles)' : (world) {
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
        ..counter = steady(100)
        ..initializers.add(particlesStartPosition(
            //constant(new vec3.zero())
            line(new vec3(0.0, 0.0, 0.0), new vec3(800.0, 100.0, 0.0), ease.periodicRatio(ease.random, 3000))
          , true
        ))
        ..initializers.add(addComponents([
          () => new proto.Drawable(proto.particles(3.0, fillStyle : STYLE0, strokeStyle : STYLE1)),
          () => new Animatable()
            ..add(new Animation()
              ..onTick = () {
                //workaround use a closure to memorize initial state
                var ys0 = [];
                return (e, t, t0) {
                  var ps = e.getComponent(Particles.CT);
                  var ratio = (t - t0) / 10000;
                  if (t == t0) { // store in parent closure
                    // ps.l.map generate a MappedListIterable, with fixed size List I 'force' an optimzed List for call [i]
                    ys0 = new List(ps.l.length);
                    for( var i = ps.l.length - 1; i > -1; --i) {
                      ys0[i] = ps.l[i].position3d.y;
                    }
                  }
                  for( var i = ps.l.length - 1; i > -1; --i) {
                    //Improvement cache ease.loop result
                    // use t as ratio because periodicRatio will convert it 0..1
                    ps.l[i].position3d.y = ease.inBounce(ratio, 200, ys0[i]);
                  }
                  return (ratio < 1.0);
                };
              }()
              ..onEnd = (e, t, t0) {
                e.deleteFromWorld();
              }
            )
        ])),
    ]);
    return new Future.value(world);
  },
  'verlet shapes' : (world) {
    world.getSystem(System_Simulator).friction = 1.0;
    var defaultDraw = proto.drawComponentType([
      new proto.DrawComponentType(Particles.CT, proto.particles(5.0, fillStyle : STYLE0, strokeStyle : STYLE1)),
      new proto.DrawComponentType(Constraints.CT, proto.drawConstraints())
    ]);

    // entities
    var segment = addNewEntity(world,
      makeLineSegments(
        [
          new vec3(20.0, 10.0, 0.0),
          new vec3(40.0, 10.0, 0.0),
          new vec3(60.0, 10.0, 0.0),
          new vec3(80.0, 10.0, 0.0),
          new vec3(100.0,10.0, 0.0)
        ],
        0.02,
        false
      ).toList()..add(new proto.Drawable(defaultDraw))
    );
    pinParticle(segment, 0);
    pinParticle(segment, 4);

    addNewEntity(world, makeTireXY(new vec3(200.0, 50.0, 0.0), 50.0, 30, 0.3, 0.9).toList()..add(new proto.Drawable(defaultDraw)));
    addNewEntity(world, makeTireXY(new vec3(400.0, 50.0, 0.0), 70.0, 7, 0.1, 0.2).toList()..add(new proto.Drawable(defaultDraw)));
    addNewEntity(world, makeTireXY(new vec3(600.0, 50.0, 0.0), 70.0, 3, 1.0, 1.0).toList()..add(new proto.Drawable(defaultDraw)));
    return new Future.value(world);
  },
  'quadtree' : (world) {
    world.getSystem(System_Simulator).friction = 1.0;
    addNewEntity(world, [
      new Transform.w2d(50.0, 50.0, 0.0),
      new Emitter()
      ..genParticles = true
      ..counter = singleWave(500)
      ..initializers.add(particlesStartPosition(
        //constant(new vec3.zero())
          box(new vec3(500.0, 500.0, 0.0), new vec3(400.0, 400.0, 0.0))
        , true
      ))
      ..initializers.add(particlesStartPositionPrevious(box(new vec3.zero(), new vec3(3.0, 3.0, 0.0))))
      ..initializers.add(particlesAddComponents([
        (lg){
          var b = new ParticleInfo0s(lg);
          b.l.forEach((p){
            p.radius = 3.0;
          });
          return b;
        }
      ]))
      ..initializers.add(addComponents([
        () => new proto.Drawable(proto.particleInfo0s(3.0, fillStyle : STYLE0, strokeStyle : STYLE1)),
        () => new Constraints(),
        () => new Animatable()
          ..add(new Animation()
            ..onTick = (e, t, t0) {
               var ps = e.getComponent(Particles.CT);
               var cont = true;
               for( var i = ps.l.length - 1; i > -1; --i) {
                 cont = true;
                 cont = cont && ps.l[i].position3d.y > 0;
                 cont = cont && ps.l[i].position3d.y < 1000;
                 cont = cont && ps.l[i].position3d.x > 0;
                 cont = cont && ps.l[i].position3d.x < 1000;
                 if (!cont) {
                   ps.l[i].position3d.setFrom(ps.l[i].position3dPrevious);
                 }
               }
               return true;//cont;
             }
             ..onEnd = (e, t, t0) {
               e.deleteFromWorld();
             }
          )
      ])),
    ]);
    return new Future.value(world);
  }
};

