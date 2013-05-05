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
 * for graphical representation :
 * * StageXL's [Transition Functions](http://www.stagexl.org/docs/transitions.html)
 * * tween.js '[Graph](http://sole.github.io/tween.js/examples/03_graphs.html)
 */
library ease;

import 'dart:math';
import 'dart:collection';

/// a list/map of all functions, use for test, demo, editor
final all = new LinkedHashMap<String, Function>()
  ..['linear'] = linear
  ..['inQuad'] = inQuad
  ..['outQuad'] = outQuad
  ..['inOutQuad'] = inOutQuad
  ..['inCubic'] = inCubic
  ..['outCubic'] = outCubic
  ..['inOutCubic'] = inOutCubic
  ..['inQuartic'] = inQuartic
  ..['outQuartic'] = outQuartic
  ..['inOutQuartic'] = inOutQuartic
  ..['inQuintic'] = inQuintic
  ..['outQuintic'] = outQuintic
  ..['inOutQuintic'] = inOutQuintic
  ..['inSine'] = inSine
  ..['outSine'] = outSine
  ..['inExponential'] = inExponential
  ..['outExponential'] = outExponential
  ..['inOutExponential'] = inOutExponential
  ..['inCircular'] = inCircular
  ..['outCircular'] = outCircular
  ..['inOutCircular'] = inOutCircular
  ;

/**
 * Performs a linear.
 */
num linear(double ratio, num change, num baseValue) {
  return change * ratio + baseValue;
}

// QUADRATIC

/**
 * Performs a quadratic easy-in.
 */
num inQuad(double ratio, num change, num baseValue) {
  return change * ratio * ratio + baseValue;
}

/**
 * Performs a quadratic easy-out.
 */
num outQuad(double ratio, num change, num baseValue) {
  return -change * ratio * (ratio - 2) + baseValue;
}

/**
 * Performs a quadratic easy-in-out.
 */
num inOutQuad(double ratio, num change, num baseValue) {
  var r = 2 * ratio;

  if (r < 1)
    return change / 2 * r * r + baseValue;

  r--;

  return -change / 2 * (r * (r - 2) - 1) + baseValue;
}

// CUBIC

/**
 * Performs a cubic easy-in.
 */
num inCubic(double ratio, num change, num baseValue) {
  return change * ratio * ratio * ratio + baseValue;
}

/**
 * Performs a cubic easy-out.
 */
num outCubic(double ratio, num change, num baseValue) {
  ratio--;
  return change * (ratio * ratio * ratio + 1) + baseValue;
}

/**
 * Performs a cubic easy-in-out.
 */
num inOutCubic(double ratio, num change, num baseValue) {
  var r = 2 * ratio;

  if (r < 1)
    return change / 2 * r * r * r + baseValue;

  r -= 2;

  return change / 2 * (r * r * r + 2) + baseValue;
}

// QUARTIC

/**
 * Performs a quartic easy-in.
 */
num inQuartic(double ratio, num change, num baseValue) {
  return change * ratio * ratio * ratio * ratio + baseValue;
}

/**
 * Performs a quartic easy-out.
 */
num outQuartic(double ratio, num change, num baseValue) {
  ratio--;
  return -change * (ratio * ratio * ratio * ratio - 1) + baseValue;
}

/**
 * Performs a quartic easy-in-out.
 */
num inOutQuartic(double ratio, num change, num baseValue) {
  var r = 2 * ratio;

  if (r < 1)
    return change / 2 * r * r * r * r + baseValue;

  r -= 2;

  return -change / 2 * (r * r * r * r - 2) + baseValue;
}

// QUINTIC

/**
 * Performs a quintic easy-in.
 */
num inQuintic(double ratio, num change, num baseValue) {
  return change * ratio * ratio * ratio * ratio * ratio + baseValue;
}

/**
 * Performs a quintic easy-out.
 */
num outQuintic(double ratio, num change, num baseValue) {
  ratio--;
  return change * (ratio * ratio * ratio * ratio * ratio + 1) + baseValue;
}

/**
 * Performs a quintic easy-in-out.
 */
num inOutQuintic(double ratio, num change, num baseValue) {
  var r = 2 * ratio;

  if (r < 1)
    return change / 2 * r * r * r * r * r + baseValue;

  r -= 2;

  return change / 2 * (r * r * r * r * r + 2) + baseValue;
}

// SINUSOIDAL

/**
 * Performs a sine easy-in.
 */
num inSine(double ratio, num change, num baseValue) {
  return -change * cos(ratio * (PI / 2)) + change + baseValue;
}

/**
 * Performs a sine easy-out.
 */
num outSine(double ratio, num change, num baseValue) {
  return change * sin(ratio * (PI / 2)) + baseValue;
}

/**
 * Performs a sine easy-in-out.
 */
num inOutSine(double ratio, num change, num baseValue) {
  return -change / 2 * (cos(ratio * PI) - 1) + baseValue;
}

// EXPONENTIAL

/**
 * Performs an exponential easy-in.
 */
num inExponential(double ratio, num change, num baseValue) {
  return change * pow(2, 10 * (ratio - 1)) + baseValue;
}

/**
 * Performs an exponential easy-out.
 */
num outExponential(double ratio, num change, num baseValue) {
  return change * (-pow(2, -10 * ratio) + 1) + baseValue;
}

/**
 * Performs an exponential easy-in-out.
 */
num inOutExponential(double ratio, num change, num baseValue) {
  var r = 2 * ratio;

  if (r < 1)
    return change / 2 * pow(2, 10 * (r - 1)) + baseValue;

  r--;

  return change / 2 * (-pow(2, -10 * r) + 2) + baseValue;
}

// CIRCULAR

/**
 * Performs a circular easy-in.
 */
num inCircular(double ratio, num change, num baseValue) {
  return -change * (sqrt(1 - ratio * ratio) - 1) + baseValue;
}

/**
 * Performs a circular easy-out.
 */
num outCircular(double ratio, num change, num baseValue) {
  ratio--;

  return change * sqrt(1 - ratio * ratio) + baseValue;
}

/**
 * Performs a circular easy-in-out.
 */
num inOutCircular(double ratio, num change, num baseValue) {
  var r = 2 * ratio;

  if (r < 1)
    return -change / 2 * (sqrt(1 - r * r) - 1) + baseValue;

  r -= 2;
  return change / 2 * (sqrt(1 - r * r) + 1) + baseValue;
}

