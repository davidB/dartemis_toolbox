library demos;

import 'dart:html';
import 'dart:math' as math;
import 'package:dartemis_toolbox/ease.dart' as ease;
import 'package:dartemis_toolbox/system_transform.dart';
import 'package:dartemis_toolbox/system_animator.dart';
import 'package:dartemis_toolbox/system_proto2d.dart' as proto;
import 'package:dartemis_toolbox/collisions.dart' as collisions;
import 'package:dartemis_toolbox/system_verlet.dart';
import 'package:dartemis_toolbox/system_emitter.dart';
import 'package:dartemis_toolbox/system_particles.dart';
import 'package:dartemis_toolbox/colors.dart';
import 'package:dartemis_toolbox/utils_dartemis.dart';
import 'package:dartemis_toolbox/startstopstats.dart';
import 'package:dartemis/dartemis.dart';
import 'dart:async';
import 'package:vector_math/vector_math.dart';
import 'package:html_toolbox/html_toolbox.dart';
import 'package:html_toolbox/widgets_charts.dart';

part 'demos/proto2d.dart';

void main() {
  // Enable this to use Shadow DOM in the browser.
  //useShadowDom = true;
  // xtag is null until the end of the event loop (known dart web ui issue)
  new Timer(const Duration(), () {
    _setupRoutes();
    _updateMenuEntry(null);
  });
}

void _setupRoutes() {
  Window.hashChangeEvent.forTarget(window).listen((e) {
    _route(window.location.hash);
  });
  _route(window.location.hash);
}



var activeCtrl = new Future.value(new Ctrl());
void _route(String hash) {
  var k = (hash != null && hash.length < 2)? null : hash.substring(2);
  if (k == null) {
    window.location.hash = '/${initDemo.keys.first}';
    return;
  }
  var initEntities = initDemo[k];
  if (initEntities == null) {
    window.location.hash = '/${initDemo.keys.first}';
    return;
  }
  _updateMenuEntry(k);
  activeCtrl.then((x) => x.running = false);
  activeCtrl = init(initEntities).then(start);
}

void _updateMenuEntry(active) {
  if (_tmpl == null) {
    _tmpl = new MicroTemplate(querySelector("script.menuEntry"));
  }
  var items = initDemo.keys.map((x) =>{
    "k" : x,
    "activeClass" : (x == active) ? 'active' : ''
  }).toList();
  _tmpl.apply(items);
}
var _tmpl;

Future init(initEntities) => handleError((){
  var world = new World();
  var canvas = querySelector('canvas#demo');
  world.addManager(new PlayerManager());
  world.addManager(new GroupManager());
  //world.addSystem(new System_Physics(false), passive : false);
  world.addSystem(new System_Animator());
  world.addSystem(new System_Emitters());
  world.addSystem(new System_Simulator(steps:1));
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
  var _statsLoopTxt = querySelector('#statsLoop') as PreElement;
  var _statsLoopChart = new ChartT()
  ..el = querySelector("#statsLoop_chart")
  ;
  var values = new List<double>(2);
  //var v0 = random.nextDouble() * 100.0;

  var statsL = new StartStopStats()
    ..displayFct = (stats, now) {
      if (now - stats.displayLast > 1000) {
        stats.displayLast = now;
        var fps = 1000/stats.avg;
        if (_statsLoopTxt != null){
          var msg = "avg : ${stats.avg}\nmax : ${stats.max}\nmin : ${stats.min}\nfps : ${fps}\n";
          _statsLoopTxt.text = msg;
        }
        if (_statsLoopChart != null){
          values[0] = stats.avg;
          values[1] = fps;
          _statsLoopChart.push(values);
        }

        if (now - stats.resetLast > 3000) stats.reset();
      }
    }
  ;
  var deltaMax = 1000.0 / 30;
  loop(num highResTime) => handleError((){
    if (ctrl.running) window.requestAnimationFrame(loop);
    statsL.start();
    try {
      world.delta = (lastT > 0)? math.min(highResTime - lastT, deltaMax) : 0;
      world.process();
      lastT = highResTime;
    } on Object catch(e,s) {
      print(e);
      print(s);
    }
    statsL.stop();
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

var foregroundcolor = 0xe3e3f8ff;
var foregroundcolors = hsl_tetrad(irgba_hsl(foregroundcolor)).map((hsl) => irgba_rgbaString(hsl_irgba(hsl))).toList();
var foregroundcolorsM = hsv_monochromatic(irgba_hsv(foregroundcolor), 4).map((hsv) => irgba_rgbaString(hsv_irgba(hsv))).toList(); //monochromatique

final initDemo = {
  'proto2d' : demo_proto2d,
  'proto2d + animatable' : (world) {
    addNewEntity(world, [
      new Transform.w2d(50.0, 50.0, 0.0),
      new proto.Drawable(proto.rect(10.0, 20.0, fillStyle : foregroundcolorsM[1], strokeStyle : foregroundcolorsM[0])),
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

    world.getSystem(System_Simulator)
    ..globalAccs.y = 0.0
    ..steps = 1
    ..collSpace = new collisions.Space_XY0(new collisions.Checker_T1(), new collisions.Resolver_Noop())
    ;
    enableQuadtree(world, querySelector('canvas#demo'), false, false);
    addNewEntity(world, [
      new Transform.w2d(50.0, 50.0, 0.0),
      new Emitter()
        ..genParticles = ((nb) => new Particles(nb, inertia0: 0.0, isSim0 : false))
        ..counter = steady(100)
        ..initializers.add(particlesStartPosition(
            //constant(new Vector3.zero())
            line(new Vector3(0.0, 0.0, 0.0), new Vector3(800.0, 100.0, 0.0), ease.periodicRatio(ease.random, 3000))
          , true
        ))
        ..initializers.add(addComponents([
          () => new proto.Drawable(proto.particles(3.0, fillStyle : foregroundcolors[0], strokeStyle : foregroundcolorsM[1])),
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
                    ys0 = new List(ps.position3d.length);
                    for( var i = ps.position3d.length - 1; i > -1; --i) {
                      ys0[i] = ps.position3d[i].y;
                    }
                  }
                  for( var i = ps.position3d.length - 1; i > -1; --i) {
                    //Improvement cache ease.loop result
                    // use t as ratio because periodicRatio will convert it 0..1
                    ps.position3d[i].y = ease.inBounce(ratio, 200, ys0[i]);
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
    addNewEntity(world, [
      new Transform.w2d(600.0, 50.0, 0.0),
      new Emitter()
        ..genParticles = ((nb) => new Particles(nb, withColors: true, color0: 0xff0000ff, radius0: 4.0, withCollides: true, collide0: 0, intraCollide: true, inertia0: 0.98, isSim0: true))
        ..counter = steady(100)
        ..initializers.add(particlesStartPosition(
          constant(new Vector3.zero())
          , true
        ))
      ..initializers.add(particlesStartPositionPrevious(line(new Vector3.zero(), new Vector3(5.0, 0.0, 0.0), ease.periodicRatio(ease.random, 3000)), true))
      ..initializers.add(addComponents([
        () => new proto.Drawable(proto.particles(1.0, fillStyle : foregroundcolors[0], strokeStyle : foregroundcolors[1])),
        // living for 5s
        () => new Animatable()
          ..add(new Animation()
            ..onTick = ((e, t, t0) => t - t0 < 5000)
            ..onEnd = ((e, t, t0) => e.deleteFromWorld())
          )
          ..add(new Animation()
            ..onTick = (e, t, t0){
              var opacity = ease.onceRatio(ease.linear, 5000)(t - t0, -255.0, 255.0).toInt();

              var ps = e.getComponent(Particles.CT);
              for(int i= 0; i< ps.length; i++) {
                ps.color[i] = (ps.color[i] & 0xffffff00) | opacity;
              };
              return t - t0 < 5001;
            }
          )
      ])),
      new Animatable()
        ..add(new Animation()
          ..onTick = (e, t, t0) {
            var tf = e.getComponent(Transform.CT);
            tf.rotation3d.z = ease.periodicRatio(ease.linear, 3000)(t - t0, math.PI * 2, 0.0);
            //tf.position3d.x = ease.goback(ease.periodicRatio(ease.linear, 3000))(t - t0, 600.0, 0.0);
            return true;
          }
        )
    ]);
    return new Future.value(world);
  },
  'verlet shapes' : (world) {
    var g = 10.0;
    world.getSystem(System_Simulator)
      ..globalAccs.y = g
      ..steps = 3
      ..collSpace = new collisions.Space_XY0(new collisions.Checker_T1(), new collisions.Resolver_Backward())
      ;
    enableQuadtree(world, querySelector('canvas#demo'), true, false);
    var defaultDraw = proto.drawComponentType([
      new proto.DrawComponentType(Particles.CT, proto.particles(5.0, fillStyle : foregroundcolors[0], strokeStyle : foregroundcolors[1])),
      new proto.DrawComponentType(Segments.CT, proto.segments(distanceStyleCollide : "#e20000"))
    ]);

    ParticlesConstructor genP = (nb) => new Particles(nb, withCollides: true, collide0: 1, color0: 0x00A000FF, inertia0: 0.99, withIsSims: true, withAccs: true);
    // entities
    var segment = addNewEntity(world,
      makeLineSegments(
        [
          new Vector3(20.0, 10.0, 0.0),
          new Vector3(40.0, 10.0, 0.0),
          new Vector3(60.0, 10.0, 0.0),
          new Vector3(80.0, 10.0, 0.0),
          new Vector3(100.0,10.0, 0.0)
        ],
        10.0 * g,
        0.0,
        false,
        genP
      ).toList()..add(new proto.Drawable(defaultDraw))
    );
    pinParticle(segment, 0);
    pinParticle(segment, 4);

    var pendule = addNewEntity(world,
      makeLineSegments(
        [
          new Vector3(20.0, 60.0, 0.0),
          new Vector3(100.0,63.0, 0.0)
        ],
        2 * g,
        0.0,
        false,
        genP
      ).toList()..add(new proto.Drawable(defaultDraw))
    );
    pinParticle(pendule, 0);

    var e1 = addNewEntity(world, makeTireXY(new Vector3(200.0, 50.0, 0.0), 50.0, 30, 0.3 * g, 0.9 * g, 0.0, 0.0, genP).toList()..add(new proto.Drawable(defaultDraw)));
    setCollideOfSegment(e1, 1);
    var e2 = addNewEntity(world, makeTireXY(new Vector3(400.0, 50.0, 0.0), 70.0, 7, 0.1 * g, 0.2 *g, 0.0, 0.0, genP).toList()..add(new proto.Drawable(defaultDraw)));
    setCollideOfSegment(e2, 1);
    var e3 = addNewEntity(world, makeTireXY(new Vector3(600.0, 50.0, 0.0), 70.0, 3, 1.0 * g, 1.0 *g, 0.0, 0.0, genP).toList()..add(new proto.Drawable(defaultDraw)));
    setCollideOfSegment(e3, 1);
    var e4 = addNewEntity(world, makeCloth(new Vector3(800.0, 50.0, 0.0), new Vector3(300.0, 0.0, 0.0), new Vector3(0.0, 200.0, 0.0), 15, 14, 10 * g, 0.2, genP).toList()..add(new proto.Drawable(defaultDraw)));

    var e5 = addNewEntity(world, makeTireXY(new Vector3(600.0, 300.0, 0.0), 70.0, 4, 1.0 * g, 1.0 *g, 0.0, 0.0, genP).toList()..add(new proto.Drawable(defaultDraw)));
    setCollideOfSegment(e5, 1);
    var e6 = addNewEntity(world, makeParallelogram(new Vector3(400.0, 300.0, 0.0), new Vector3(70.0, 0.0, 0.0), new Vector3(0.0, 70.0, 0.0), 0.1 * g, 0.0, genP).toList()..add(new proto.Drawable(defaultDraw)));
    setCollideOfSegment(e6, 1);
    var e7 = addNewEntity(world, makeParallelogram(new Vector3(200.0, 300.0, 0.0), new Vector3(70.0, 10.0, 0.0), new Vector3(10.0, 30.0, 0.0), 0.1 * g, 0.0, genP).toList()..add(new proto.Drawable(defaultDraw)));
    setCollideOfSegment(e7, 1);

    var ground = addNewEntity(world, makeParallelogram(new Vector3(10.0, 380.0, 0.0), new Vector3(1100.0, 0.0, 0.0), new Vector3(0.0, 10.0, 0.0), 0.1 * g, 0.0, genP).toList()..add(new proto.Drawable(defaultDraw)));
    pinParticle(ground, 0);
    pinParticle(ground, 1);
    pinParticle(ground, 2);
    pinParticle(ground, 3);
    setCollideOfSegment(ground, 1);

    return new Future.value(world);
  },
  'collisions' : (world) {
    var canvas = querySelector('canvas#demo');
    var w = canvas.width;
    var h = canvas.height;
    var wm = 10;
    var hm = 10;
    world.getSystem(System_Simulator)
    ..globalAccs.y = 0.0
    ..steps = 3
    ..collSpace = new collisions.Space_XY0(new collisions.Checker_T1(), new collisions.Resolver_Noop())
    ;
    enableQuadtree(world, canvas, true, true);
    addNewEntity(world, [
      new Transform.w2d(50.0, 50.0, 0.0),
      new Emitter()
      ..genParticles = ((nb) => new Particles(nb, withRadius : true, radius0 : 3.0, withColors: true, color0: 0xff0000ff, withCollides: true, collide0: 1, intraCollide: true, isSim0: true))
      ..counter = singleWave(500)
      ..initializers.add(particlesStartPosition(
          //constant(new Vector3.zero())
          box(new Vector3(w/2, h/2, 0.0), new Vector3(w/2 - wm, h/2 -hm, 0.0))
        , true
      ))
      ..initializers.add(particlesStartPositionPrevious(box(new Vector3.zero(), new Vector3(3.0, 3.0, 0.0)), false))
      ..initializers.add(addComponents([
        () => new proto.Drawable(proto.particles(1.0, fillStyle : foregroundcolors[0], strokeStyle : foregroundcolors[1])),
        () => new Animatable()
          ..add(new Animation()
            ..onTick = (e, t, t0) {
               var ps = e.getComponent(Particles.CT);
               var cont = true;
               for( var i = ps.position3d.length - 1; i > -1; --i) {
                 cont = true;
                 cont = cont && ps.position3d[i].y > hm;
                 cont = cont && ps.position3d[i].y < (h - hm);
                 cont = cont && ps.position3d[i].x > wm;
                 cont = cont && ps.position3d[i].x < (w - wm);
                 if (!cont) {
                   ps.position3d[i].setFrom(ps.position3dPrevious[i]);
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

enableQuadtree(world, canvas, state, displayDebug) {
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
  if (displayDebug) addNewEntity(world, [new proto.Drawable(collisions.newDrawCanvas_QuadTreeXYAabb(grid, foregroundcolorsM[2], irgba_rgbaString(0x00f000ff)))]);
}