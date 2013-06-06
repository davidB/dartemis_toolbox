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
library utils_math;

import 'dart:math' as math;
import 'package:vector_math/vector_math.dart';

double clamp(double v, double max, double min) => math.min(math.max(v, min), max );


final VZERO = new Vector3.zero();
final VX_AXIS = new Vector3(1.0, 0.0, 0.0);
final VY_AXIS = new Vector3(0.0, 1.0, 0.0);
final VZ_AXIS = new Vector3(0.0, 0.0, 1.0);

/// return [out]
Vector3 lookAt(Vector3 target, Vector3 position3d, Vector3 out, [Vector3 up]) {
  up = (up == null) ? VY_AXIS : up;
  var m = makeViewMatrix(position3d, target, up).getRotation();
  // code from (euler order XYZ)
  // https://github.com/mrdoob/three.js/blob/master/src/math/Vector3.js
  out.y = math.asin( clamp(m.row2.x, -1.0 ,1.0 ) );
  if ( m.row2.x.abs() < 0.99999 ) {
    out.x = math.atan2( - m.row2.y, m.row2.z );
    out.z = math.atan2( - m.row1.x, m.row0.x );
  } else {
    out.x = math.atan2( m.row1.z, m.row1.y );
    out.z = 0.0;
  }
  return out;
}