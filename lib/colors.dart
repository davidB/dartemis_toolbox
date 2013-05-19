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

/// Very primitive colors utilities
///
/// TODO to include more functions (adapted/copied from [TinyColor](http://bgrins.github.io/TinyColor/))
/// TODO more test
/// TODO a demo, a color tool (picker + display other, like [agave color scheme](http://home.gna.org/colorscheme/))
library colors;

import 'dart:math' as math;
import 'package:vector_math/vector_math.dart';

irgba_r255(int v) => ((v & 0xff000000) >> 24);
irgba_r1(int v) => ((v & 0xff000000) >> 24) / 255.0;
irgba_g255(int v) => ((v & 0x00ff0000) >> 16);
irgba_g1(int v) => ((v & 0x00ff0000) >> 16) / 255.0;
irgba_b255(int v) => ((v & 0x0000ff00) >> 8);
irgba_b1(int v) => ((v & 0x0000ff00) >> 8) / 255.0;
irgba_a255(int v) => ((v & 0x000000ff));
irgba_a1(int v) => ((v & 0x000000ff)) / 255.0;

int rgb1_irgba(double r, double g, double b) {
  return 0x000000ff | ((r * 255).toInt() << 24) | ((g * 255).toInt() << 16) | ((b * 255).toInt() << 8);
}


// Converts an rgba (int) color value to [h, s, l] each value in [0.0, 1.0].
List<double> irgb_hsl(int v) {
  var r = irgba_r1(v);
  var g = irgba_g1(v);
  var b = irgba_r1(v);

  var max = math.max(math.max(r, g), b);
  var min = math.min(math.min(r, g), b);
  var h, s, l = (max + min) / 2;

  if (max == min) {
    h = s = 0; // achromatic
  } else {
    var d = max - min;
    s = l > 0.5 ? d / (2 - max - min) : d / (max + min);
    h = (max = r) ?
      (g - b) / d + (g < b ? 6 : 0)
      : (max == g) ?
          (b - r) / d + 2
        : (r - g) / d + 4
      ;
    h /= 6;
  }
  return [h, s, l];
}

int hsl_irgba(List<double> hsl) {
  var r, g, b;

  var h = hsl[0];
  var s = hsl[1];
  var l = hsl[2];

  hue2rgb(p, q, t) {
    if(t < 0) t += 1;
    if(t > 1) t -= 1;
    if(t < 1/6) return p + (q - p) * 6 * t;
    if(t < 1/2) return q;
    if(t < 2/3) return p + (q - p) * (2/3 - t) * 6;
    return p;
  }

  if(s == 0.0) {
    r = g = b = l; // achromatic
  } else {
    var q = l < 0.5 ? l * (1 + s) : l + s - l * s;
    var p = 2 * l - q;
    r = hue2rgb(p, q, h + 1/3);
    g = hue2rgb(p, q, h);
    b = hue2rgb(p, q, h - 1/3);
  }
  return rgb1_irgba(r, g, b);
}

/// Converts an rgba (int) color value to [h, s, v] each value in [0.0, 1.0].
irgba_hsv(int v) {
  var r = irgba_r1(v);
  var g = irgba_g1(v);
  var b = irgba_r1(v);

  var max = math.max(math.max(r, g), b);
  var min = math.min(math.min(r, g), b);
  var h, s, v = max;

  var d = max - min;
  s = (max == 0) ? 0 : d / max;

  if(max == min) {
    h = 0; // achromatic
  } else {
    h = (max == r) ?
      (g - b) / d + (g < b ? 6 : 0)
      : (max == g) ?
        (b - r) / d + 2
        : (r - g) / d + 4
    ;
    h /= 6;
  }
  return [h, s, v];
}

hsv_irga(List<double> hsv) {

  var h = hsv[0] * 6;
  var s = hsv[1];
  var v = hsv[2];

  var i = h.floor(),
      f = h - i,
      p = v * (1 - s),
      q = v * (1 - f * s),
      t = v * (1 - (1 - f) * s),
      mod = i % 6,
      r = [v, q, p, p, t, v][mod],
      g = [t, v, v, q, p, p][mod],
      b = [p, p, t, v, v, q][mod];

  return rgb1_irgba(r, g, b);
}

/// [hsl] is modified and return
/// [amount] is a percent (default 10)
hsl_desaturate(List<double> hsl, [amount = 10]) {
  hsl[1] -= (amount / 100);
  hsl[1] = math.max(0.0, hsl[1]);
  return hsl;
}

/// [hsl] is modified and return
/// [amount] is a percent (default 10)
hsl_saturate(List<double> hsl, [amount = 10]) {
    hsl[1] += (amount / 100);
    hsl[1] = math.min(1.0, hsl[1]);
    return hsl;
}

/// [hsl] is modified and return
hsl_greyscale(List<double> hsl) => hsl_desaturate(hsl, 100);

/// [hsl] is modified and return
/// [amount] is a percent (default 10)
hsl_lighten(List<double> hsl, [amount = 10]) {
  hsl[2] += (amount / 100);
  hsl[2] = math.min(1.0, hsl[2]);
  return hsl;
}

/// [hsl] is modified and return
/// [amount] is a percent (default 10)
hsl_darken(List<double> hsl, [amount = 10]) {
  hsl[2] -= (amount / 100);
  hsl[2] = math.max(0.0, hsl[2]);
  return hsl;
}

/// [hsl] is modified and return
hsl_complement(List<double> hsl) {
    hsl[0] = (hsl[0] + 0.5) % 1.0;
    return hsl;
}

hsl_triad(List<double> hsl) {
  var h = hsl[0];
  return [
    hsl,
    [(h + 0.333) % 1.0, hsl[1], hsl[2]], // h + 120°
    [(h + 0.666) % 1.0, hsl[1], hsl[2]], // h + 240°
  ];
}

hsl_tetrad(List<double> hsl) {
  var h = hsl[0];
  return [
    hsl,
    [(h + 0.25) % 1.0, hsl[1], hsl[2]], // h + 90°
    [(h + 0.50) % 1.0, hsl[1], hsl[2]], // h + 180°
    [(h + 0.75) % 1.0, hsl[1], hsl[2]], // h + 270°
  ];
}

hsl_splitcomplement(List<double> hsl) {
  var h = hsl[0];
  return [
    hsl,
    [(h + 0.20) % 1.0, hsl[1], hsl[2]], // h + 72°
    [(h + 0.60) % 1.0, hsl[1], hsl[2]], // h + 216°
  ];
}

List<List<double>> hsl_analogous(List<double> hsl, [int results = 6, int slices = 30]) {
  var part = 360 / slices;
  var ret = new List<List<double>>(results);
  ret[0] = hsl;
  var h = ((hsl[0] * 360 - (part * results >> 1)) + 720) % 360,
     s = hsl[1],
     l = hsl[2];
  for (var i = 1; i < results; ++i) {
    h = (h + part) % 360;
    ret[i] = [h / 360, s, l];
  }
  return ret;
}

List<List<double>> hsv_monochromatic(List<double> hsv, [int results = 6]) {
  var h = hsv[0], s = hsv[1], v = hsv[2];
  var ret = new List<List<double>>(results);
  var modification = 1.0 / results;
  ret[0] = hsv;

  for (var i = 1; i < results; ++i) {
    v = (v + modification) % 1.0;
    ret[i] = [h, s, v];
  }
  return ret;
}

///    test('irgba_rgbString',(){
///      expect(irgba_rgbString(0xff000000), 'rgb(255, 0, 0)');
///      expect(irgba_rgbString(0x00ff0000), 'rgb(0, 255, 0)');
///      expect(irgba_rgbString(0x0000ff00), 'rgb(0, 0, 255)');
///      expect(irgba_rgbString(0xffffffff), 'rgb(255, 255, 255)');
///      expect(irgba_rgbString(0x00000000), 'rgb(0, 0, 0)');
///      expect(irgba_rgbString(0x000000ff), 'rgb(0, 0, 0)');
///    });
irgba_rgbString(int v) {
  var r = irgba_r255(v);
  var g = irgba_g255(v);
  var b = irgba_b255(v);
  return 'rgb(${r}, ${g}, ${b})';
}

///    test('irgba_rgbaString',(){
///      expect(irgba_rgbaString(0xff000000), 'rgba(255, 0, 0, 0.0)');
///      expect(irgba_rgbaString(0x00ff0000), 'rgba(0, 255, 0, 0.0)');
///      expect(irgba_rgbaString(0x0000ff00), 'rgba(0, 0, 255, 0.0)');
///      expect(irgba_rgbaString(0xffffffff), 'rgba(255, 255, 255, 1.0)');
///      expect(irgba_rgbaString(0x00000000), 'rgba(0, 0, 0, 0.0)');
///      expect(irgba_rgbaString(0x000000ff), 'rgba(0, 0, 0, 1.0)');
///    });
irgba_rgbaString(int v) {
  var r = irgba_r255(v);
  var g = irgba_g255(v);
  var b = irgba_b255(v);
  var a = irgba_a1(v);
  return 'rgba(${r}, ${g}, ${b}, ${a})';
}

/// Converts an RGB color to hex
/// Returns a 6 character hex (no prefix)
///
///    test('irgba_hexString',(){
///      expect(irgba_hexString(0xff000000), 'ff0000');
///      expect(irgba_hexString(0x00ff0000), '00ff00');
///      expect(irgba_hexString(0x0000ff00), '0000ff');
///      expect(irgba_hexString(0xffffff00), 'ffffff');
///      expect(irgba_hexString(0x00000000), '000000');
///      expect(irgba_hexString(0x000000ff), '000000');
///    });
irgba_hexString(int v) {
  var x = (v >> 8) | 0x1000000; // start with 1 for padding with 0
  return x.toRadixString(16).substring(1);
}

// [Big List of Colors](http://www.w3.org/TR/css3-color/#svg-color)
const aliceblue = 0xf0f8ffff;
const antiquewhite = 0xfaebd7ff;
const aqua = 0x0ffff;
const aquamarine = 0x7fffd4ff;
const azure = 0xf0ffffff;
const beige = 0xf5f5dcff;
const bisque = 0xffe4c4ff;
const black = 0x000ff;
const blanchedalmond = 0xffebcdff;
const blue = 0x00fff;
const blueviolet = 0x8a2be2ff;
const brown = 0xa52a2aff;
const burlywood = 0xdeb887ff;
const burntsienna = 0xea7e5dff;
const cadetblue = 0x5f9ea0ff;
const chartreuse = 0x7fff00ff;
const chocolate = 0xd2691eff;
const coral = 0xff7f50ff;
const cornflowerblue = 0x6495edff;
const cornsilk = 0xfff8dcff;
const crimson = 0xdc143cff;
const cyan = 0x0ffff;
const darkblue = 0x00008bff;
const darkcyan = 0x008b8bff;
const darkgoldenrod = 0xb8860bff;
const darkgray = 0xa9a9a9ff;
const darkgreen = 0x006400ff;
const darkgrey = 0xa9a9a9ff;
const darkkhaki = 0xbdb76bff;
const darkmagenta = 0x8b008bff;
const darkolivegreen = 0x556b2fff;
const darkorange = 0xff8c00ff;
const darkorchid = 0x9932ccff;
const darkred = 0x8b0000ff;
const darksalmon = 0xe9967aff;
const darkseagreen = 0x8fbc8fff;
const darkslateblue = 0x483d8bff;
const darkslategray = 0x2f4f4fff;
const darkslategrey = 0x2f4f4fff;
const darkturquoise = 0x00ced1ff;
const darkviolet = 0x9400d3ff;
const deeppink = 0xff1493ff;
const deepskyblue = 0x00bfffff;
const dimgray = 0x696969ff;
const dimgrey = 0x696969ff;
const dodgerblue = 0x1e90ffff;
const firebrick = 0xb22222ff;
const floralwhite = 0xfffaf0ff;
const forestgreen = 0x228b22ff;
const fuchsia = 0xf0fff;
const gainsboro = 0xdcdcdcff;
const ghostwhite = 0xf8f8ffff;
const gold = 0xffd700ff;
const goldenrod = 0xdaa520ff;
const gray = 0x808080ff;
const green = 0x008000ff;
const greenyellow = 0xadff2fff;
const grey = 0x808080ff;
const honeydew = 0xf0fff0ff;
const hotpink = 0xff69b4ff;
const indianred = 0xcd5c5cff;
const indigo = 0x4b0082ff;
const ivory = 0xfffff0ff;
const khaki = 0xf0e68cff;
const lavender = 0xe6e6faff;
const lavenderblush = 0xfff0f5ff;
const lawngreen = 0x7cfc00ff;
const lemonchiffon = 0xfffacdff;
const lightblue = 0xadd8e6ff;
const lightcoral = 0xf08080ff;
const lightcyan = 0xe0ffffff;
const lightgoldenrodyellow = 0xfafad2ff;
const lightgray = 0xd3d3d3ff;
const lightgreen = 0x90ee90ff;
const lightgrey = 0xd3d3d3ff;
const lightpink = 0xffb6c1ff;
const lightsalmon = 0xffa07aff;
const lightseagreen = 0x20b2aaff;
const lightskyblue = 0x87cefaff;
const lightslategray = 0x789ff;
const lightslategrey = 0x789ff;
const lightsteelblue = 0xb0c4deff;
const lightyellow = 0xffffe0ff;
const lime = 0x0f0ff;
const limegreen = 0x32cd32ff;
const linen = 0xfaf0e6ff;
const magenta = 0xf0fff;
const maroon = 0x800000ff;
const mediumaquamarine = 0x66cdaaff;
const mediumblue = 0x0000cdff;
const mediumorchid = 0xba55d3ff;
const mediumpurple = 0x9370dbff;
const mediumseagreen = 0x3cb371ff;
const mediumslateblue = 0x7b68eeff;
const mediumspringgreen = 0x00fa9aff;
const mediumturquoise = 0x48d1ccff;
const mediumvioletred = 0xc71585ff;
const midnightblue = 0x191970ff;
const mintcream = 0xf5fffaff;
const mistyrose = 0xffe4e1ff;
const moccasin = 0xffe4b5ff;
const navajowhite = 0xffdeadff;
const navy = 0x000080ff;
const oldlace = 0xfdf5e6ff;
const olive = 0x808000ff;
const olivedrab = 0x6b8e23ff;
const orange = 0xffa500ff;
const orangered = 0xff4500ff;
const orchid = 0xda70d6ff;
const palegoldenrod = 0xeee8aaff;
const palegreen = 0x98fb98ff;
const paleturquoise = 0xafeeeeff;
const palevioletred = 0xdb7093ff;
const papayawhip = 0xffefd5ff;
const peachpuff = 0xffdab9ff;
const peru = 0xcd853fff;
const pink = 0xffc0cbff;
const plum = 0xdda0ddff;
const powderblue = 0xb0e0e6ff;
const purple = 0x800080ff;
const red = 0xf00ff;
const rosybrown = 0xbc8f8fff;
const royalblue = 0x4169e1ff;
const saddlebrown = 0x8b4513ff;
const salmon = 0xfa8072ff;
const sandybrown = 0xf4a460ff;
const seagreen = 0x2e8b57ff;
const seashell = 0xfff5eeff;
const sienna = 0xa0522dff;
const silver = 0xc0c0c0ff;
const skyblue = 0x87ceebff;
const slateblue = 0x6a5acdff;
const slategray = 0x708090ff;
const slategrey = 0x708090ff;
const snow = 0xfffafaff;
const springgreen = 0x00ff7fff;
const steelblue = 0x4682b4ff;
const tan = 0xd2b48cff;
const teal = 0x008080ff;
const thistle = 0xd8bfd8ff;
const tomato = 0xff6347ff;
const turquoise = 0x40e0d0ff;
const violet = 0xee82eeff;
const wheat = 0xf5deb3ff;
const white = 0xfffff;
const whitesmoke = 0xf5f5f5ff;
const yellow = 0xff0ff;
const yellowgreen = 0x9acd32ff;
