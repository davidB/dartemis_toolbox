library transform;

import 'dart:math' as math;
import 'package:dartemis/dartemis.dart';
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
import 'package:vector_math/vector_math.dart';

class Transform extends ComponentPoolable {
  vec3 position3d;
  vec3 rotation3d;
  vec3 scale3d;

  // 2d view
  vec2 _position2d = new vec2.zero();
  double get angle => rotation3d.z;
  set angle(double v) => rotation3d.z = v;
  vec2 get position {
    _position2d.x = position3d.x;
    _position2d.y = position3d.y;
    return _position2d;
  }
  set position(vec2 v) {
    position3d.x = v.x;
    position3d.y = v.y;
  }

  Transform._();
  static _ctor() => new Transform._();
  factory Transform.w2d(double x, double y, double a) {
    return new Transform.w3d(new vec3(x, y, 0.0), new vec3(0.0, 0.0, a));
  }
  factory Transform.w3d(vec3 position, [vec3 rotation, vec3 scale]) {
    var c = new Poolable.of(Transform, _ctor) as Transform;
    c.position3d = position;
    c.rotation3d = (rotation == null) ? new vec3(0.0, 0.0, 0.0) : rotation;
    c.scale3d = (scale == null) ? new vec3(1.0, 1.0, 1.0) : scale;
    return c;
  }
  /// this method mofidy the Transform (usefull for creation)
  /// return this
  Transform lookAt(vec3 target, [vec3 up]) {
    up = (up == null) ? new vec3(0.0, 1.0, 0.0) : up;
    var m = makeViewMatrix(position3d, target, up).getRotation();
    // code from (euler order XYZ)
    // https://github.com/mrdoob/three.js/blob/master/src/math/Vector3.js
    rotation3d.y = math.asin( clamp( m.row2.x, -1.0 ,1.0 ) );
    if ( m.row2.x.abs() < 0.99999 ) {
      rotation3d.x = math.atan2( - m.row2.y, m.row2.z );
      rotation3d.z = math.atan2( - m.row1.x, m.row0.x );
    } else {
      rotation3d.x = math.atan2( m.row1.z, m.row1.y );
      rotation3d.z = 0.0;
    }
    return this;
  }
}