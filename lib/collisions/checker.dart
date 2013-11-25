// License [CC0](http://creativecommons.org/publicdomain/zero/1.0/)

part of collisions;

abstract class Checker {
  bool collideParticleParticle(Particles psA, int iA, Particles psB, int iB, Vector4 acol);
  bool collideParticleSegment(Particles psA, int iA, Segment s, Vector4 scol);
}

class Checker_Noop implements Checker{
  var check = false;
  bool collideParticleParticle(Particles psA, int iA, Particles psB, int iB, Vector4 acol) => check;
  bool collideParticleSegment(Particles psA, int iA, Segment s, Vector4 scol) => check;
}

/// Check against the last motion of particles and segment
/// **Ignore radius of each particle**
class Checker_ParticleMvt0 implements Checker{
  final IntersectionFinder _intf = new IntersectionFinderXY();
  final _v0 = new Vector3.zero();
  final _v1 = new Vector3.zero();
  final _v2 = new Vector3.zero();
  final _v3 = new Vector3.zero();
  /// Returns whether two particles A ([psA] + [iA]) and B [psB] + [iB]) intersect
  /// [psA.collide[iA]] and [psB.collide[iB]] are set to true if collision.
  /// Doesn't check if provided particles are the same or part of same group,... should be done before calling.
  /// * **Ignore radius of each particle**
  /// * check against the movement of the particles A and B (previous -> current)
  collideParticleParticle(Particles psA, int iA, Particles psB, int iB, Vector4 acol) {
    //var b = intf.sphere_sphere(psA.position3d[iA], psA.radius[iA], psB.position3d[iB], psA.radius[iB]);
    var pa0 = psA.position3dPrevious[iA];
    var pa1 = psA.position3d[iA];
    var pb0 = psB.position3dPrevious[iB];
    var pb1 = psB.position3d[iB];
    if (pa0 == pa1){
      pa0 = _v0.setFrom(pa0);
      pa0.x = pa0.x - psA.radius[iA];
      pa1 = _v1.setFrom(pb1);
      pa1.x = pa1.x + psA.radius[iA];
    }
    if (pb0 == pb1){
      pb0 = _v2.setFrom(pb0);
      pb0.x = pb0.x - psB.radius[iB];
      pb1 = _v3.setFrom(pb1);
      pb1.x = pb1.x + psB.radius[iB];
    }
    var b = _intf.segment_segment(pa0, pa1, pb0, pb1, acol);
    if (b) {
      psA.collide[iA] = -1;
      psB.collide[iB] = -1;
    }
    return b;
  }

  /// Returns whether the provided particle A and the segment from B intersect
  /// Doesn't check if provided particles are the same or part of same group,... should be done before calling.
  /// * **Ignore radius of each particle**
  /// * check against the movement of the particle A (previous -> current)
  /// * **Ignore movement of segment**, only check against last position of the segment
  collideParticleSegment(Particles psA, int iA, Segment s, Vector4 scol) {
    var b = false;
    //b = b || collideParticleSegment0(psA.position3dPrevious[iA], psA.position3d[iA], psA.radius[iA], s.ps.position3dPrevious[s.i1], s.ps.position3d[s.i1], s.ps.position3dPrevious[s.i2], s.ps.position3d[s.i2], intf, ci);
    //b = b || intf.segment_sphere(s.ps.position3d[s.i1], s.ps.position3d[s.i2], psA.position3d[iA], psA.radius[iA]);
    var pa0 = psA.position3dPrevious[iA];
    var pa1 = psA.position3d[iA];
    // create a segment perpendicular to input segment for immobile particle
    if (pa0 == pa1){
      _v3.setFrom(s.ps.position3d[s.i1]).sub(s.ps.position3d[s.i2]);
      _v3.normalize().scale(psA.radius[iA]);
      var t = _v3.x;
      _v3.x = _v3.y;
      _v3.y = t;
      pa0 = _v0.setFrom(pa0).sub(_v3);
      pa1 = _v1.setFrom(pa0).add(_v3);
    }
    b = b || _intf.segment_segment(pa0, pa1, s.ps.position3d[s.i1], s.ps.position3d[s.i2], scol);

    if (b) {
      psA.collide[iA] = -1;
      s.collide = -1;
    }
    return b;
  }
}

/// Check only the current position3d of particles and segment
class Checker_T1 implements Checker{
  final IntersectionFinder _intf = new IntersectionFinderXY();

  /// Returns whether two particles A ([psA] + [iA]) and B [psB] + [iB]) intersect
  /// [psA.collide[iA]] and [psB.collide[iB]] are set to true if collision.
  /// Doesn't check if provided particles are the same or part of same group,... should be done before calling.
  /// take care of radius of each particle
  collideParticleParticle(Particles psA, int iA, Particles psB, int iB, Vector4 acol) {
    //psA = psA as Particles;
    var b = _intf.sphere_sphere(psA.position3d[iA], psA.radius[iA], psB.position3d[iB], psA.radius[iB]);
    if (b) {
      psA.collide[iA] = -1;
      psB.collide[iB] = -1;
    }
    return b;
  }

  /// Returns whether the provided particle A and the segment [s]
  /// Doesn't check if provided particles are the same or part of same group,... should be done before calling.
  /// only check against last position of the segment
  collideParticleSegment(Particles psA, int iA, Segment s, Vector4 scol) {
    var b = false;
    b = b || _intf.segment_sphere(s.ps.position3d[s.i1], s.ps.position3d[s.i2], psA.position3d[iA], psA.radius[iA]);

    if (b) {
      psA.collide[iA] = -1;
      s.collide = -1;
    }
    return b;
  }
}

/// Check by intersection of polygon particles are converted into rectangle :
///  * width : start/end point x 2 radius (normal of displacement),
///  * longer : displacement
/// Segment : previous[s.i1], previous[s.i2], current[s.i2], current[s.i1] (ignore radius)
class Checker_MvtAsPoly4 implements Checker{
  // print info (for debugging)
  var printCollidePS = false;
  final IntersectionFinder _intf = new IntersectionFinderXY();
  var _v0 = new Vector3.zero();
  var _poly0 = new Poly4();
  var _poly1 = new Poly4();

  /// Returns whether two particles A ([psA] + [iA]) and B [psB] + [iB]) intersect
  /// [psA.collide[iA]] and [psB.collide[iB]] are set to true if collision.
  /// Doesn't check if provided particles are the same or part of same group,... should be done before calling.
  /// take care of radius of each particle, if any radius == 0.0 then no collision
  collideParticleParticle(Particles psA, int iA, Particles psB, int iB, Vector4 acol) {
    //TODO optimisation (less computation if (psA.radius[iA] == 0.0 && psB.radius[iB] == 0.0) make segment_segment or no collision)
    var b = (psA.radius[iA] == 0.0 || psB.radius[iB] == 0.0) ?
      false
      : _checkPoly4(_makePoly4_P(psA, iA, _poly0), _makePoly4_P(psB, iB, _poly1), acol);
    if (b) {
      psA.collide[iA] = -1;
      psB.collide[iB] = -1;
      var v = psA.position3d[iA];
      acol.setValues(v.x, v.y, v.z, 1.0);
    }
    return b;
  }

  /// Returns whether the provided particle A and the segment [s]
  /// Doesn't check if provided particles are the same or part of same group,... should be done before calling.
  collideParticleSegment(Particles psA, int iA, Segment s, Vector4 scol) {
    var b = _checkPoly4(_makePoly4_P(psA, iA, _poly0), _makePoly4_S(s, _poly1), scol);
    if (b) {
      if (printCollidePS) print("[DEBUG] collide PS ${_poly0.nbPoints} ${_poly1.nbPoints} // ${_poly0.points} // ${_poly1.points}");
      psA.collide[iA] = -1;
      s.collide = -1;
      //TODO project scol on segment (final position)
      var v = psA.position3d[iA];
      scol.setValues(v.x, v.y, v.z, 1.0);
    }
    return b;
  }

  _checkPoly4(Poly4 poly0, Poly4 poly1, Vector4 scol) {
    var out = false;
    if (poly0.nbPoints == 1) {
      if (poly1.nbPoints == 1) {
        out = poly0.points[0] == poly1.points[0];
      } else if (poly1.nbPoints == 2) {
        out = _intf.segment_sphere(poly1.points[0], poly1.points[1], poly0.points[0], 0.0);
      } else {
        out = _intf.poly_point(poly1.points, poly0.points[0]);
      }
    } else if (poly0.nbPoints == 2) {
      if (poly1.nbPoints == 1) {
        out = _intf.segment_sphere(poly0.points[0], poly0.points[1], poly1.points[0], 0.0);
      } else if (poly1.nbPoints == 2) {
        out = _intf.segment_segment(poly0.points[0], poly0.points[1], poly1.points[0], poly1.points[1], scol);
      } else {
        out = _intf.poly_segment(poly1.points, poly0.points[0], poly0.points[1]);
      }
    } else {
      if (poly1.nbPoints == 1) {
        out = _intf.poly_point(poly0.points, poly1.points[0]);
      } else if (poly1.nbPoints == 2) {
        out = _intf.poly_segment(poly0.points, poly1.points[0], poly1.points[1]);
      } else {
        out = _intf.poly_poly(poly0.points, poly1.points);
      }
    }
    return out;
  }

  _makePoly4_S(Segment s, Poly4 out) {
    var points = out.points;
    if (VXY.eq(s.ps.position3dPrevious[s.i1], s.ps.position3d[s.i1]) && VXY.eq(s.ps.position3dPrevious[s.i2], s.ps.position3d[s.i2])) {
      out.nbPoints = 2;
      points[0].setFrom(s.ps.position3d[s.i2]);
      points[1].setFrom(s.ps.position3d[s.i1]);
      points[0].z = 0.0;
      points[1].z = 0.0;
    } else {
      out.nbPoints = 4;
      points[0].setFrom(s.ps.position3dPrevious[s.i1]);
      points[1].setFrom(s.ps.position3dPrevious[s.i2]);
      points[2].setFrom(s.ps.position3d[s.i2]);
      points[3].setFrom(s.ps.position3d[s.i1]);
      points[0].z = 0.0;
      points[1].z = 0.0;
      points[2].z = 0.0;
      points[3].z = 0.0;
    }
    return out;
  }

  // if no displacement (< r/10) then an outside square is return;
  _makePoly4_P(Particles ps, int i, Poly4 out) {
    var pn = ps.position3d[i];
    var pp = ps.position3dPrevious[i];
    var r = ps.radius[i];
    var points = out.points;
    if (r == 0.0) {
      points[0].x = pp.x;
      points[0].y = pp.y;
      points[0].z = 0.0;
      if (VXY.eq(pp, pn)) {
        out.nbPoints =  1;
      } else {
        out.nbPoints =  2;
        points[1].x = pn.x;
        points[1].y = pn.y;
        points[1].z = 0.0;
      }
    } else {
      out.nbPoints = 4;
      // _v0.setFrom(pn).sub(pp);
      var vx = pn.x - pp.x;
      var vy = pn.y - pp.y;
      //var l = _v0.length;
      var l2 = vx * vx + vy * vy;
      if ((l2 * 10) < r) {
        points[0].x = pn.x + r;
        points[0].y = pn.y + r;
        points[1].x = pn.x + r;
        points[1].y = pn.y - r;
        points[2].x = pn.x - r;
        points[2].y = pn.y - r;
        points[3].x = pn.x - r;
        points[3].y = pn.y + r;
      } else {
        //var t = _v0.x;
        //_v0.scale(r / l);
        var rl = r / math.sqrt(l2);
        var t = vx;
        vx = -vy * rl;
        vy = t * rl;
        //points[0].setFrom(pp).add(_v0);
        points[0].x = pp.x + vx;
        points[0].y = pp.y + vy;
        //points[1].setFrom(ps.position3dPrevious[i]).sub(_v0);
        points[1].x = pp.x - vx;
        points[1].y = pp.y - vy;
        //points[2].setFrom(ps.position3d[i]).sub(_v0);
        points[2].x = pn.x - vx;
        points[2].y = pn.y - vy;
        //points[3].setFrom(ps.position3d[i]).add(_v0);
        points[3].x = pn.x + vx;
        points[3].y = pn.y + vy;
      }
      points[0].z = 0.0;
      points[1].z = 0.0;
      points[2].z = 0.0;
      points[3].z = 0.0;
    }
    return out;
  }
}

class Poly4 {
  final points = new List.generate(4, (i) => new Vector3.zero(), growable: false);
  int nbPoints = 4;
}
