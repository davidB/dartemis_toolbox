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

/// Check only the current position3d of particles and segment
/// **Ignore radius of each particle**
class Checker_ParticleMvt0 implements Checker{
  final IntersectionFinder _intf = new IntersectionFinderXY();

  /// Returns whether two particles A ([psA] + [iA]) and B [psB] + [iB]) intersect
  /// [psA.collide[iA]] and [psB.collide[iB]] are set to true if collision.
  /// Doesn't check if provided particles are the same or part of same group,... should be done before calling.
  /// * **Ignore radius of each particle**
  /// * check against the movement of the particles A and B (previous -> current)
  collideParticleParticle(Particles psA, int iA, Particles psB, int iB, Vector4 acol) {
    //var b = intf.sphere_sphere(psA.position3d[iA], psA.radius[iA], psB.position3d[iB], psA.radius[iB]);
    var b = _intf.segment_segment(psA.position3dPrevious[iA], psA.position3d[iA], psB.position3dPrevious[iB], psB.position3d[iB], acol);
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
    b = b || _intf.segment_segment(psA.position3dPrevious[iA], psA.position3d[iA], s.ps.position3d[s.i1], s.ps.position3d[s.i2], scol);

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