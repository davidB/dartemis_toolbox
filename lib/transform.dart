library transform;

import 'dart:math' as math;
import 'package:dartemis/dartemis.dart';
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