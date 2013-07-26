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

//-- double --------------------------------------------------------------------

double clamp(double v, double max, double min) => math.min(math.max(v, min), max );

class MinMax {
  double min;
  double max;
}

/// Calculate the distance between the two intervals
double intervalDistance( double minA, double maxA, double minB, double maxB ) {
  return ( minA < minB ) ? minB - maxA : minA - maxB;
}

bool isSeparated( double minA, double maxA, double minB, double maxB ) {
  return (maxA < minB) || (maxB < minA);
}

//-- Vector3 -------------------------------------------------------------------

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
  out.y = math.asin( clamp(m.row2.x, 1.0, -1.0 ) );
  if ( m.row2.x.abs() < 0.99999 ) {
    out.x = math.atan2( - m.row2.y, m.row2.z );
    out.z = math.atan2( - m.row1.x, m.row0.x );
  } else {
    out.x = math.atan2( m.row1.z, m.row1.y );
    out.z = 0.0;
  }
  return out;
}

Vector3 extractCenter(List<Vector3> shape, Vector3 out) {
  out.x = 0.0;
  out.y = 0.0;

  for (int i = 0; i < shape.length; i++) {
    var v = shape[i];
    out.x += v.x;
    out.y += v.y;
  }

  out.x /= shape.length;
  out.y /= shape.length;
  return out;
}

Aabb3 extractAabbDisc(Vector3 v, double radius, Aabb3 out){
  out.min.setValues(v.x - radius, v.y - radius, v.z - radius);
  out.max.setValues(v.x + radius, v.y + radius, v.z + radius);
}

Aabb3 extractAabbDisc2(Vector3 v0, Vector3 v1, double radius, Aabb3 out){
  var min = out.min;
  var max = out.max;
  if (v0.x < v1.x) {
    min.x = v0.x - radius;
    max.x = v1.x + radius;
  } else {
    min.x = v1.x - radius;
    max.x = v0.x + radius;
  }
  if (v0.y < v1.y) {
    min.y = v0.y - radius;
    max.y = v1.y + radius;
  } else {
    min.y = v1.y - radius;
    max.y = v0.y + radius;
  }
  if (v0.z < v1.z) {
    min.z = v0.z - radius;
    max.z = v1.z + radius;
  } else {
    min.z = v1.z - radius;
    max.z = v0.z + radius;
  }
  //out.min.setValues(math.min(v0.x, v1.x) - radius, math.min(v0.y, v1.y) - radius, math.min(v0.z, v1.z) - radius);
  //out.max.setValues(math.max(v0.x, v1.x) + radius, math.max(v0.y, v1.y) + radius, math.max(v0.z, v1.z) + radius);
}

Aabb3 extractAabbPoly(List<Vector3> vs, Aabb3 out){
  var min = out.min;
  var max = out.max;

  min.setFrom(vs[0]);
  max.setFrom(vs[0]);
  for (int i = vs.length - 1; i > 0 ; --i) {
    var v = vs[i];
    if (min.x > v.x) min.x = v.x;
    if (min.y > v.y) min.y = v.y;
    if (min.z > v.z) min.z = v.z;
    if (max.x < v.x) max.x = v.x;
    if (max.y < v.y) max.y = v.y;
    if (max.z < v.z) max.z = v.z;
  }

  return out;
}

Aabb3 extractAabbPoly2(List<Vector3> vs0, List<Vector3> vs1, Aabb3 out){
  var min = out.min;
  var max = out.max;

  min.setFrom(vs0[0]);
  max.setFrom(vs0[0]);
  var vs = vs0;
  for (int i = vs.length - 1; i > 0 ; --i) {
    var v = vs[i];
    if (min.x > v.x) min.x = v.x;
    if (min.y > v.y) min.y = v.y;
    if (min.z > v.z) min.z = v.z;
    if (max.x < v.x) max.x = v.x;
    if (max.y < v.y) max.y = v.y;
    if (max.z < v.z) max.z = v.z;
  }
  vs = vs1;
  for (int i = vs.length - 1; i >= 0; --i) {
    var v = vs[i];
    if (min.x > v.x) min.x = v.x;
    if (min.y > v.y) min.y = v.y;
    if (min.z > v.z) min.z = v.z;
    if (max.x < v.x) max.x = v.x;
    if (max.y < v.y) max.y = v.y;
    if (max.z < v.z) max.z = v.z;
  }

  return out;
}

/// the MinMax use axis as unit vector, and (0,0,0) as origin point.
MinMax extractMinMaxProjection(List<Vector3> vs, Vector3 axis, MinMax out) {
  var p = vs[0].dot(axis);
  out.min = p;
  out.max = p;
  for (int i = 1; i < vs.length; i++) {
    p = vs[i].dot(axis);
    if (p < out.min) out.min = p;
    if (p > out.max) out.max = p;
  }
}

abstract class IntersectionFinder {
  bool segment_segment(Vector3 a1, Vector3 a2, Vector3 b1, Vector3 b2, Vector4 acol);
  bool segment_sphere(Vector3 s1, Vector3 s2, Vector3 c, double r);
  bool sphere_sphere(Vector3 ca, double ra, Vector3 cb, double rb);
  bool aabb_aabb(Aabb3 b1, Aabb3 b2 );
  bool poly_poly(List<Vector3> a, List<Vector3> b);
}

/// TODO optimize: reduce Vector3 creation (each operation) by using instance cache (or by using x,y instead of vector)
/// May be future inspiration :
/// * http://www.realtimerendering.com/intersections.html
/// * http://www.kevlindev.com/gui/math/intersection/index.htm
/// * http://cse.csusb.edu/tong/courses/cs621/notes/intersect.php
/// * http://www.gamasutra.com/view/feature/3383/simple_intersection_tests_for_games.php
class IntersectionFinderXY implements IntersectionFinder {
  //with double approximation, use zeroEpsilon for test
  static const zeroEpsilon = 0.0001;

  // cache to avoid re-alloc
  var _v0 = new Vector3.zero();
  var _v1 = new Vector3.zero();
  var _v2 = new Vector3.zero();
  var _mm0 = new MinMax();
  var _mm1 = new MinMax();


//  double length2(Vector3 p0, Vector3 p1) {
//    var x = p1.x - p0.x;
//    var y = p1.y - p0.y;
//    return x*x + y*y;
//  }

  /// implementation from http://stackoverflow.com/questions/563198/how-do-you-detect-where-two-line-segments-intersect
  /// based on Andre LeMothe's ["Tricks of the Windows Game Programming Gurus"](http://rads.stackoverflow.com/amzn/click/0672323699).
  bool segment_segment(Vector3 sa1, Vector3 sa2, Vector3 sb1, Vector3 sb2, Vector4 acol) {
    var sa_x, sa_y, sb_x, sb_y;
    sa_x = sa2.x - sa1.x;     sa_y = sa2.y - sa1.y;
    sb_x = sb2.x - sb1.x;     sb_y = sb2.y - sb1.y;

    var u = (sa_x * sb_y - sb_x * sa_y);
    // u == 0 if segment are parallele, with double approximation, use 0.0001
    //if (u < zeroEpsilon && u > -zeroEpsilon ) return false;
    if (u == 0) return false;

    var s = ( sa_x * (sa1.y - sb1.y) - sa_y * (sa1.x - sb1.x)) / u;
    var t = ( sb_x * (sa1.y - sb1.y) - sb_y * (sa1.x - sb1.x)) / u;

    if (s >= 0 && s <= 1 && t >= 0 && t <= 1) {
      acol.x = sa1.x + (t * sa_x);
      acol.y = sa1.y + (t * sa_y);
      //acol.z = sa1.z;
      acol.w = t;
      return  true;
    }
    return false;
  }


  bool segment_sphere(Vector3 s1, Vector3 s2, Vector3 c, double r){

    var s1c = _v0;
    s1c.setFrom(c).sub(s1);
    var s = _v1;
    s.setFrom(s2).sub(s1);
    var sl2 = s.length2;
    var sp;
    if (sl2 == 0.0) {
      sp = s1;
    } else {
      double u = (s1c.x * s.x + s1c.y *s.y) / sl2; // s1c.dot(s)
      sp = (u < 0.0)? s1 : (u > 1.0) ? s2 : s.scale(u).add(s1);
    }
    var cs = _v2;
    cs.setFrom(c).sub(sp);
    double l2 = cs.length2;

    if (l2 > r * r)
      return false;

//    double l = math.sqrt(l2);
//    var t = (r - l) / l;
//    var coll = cs.scale(t).add(c);
//    ccol.setValues(coll.x, coll.y, coll.z, t);
    return true;

  }

  bool sphere_sphere(Vector3 ca, double ra, Vector3 cb, double rb) {
    var threshold = ra + rb;

    // Get the Cathetus
    var dx = (ca.x - cb.x);
    var dy = (ca.y - cb.y);

    // Calculate the distance
    var dis2 = dx * dx + dy * dy;

    // Returns whether the distance between the two particles is smaller then the sum of both radi
    return (threshold * threshold >= dis2);
  }

  bool aabb_aabb( Aabb3 b1, Aabb3 b2 ) {
    return ( b1.min.x <= b2.max.x) && ( b1.min.y <= b2.max.y )
        && ( b1.max.x >= b2.min.x ) && ( b1.max.y >= b2.min.y);
  }


  // use SAT check intersection (first againts the longer poly (nb of edge))
  // [a] and [b] should be clockwise concave polygone
  bool poly_poly(List<Vector3> a, List<Vector3> b) {
    var separated = false;

    separated = _poly_poly0(a, b);
    separated = separated || _poly_poly0(b, a);
    return !separated;
  }

  bool _poly_poly0(List<Vector3> a, List<Vector3> b) {
    var axis = _v0;
    MinMax amm = _mm0;
    MinMax bmm = _mm1;

    var separated = false;
    for (var i = 0; (!separated) && (i < a.length); i++) {
      // axis is the left normal of the side
      axis.setFrom(a[(i+1) % a.length]).sub(a[i]);
      var t = axis.x;
      axis.x = - axis.y;
      axis.y = t;

      extractMinMaxProjection(a, axis, amm);
      extractMinMaxProjection(b, axis, bmm);
      separated = isSeparated(amm.min, amm.max, bmm.min, bmm.max);
    }
    return separated;
  }
}
