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
  final IntersectionFinder _intf = new IntersectionFinderXY();
  var _v0 = new Vector3.zero();
  var _poly0 = new List.generate(4, (i) => new Vector3.zero(), growable: false);
  var _poly1 = new List.generate(4, (i) => new Vector3.zero(), growable: false);

  /// Returns whether two particles A ([psA] + [iA]) and B [psB] + [iB]) intersect
  /// [psA.collide[iA]] and [psB.collide[iB]] are set to true if collision.
  /// Doesn't check if provided particles are the same or part of same group,... should be done before calling.
  /// take care of radius of each particle
  collideParticleParticle(Particles psA, int iA, Particles psB, int iB, Vector4 acol) {
    var b = _intf.poly_poly(makePoly4(psA, iA, _poly0), makePoly4(psB, iB, _poly1));
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
    _poly1[0].setFrom(s.ps.position3dPrevious[s.i1]);
    _poly1[1].setFrom(s.ps.position3dPrevious[s.i2]);
    _poly1[2].setFrom(s.ps.position3d[s.i2]);
    _poly1[3].setFrom(s.ps.position3d[s.i1]);
    var b = _intf.poly_poly(makePoly4(psA, iA, _poly0), _poly1);
    if (b) {
      psA.collide[iA] = -1;
      s.collide = -1;
      //TODO project scol on segment (final position)
      var v = psA.position3d[iA];
      scol.setValues(v.x, v.y, v.z, 1.0);
    }
    return b;
  }

  // if no displacement (< r/10) then an outside square is return;
  makePoly4(Particles ps, int i, List<Vector3> out) {
    _v0.setFrom(ps.position3d[i]).sub(ps.position3dPrevious[i]);
    var l = _v0.length;
    var r = ps.radius[i];
    if ((l * 10) < r) {
      out[0].setFrom(ps.position3d[i])
        ..x += r
        ..y += r
        ;
      out[1].setFrom(ps.position3d[i])
        ..x += r
        ..y -= r
        ;
      out[2].setFrom(ps.position3d[i])
        ..x -= r
        ..y -= r
        ;
      out[3].setFrom(ps.position3d[i])
        ..x -= r
        ..y += r
        ;
    } else {
      var t = _v0.x;
      _v0.x = - _v0.y;
      _v0.y = t;
      _v0.scale(r / l);
      out[0].setFrom(ps.position3dPrevious[i]).add(_v0);
      out[1].setFrom(ps.position3dPrevious[i]).sub(_v0);
      out[2].setFrom(ps.position3d[i]).sub(_v0);
      out[3].setFrom(ps.position3d[i]).add(_v0);
    }
    return out;
  }
}