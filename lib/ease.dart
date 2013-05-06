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

/**
 * A set of common "easing" function to compute intermediate value of a variable,
 * generally from [baseValue] to [baseValue] + [change],
 * used for transition, interpolation.
 *
 * Every function follow the same signature :
 * * [ratio] is the progression (0.0 .. 1.0).
 * * [change] is the "amplitute" of the variation for the final variable,
 * or the difference between [baseValue] and the final value.
 * * [baseValue] the initiale value of the variable
 * * return the intermediate value.
 *
 * Functions can be used without dartemis or dartemis_addons (there are fully standalone)
 *
 * [graphical representation](http://davidb.github.io/dartemis_addons/ease_graphics.html)
 */
library ease;

import 'dart:math';
import 'dart:collection';

/// a list/map of all functions, use for test, demo, editor
final all = new LinkedHashMap<String, Function>()
  ..['linear'] = linear
  ..['random'] = random
  ..['inQuad'] = inQuad
  ..['outQuad'] = outQuad
  ..['inOutQuad'] = inOutQuad
  ..['outInQuad'] = outInQuad
  ..['inCubic'] = inCubic
  ..['outCubic'] = outCubic
  ..['inOutCubic'] = inOutCubic
  ..['outInCubic'] = outInCubic
  ..['inQuartic'] = inQuartic
  ..['outQuartic'] = outQuartic
  ..['inOutQuartic'] = inOutQuartic
  ..['outInQuartic'] = outInQuartic
  ..['inQuintic'] = inQuintic
  ..['outQuintic'] = outQuintic
  ..['inOutQuintic'] = inOutQuintic
  ..['outInQuintic'] = outInQuintic
  ..['inSine'] = inSine
  ..['outSine'] = outSine
  ..['inOutSine'] = inOutSine
  ..['outInSine'] = outInSine
  ..['inExponential'] = inExponential
  ..['outExponential'] = outExponential
  ..['inOutExponential'] = inOutExponential
  ..['outInExponential'] = outInExponential
  ..['inCircular'] = inCircular
  ..['outCircular'] = outCircular
  ..['inOutCircular'] = inOutCircular
  ..['outInCircular'] = outInCircular
  ..['inBack'] = inBack
  ..['outBack'] = outBack
  ..['inOutBack'] = inOutBack
  ..['outInBack'] = outInBack
  ..['inElastic'] = inElastic
  ..['outElastic'] = outElastic
  ..['inOutElastic'] = inOutElastic
  ..['outInElastic'] = outInElastic
  ..['inBounce'] = inBounce
  ..['outBounce'] = outBounce
  ..['inOutBounce'] = inOutBounce
  ..['outInBounce'] = outInBounce
  ;

/// create a new ease function by chaining 2 ease function
chain(f0, f1) => (double ratio, num change, num baseValue) {
  ratio = ratio * 2.0;
  var c = change / 2;
  return (ratio < 1.0) ? f0(ratio, c, baseValue) : f1(ratio - 1.0, c, baseValue) + c;
};

reverse(f0) => (double ratio, num change, num baseValue) {
  return f0(ratio, -change, baseValue + change);
};

/// create a new ease function by chaining 2 ease function
goback(f0) => (double ratio, num change, num baseValue) {
  ratio = ratio * 2.0;
  var c = change;
  return (ratio < 1.0) ? f0(ratio, c, baseValue) : reverse(f0)(ratio - 1.0, c, baseValue);
};

easeRatio(f0, ease4ratio) => (double ratio, num change, num baseValue) {
  ratio = ease4ratio(ratio, 1.0, 0.0);
  return f0(ratio, change, baseValue);
};

periodicRatio(f0, period) => (double ratio, num change, num baseValue) {
  ratio = (ratio / period);
  ratio = ratio - ratio.toInt();
  return f0(ratio, change, baseValue);
};

/**
 * Performs a linear.
 */
num linear(double ratio, num change, num baseValue) {
  return change * ratio + baseValue;
}

/**
 * Performs a random value (except for ratio == 0 or ratio == 1).
 */
num random(double ratio, num change, num baseValue) {
  var r = (ratio > 0.0 && ratio < 1.0) ? _randomRatio.nextDouble() : ratio;
  return change * r + baseValue;
}
final _randomRatio = new Random();

// QUADRATIC

num inQuad(double ratio, num change, num baseValue) {
  return change * ratio * ratio + baseValue;
}

num outQuad(double ratio, num change, num baseValue) {
  return -change * ratio * (ratio - 2) + baseValue;
}

///num f(double ratio, num change, num baseValue)
final inOutQuad = chain(inQuad, outQuad);

///num f(double ratio, num change, num baseValue)
final outInQuad = chain(outQuad, inQuad);

// CUBIC

num inCubic(double ratio, num change, num baseValue) {
  return change * ratio * ratio * ratio + baseValue;
}

num outCubic(double ratio, num change, num baseValue) {
  ratio--;
  return change * (ratio * ratio * ratio + 1) + baseValue;
}

final inOutCubic = chain(inCubic, outCubic);

final outInCubic = chain(outCubic, inCubic);

// QUARTIC

num inQuartic(double ratio, num change, num baseValue) {
  return change * ratio * ratio * ratio * ratio + baseValue;
}

num outQuartic(double ratio, num change, num baseValue) {
  ratio--;
  return -change * (ratio * ratio * ratio * ratio - 1) + baseValue;
}

///num f(double ratio, num change, num baseValue)
final inOutQuartic = chain(inQuartic, outQuartic);

///num f(double ratio, num change, num baseValue)
final outInQuartic = chain(outQuartic, inQuartic);

// QUINTIC

/**
 * Performs a quintic easy-in.
 */
num inQuintic(double ratio, num change, num baseValue) {
  return change * ratio * ratio * ratio * ratio * ratio + baseValue;
}

num outQuintic(double ratio, num change, num baseValue) {
  ratio--;
  return change * (ratio * ratio * ratio * ratio * ratio + 1) + baseValue;
}

///num f(double ratio, num change, num baseValue)
final inOutQuintic = chain(inQuintic, outQuintic);

///num f(double ratio, num change, num baseValue)
final outInQuintic = chain(outQuintic, inQuintic);

// SINUSOIDAL

num inSine(double ratio, num change, num baseValue) {
  return -change * cos(ratio * (PI / 2)) + change + baseValue;
}

num outSine(double ratio, num change, num baseValue) {
  return change * sin(ratio * (PI / 2)) + baseValue;
}

//num inOutSine(double ratio, num change, num baseValue) {
//  return -change / 2 * (cos(ratio * PI) - 1) + baseValue;
//}

///num f(double ratio, num change, num baseValue)
final inOutSine = chain(inSine, outSine);

///num f(double ratio, num change, num baseValue)
final outInSine = chain(outSine, inSine);

// EXPONENTIAL

num inExponential(double ratio, num change, num baseValue) {
  return change * pow(2, 10 * (ratio - 1)) + baseValue;
}

num outExponential(double ratio, num change, num baseValue) {
  return change * (-pow(2, -10 * ratio) + 1) + baseValue;
}


///num f(double ratio, num change, num baseValue)
final inOutExponential = chain(inExponential, outExponential);

///num f(double ratio, num change, num baseValue)
final outInExponential = chain(outExponential, inExponential);

// CIRCULAR

num inCircular(double ratio, num change, num baseValue) {
  return -change * (sqrt(1 - ratio * ratio) - 1) + baseValue;
}

num outCircular(double ratio, num change, num baseValue) {
  ratio--;

  return change * sqrt(1 - ratio * ratio) + baseValue;
}

///num f(double ratio, num change, num baseValue)
final inOutCircular = chain(inCircular, outCircular);

///num f(double ratio, num change, num baseValue)
final outInCircular = chain(outCircular, inCircular);

// Back

num inBack(double ratio, num change, num baseValue) {
  num s = 1.70158;
  return ratio * ratio * ((s + change) * ratio - s) + baseValue;
}

num outBack(double ratio, num change, num baseValue) {
  num s = 1.70158;
  ratio = ratio - 1.0;
  return ratio * ratio * ((s + change) * ratio + s) + change  + baseValue;
}

///num f(double ratio, num change, num baseValue)
final inOutBack = chain(inBack, outBack);

///num f(double ratio, num change, num baseValue)
final outInBack = chain(outBack, inBack);

// Elastic

num inElastic(double ratio, num change, num baseValue) {
  var r = ratio;
  if (!(ratio == 0.0 || ratio == 1.0)) {
    ratio = ratio - 1.0;
    r = - pow(2.0, 10.0 * ratio) * sin((ratio - 0.3 / 4.0) * (2.0 * PI) / 0.3);
  }
  return r * change + baseValue;
}

num outElastic(double ratio, num change, num baseValue) {
  var r =  (ratio == 0.0 || ratio == 1.0) ? ratio
    : pow(2.0, - 10.0 * ratio) * sin((ratio - 0.3 / 4.0) * (2.0 * PI) / 0.3) + 1;
  return r * change + baseValue;
}

///num f(double ratio, num change, num baseValue)
final inOutElastic = chain(inElastic, outElastic);

///num f(double ratio, num change, num baseValue)
final outInElastic = chain(outElastic, inElastic);

// Bounce

num inBounce(double ratio, num change, num baseValue) {
  var r = 1.0 - outBounce(1.0 - ratio, 1.0, 0.0);
  return r * change + baseValue;
}

num outBounce(double ratio, num change, num baseValue) {
  if (ratio < 1 / 2.75) {
    ratio =  7.5625 * ratio * ratio;
  } else if (ratio < 2 / 2.75) {
    ratio = ratio - 1.5 / 2.75;
    ratio = 7.5625 * ratio * ratio + 0.75;
  } else if (ratio < 2.5 / 2.75) {
    ratio = ratio - 2.25 / 2.75;
    ratio = 7.5625 * ratio * ratio + 0.9375;
  } else {
    ratio = ratio - 2.625 / 2.75;
    ratio = 7.5625 * ratio * ratio + 0.984375;
  }
  return ratio * change + baseValue;
}

///num f(double ratio, num change, num baseValue)
final inOutBounce = chain(inBounce, outBounce);

///num f(double ratio, num change, num baseValue)
final outInBounce = chain(outBounce, inBounce);

