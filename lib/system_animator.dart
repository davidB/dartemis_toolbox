// License [CC0](http://creativecommons.org/publicdomain/zero/1.0/)

library system_animator;

import 'dart:math' as math;
import 'package:dartemis/dartemis.dart';
import 'utils.dart';

// -- Components ---------------------------------------------------------------

/**
 * Component use to store a bag of [Animation] to play.
 *
 * Because Animation are a bag of "callback" function, it doesn't follow
 * the philosofy of EntitySystem (Component should be only primitive).
 */
class Animatable extends ComponentPoolable {
  final l = new LinkedBag<Animation>();

  Animatable._();
  static _ctor() => new Animatable._();
  factory Animatable() {
    var c = new Poolable.of(Animatable, _ctor);
    c.cleanUp();
    return c;
  }

  void cleanUp() {
    l.clear();
  }

  /// this is a sugar method for [l].add([a])
  /// sugar because you can write
  ///
  ///    new Animatable()
  ///      ..add(new Animation())
  ///      ..add(new Animation())
  ///
  Animatable add(Animation a) {
    l.add(a);
    return this;
  }
}

typedef bool OnStart(Entity e, double t, double t0);
typedef bool OnUpdate(Entity e, double t, double t0);
typedef bool OnComplete(Entity e, double t, double t0);

bool onNoop(Entity e, num t, num t0){ return false;}
/**
 * [Animation] is a set of action to execute [onBegin], [onTick], [onEnd].
 *
 * It can be used to playe some action based on time :
 *
 * * animate visual Entity (eg: onTick rotate an 3D object)
 * * countdown to trigger some action [onEnd], or update value [onTick]
 * * run periodic action on the idem (without using a dedicated [EntitySystem])
 */
//INSPI may be replace by Iteratee or Stream later in future
class Animation {
  /// set by System_Animator when it start playing
  double _t0 = -1.0;

  /// Callback before first call of [onTick] (same tick)
  OnStart onBegin = onNoop;

  /// Callback each tick of the [System_Animator],
  /// the animation is ended when onUpdate return false
  OnUpdate onTick = onNoop;

  /// Callback when animation is ended (after last [onTick], same tick)
  OnComplete onEnd = onNoop;

  /// [Animation] to chain (to animate when this is completed)
  Animation next = null;
}


// -- System -------------------------------------------------------------------
class System_Animator extends EntityProcessingSystem {
  ComponentMapper<Animatable> _animatableMapper;
  double _tickTime = 0.0;

  System_Animator() : super(Aspect.getAspectForAllOf([Animatable]));

  void initialize(){
    _animatableMapper = new ComponentMapper<Animatable>(Animatable, world);
  }

  void begin() {
    _tickTime += world.delta;
    //if (_tickTime < 10000) print("_tickTime ${_tickTime}");
  }

  void processEntity(Entity entity) {
    var animatable = _animatableMapper.get(entity);
    animatable.l.iterateAndUpdate((anim) {
      if (anim._t0 < 0) {
        anim._t0 = _tickTime;
        anim.onBegin(entity, _tickTime, anim._t0);
      }
      var cont = (anim._t0 <= _tickTime)? anim.onTick(entity, _tickTime, anim._t0) : true;
      if (!cont) {
        anim.onEnd(entity, _tickTime, anim._t0);
      }
      return cont ? anim : anim.next;
    });
  }
}


