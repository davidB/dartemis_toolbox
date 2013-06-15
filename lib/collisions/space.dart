part of collisions;

abstract class Space {
  void clear();
  bool addParticles(Particles ps);
  bool addSegment(Segment seg);
  void handleCollision();
}

class Space_Noop implements Space{
  void clear() {}
  bool addParticles(Particles ps) => true;
  bool addSegment(Segment seg) => true;
  void handleCollision() {}
}

/// Raw space (no optimisation, no grid, no quadtree, no ...) every particles
/// are check against every particles (inter [Particles] and intra [Particles] group)
/// and check against every [Segment]
class Space_XY0 implements Space{

  final List<Particles> _particlesS = new List();
  final List<Segment> _segments = new List();
  final Checker checker;
  final Resolver resolver;
  final Vector4 _scol = new Vector4.zero();

  Space_XY0(this.checker, this.resolver);

  void clear() {
    _particlesS.clear();
    _segments.clear();
  }

  /// return true if at least one [ps].collide != 0 (the Particles [ps] is included in the space)
  bool addParticles(Particles ps) {
    var b = true;
    for(int i = 0; i < ps.length; ++i) {
      var v = ps.collide[i];
      ps.collide[i] = v * v;
      b  = b || (ps.collide[i] != 0);
    }
    if (b) {
      _particlesS.add(ps);
    }
    return b;
  }

  /// return true if [seg].collide != 0 (the Segment [seg] is include in the space)
  bool addSegment(Segment seg) {
    //print("try add segment");
    if (seg.collide != 0) {
      seg.collide = 1;
      _segments.add(seg);
      return true;
    }
    return false;
  }

  //TODO optimize with a grid, a quadtree, ...
  void handleCollision() {
    for (int i = 0; i < _particlesS.length; ++i) {
      //TODO check intraCollide
      _detectCollisionInterParticles(i);
      _detectCollisionParticlesSegments(i);
      _detectCollisionIntraParticles(i);
    }
  }

  void _detectCollisionInterParticles(int i) {
    var psA = _particlesS[i];
    for (int j = i+1; j < _particlesS.length; ++j) {
      var psB = _particlesS[j];
      for(int iA = 0; iA < psA.length; ++iA) {
        if (psA.collide[iA] != 0) {
          for(int iB = 0; iB < psB.length; ++iB) {
            if (psB.collide[iB] != 0) {
              if(checker.collideParticleParticle(psA, iA, psB, iB, _scol)){
                resolver.notifyCollisionParticleParticle(psA, iA, psB, iB, _scol.w);
              }
            }
          }
        }
      }
    }
  }

  void _detectCollisionIntraParticles(int i) {
    var psA = _particlesS[i];
    if (!psA.intraCollide) return;
    for(int iA = 0; iA < psA.length; ++iA) {
      if (psA.collide[iA] != 0) {
        for(int iB = iA+1; iB < psA.length; ++iB) {
          if (psA.collide[iB] != 0) {
            if(checker.collideParticleParticle(psA, iA, psA, iB, _scol)){
              resolver.notifyCollisionParticleParticle(psA, iA, psA, iB, _scol.w);
            }
          }
        }
      }
    }
  }

  void _detectCollisionParticlesSegments(int i) {
    var psA = _particlesS[i];
    for(int iS = 0; iS < _segments.length; ++iS) {
      var s = _segments[iS];
      if (psA == s.ps) continue;
      for(int iA = 0; iA < psA.length; ++iA) {
        if (psA.collide[iA] != 0) {
          //print("test ${psA.position3d[iA]}");
          if (checker.collideParticleSegment(psA, iA, s, _scol)) {
            resolver.notifyCollisionParticleSegment(psA, iA, s, _scol.w);
          }
        }
      }
    }
  }
}
