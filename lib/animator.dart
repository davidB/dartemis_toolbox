library animator;

import 'dart:math' as math;
import 'package:dartemis/dartemis.dart';
import 'package:dartemis_addons/utils.dart';

// -- Components ---------------------------------------------------------------

/**
 * Component use to store a bag of [Animation] to play.
 *
 * Because Animation are a bag of "callback" function, it doesn't follow
 * the philosofy of EntitySystem (Component should be only primitive).
 */
class Animatable implements Component {
  final l = new LinkedBag<Animation>();

  Animatable._();
  static _ctor() => new Animatable._();
  factory Animatable() {
    var c = new Component(Animatable, _ctor);
    c.l.clear();
    return c;
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


/**
 * A set of common "easing" function to compute intermediate value of a variable,
 * generally from [baseValue] to [baseValue] + [change],
 * used for transition, interpolation.
 *
 * Every function follow the same signature :
 * [ratio] is the progression (0.0 .. 1.0).
 * [change] is the "amplitute" of the variation for the final variable,
 * or the difference between [baseValue] and the final value.
 * [baseValue] the initiale value of the variable 
 * return the intermediate value.
 *
 * Functions can be used without dartemis or dartemis_addons (there are fully standalone)
 *
 * for graphical representation :
 * * StageXL's [Transition Functions](http://www.stagexl.org/docs/transitions.html)
 * * tween.js '[Graph](http://sole.github.io/tween.js/examples/03_graphs.html)
 */
class Easing {
  /**
   * Performs a linear.
   */
  static num linear(double ratio, num change, num baseValue) {
    return change * ratio + baseValue;
  }

  // QUADRATIC

  /**
   * Performs a quadratic easy-in.
   */
  static num easeInQuad(double ratio, num change, num baseValue) {
    return change * ratio * ratio + baseValue;
  }

  /**
   * Performs a quadratic easy-out.
   */
  static num easeOutQuad(double ratio, num change, num baseValue) {
    return -change * ratio * (ratio - 2) + baseValue;
  }

  /**
   * Performs a quadratic easy-in-out.
   */
  static num easeInOutQuad(double ratio, num change, num baseValue) {
    var time = 2 * ratio;

    if (time < 1)
      return change / 2 * time * time + baseValue;

    time--;

    return -change / 2 * (time * (time - 2) - 1) + baseValue;
  }

  // CUBIC

  /**
   * Performs a cubic easy-in.
   */
  static num easeInCubic(double ratio, num change, num baseValue) {
      return change * ratio * ratio * ratio + baseValue;
  }

  /**
   * Performs a cubic easy-out.
   */
  static num easeOutCubic(double ratio, num change, num baseValue) {
    ratio--;
    return change * (ratio * ratio * ratio + 1) + baseValue;
  }

  /**
   * Performs a cubic easy-in-out.
   */
  static num easeInOutCubic(double ratio, num change, num baseValue) {
    var time = 2 * ratio;

    if (time < 1)
      return change / 2 * time * time * time + baseValue;

    time -= 2;

    return change / 2 * (time * time * time + 2) + baseValue;
  }

  // QUARTIC

  /**
   * Performs a quartic easy-in.
   */
  static num easeInQuartic(double ratio, num change, num baseValue) {
    return change * ratio * ratio * ratio * ratio + baseValue;
  }

  /**
   * Performs a quartic easy-out.
   */
  static num easeOutQuartic(double ratio, num change, num baseValue) {
    ratio--;
    return -change * (ratio * ratio * ratio * ratio - 1) + baseValue;
  }

  /**
   * Performs a quartic easy-in-out.
   */
  static num easeInOutQuartic(double ratio, num change, num baseValue) {
    var time = 2 * ratio;

    if (time < 1)
      return change / 2 * time * time * time * time + baseValue;

    time -= 2;

    return -change / 2 * (time * time * time * time - 2) + baseValue;
  }

  // QUINTIC

  /**
   * Performs a quintic easy-in.
   */
  static num easeInQuintic(double ratio, num change, num baseValue) {
    return change * ratio * ratio * ratio * ratio * ratio + baseValue;
  }

  /**
   * Performs a quintic easy-out.
   */
  static num easeOutQuintic(double ratio, num change, num baseValue) {
    ratio--;
    return change * (ratio * ratio * ratio * ratio * ratio + 1) + baseValue;
  }

  /**
   * Performs a quintic easy-in-out.
   */
  static num easeInOutQuintic(double ratio, num change, num baseValue) {
    var time = 2 * ratio;

    if (time < 1)
      return change / 2 * time * time * time * time * time + baseValue;

    time -= 2;

    return change / 2 * (time * time * time * time * time + 2) + baseValue;
  }

  // SINUSOIDAL

  /**
   * Performs a sine easy-in.
   */
  static num easeInSine(double ratio, num change, num baseValue) {
    return -change * math.cos(ratio * (math.PI / 2)) + change + baseValue;
  }

  /**
   * Performs a sine easy-out.
   */
  static num easeOutSine(double ratio, num change, num baseValue) {
    return change * math.sin(ratio * (math.PI / 2)) + baseValue;
  }

  /**
   * Performs a sine easy-in-out.
   */
  static num easeInOutSine(double ratio, num change, num baseValue) {
    return -change / 2 * (math.cos(ratio * math.PI) - 1) + baseValue;
  }

  // EXPONENTIAL

  /**
   * Performs an exponential easy-in.
   */
  static num easeInExponential(double ratio, num change, num baseValue) {
    return change * math.pow(2, 10 * (ratio - 1)) + baseValue;
  }

  /**
   * Performs an exponential easy-out.
   */
  static num easeOutExponential(double ratio, num change, num baseValue) {
    return change * (-math.pow(2, -10 * ratio) + 1) + baseValue;
  }

  /**
   * Performs an exponential easy-in-out.
   */
  static num easeInOutExponential(double ratio, num change, num baseValue) {
    var time = 2 * ratio;

    if (time < 1)
      return change / 2 * math.pow(2, 10 * (time - 1)) + baseValue;

    time--;

    return change / 2 * (-math.pow(2, -10 * time) + 2) + baseValue;
  }

  // CIRCULAR

  /**
   * Performs a circular easy-in.
   */
  static num easeInCircular(double ratio, num change, num baseValue) {
    return -change * (math.sqrt(1 - ratio * ratio) - 1) + baseValue;
  }

  /**
   * Performs a circular easy-out.
   */
  static num easeOutCircular(double ratio, num change, num baseValue) {
    ratio--;

    return change * math.sqrt(1 - ratio * ratio) + baseValue;
  }

  /**
   * Performs a circular easy-in-out.
   */
  static num easeInOutCircular(double ratio, num change, num baseValue) {
    var time = 2 * ratio;

    if (time < 1)
      return -change / 2 * math.sqrt(1 - time * time) + baseValue;

    time -= 2;

    return change / 2 * (math.sqrt(1 - time * time) + 1) + baseValue;
  }
}

