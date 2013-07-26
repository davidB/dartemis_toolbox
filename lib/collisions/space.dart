// License [CC0](http://creativecommons.org/publicdomain/zero/1.0/)

part of collisions;

abstract class Space {
  void reset();
  bool addParticles(Particles ps);
  bool addSegment(Segment seg);
  void handleCollision();
}

class Space_Noop implements Space{
  void reset() {}
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

  void reset() {
    _particlesS.clear();
    _segments.clear();
  }

  /// return true if at least one [ps].collide != 0 (the Particles [ps] is included in the space)
  bool addParticles(Particles ps) {
    var b = false;
    for(int i = 0; i < ps.length; ++i) {
      var v = ps.collide[i];
      ps.collide[i] = v * v;
      b  = b || (ps.collide[i] != 0);
    }
    b = b && (ps.length > 0);
    if (b) {
      _particlesS.add(ps);
    }
    //if (ps.length > 0) print(">>>>>>>>>>>>>>>> ${ps.length} ${ps.collide[0]} ${b}");
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

/// Raw space (no optimisation, no grid, no quadtree, no ...) every particles
/// are check against every particles (inter [Particles] and intra [Particles] group)
/// and check against every [Segment]
class Space_QuadtreeXY implements Space{
  final QuadTreeXYAabb _grid;
  final Checker checker;
  final Resolver resolver;
  final Vector4 _scol = new Vector4.zero();

  final _pool = new _ProviderStack<_SQE>()
    ..createE = _SQE.ctor
    ..resetE =  _SQE.reset
    ;

  Space_QuadtreeXY(this.checker, this.resolver, {QuadTreeXYAabb grid}) : _grid = (grid == null)? new QuadTreeXYAabb(-500.0, -500.0, 1000.0, 1000.0, 10) : grid;

  void reset() {
    _grid.reset();
    _pool.reset();
  }

  /// return true if at least one [ps].collide != 0 (the Particles [ps] is included in the space)
  bool addParticles(Particles ps) {
    if (ps.length < 1) return false;
    var b = false;
    for(int i = ps.length - 1; i >= 0; --i) {
      b  = b || ps.collide[i] != 0;
    }
    if (b) {
      for(int i = ps.length - 1; i >= 0; --i) {
        ps.collide[i] = 1;
        var e = _pool.provide();
        e.ps = ps;
        e.i = i;
        extractAabbDisc(ps.position3d[i], ps.radius[i], e.aabb);
        _grid.insert(e.aabb, e);
      }
    }
    return b;
  }

  /// return true if [seg].collide != 0 (the Segment [seg] is include in the space)
  bool addSegment(Segment seg) {
    if (seg.collide != 0) {
      seg.collide = 1;
      var e = _pool.provide();
      e.segment = seg;
      extractAabbDisc2(seg.ps.position3d[seg.i1], seg.ps.position3d[seg.i2], 0.0, e.aabb);
      _grid.insert(e.aabb, e);
      return true;
    }
    return false;
  }

  void handleCollision() {
    _grid.scan(_handle0);
  }

  _handle0(_SQE e1, _SQE e2) {
    if (e1.ps != null && e2.ps != null) _handlePP(e1, e2);
    else if (e1.ps != null && e2.segment.ps != null) _handlePS(e1, e2);
    else if (e2.ps != null && e1.segment.ps != null) _handlePS(e2, e1);
    else {
      // segment vs segment collision not managed
    }
  }

  _handlePP(_SQE e1, _SQE e2) {
    if (e1.ps != e2.ps  || e1.ps.intraCollide) {
      if(checker.collideParticleParticle(e1.ps, e1.i, e2.ps, e2.i, _scol)){
        resolver.notifyCollisionParticleParticle(e1.ps, e1.i, e2.ps, e2.i, _scol.w);
      }
    }
  }

  _handlePS(_SQE e1, _SQE e2) {
    if (e1.ps != e2.segment.ps  || e1.ps.intraCollide) {
      if (checker.collideParticleSegment(e1.ps, e1.i, e2.segment, _scol)) {
        resolver.notifyCollisionParticleSegment(e1.ps, e1.i, e2.segment, _scol.w);
      }
    }
  }

}

class _SQE {
  final aabb = new Aabb3();
  Particles ps;
  int i;
  Segment segment;

  static ctor() => new _SQE();
  static reset(e) {
    e.ps = null;
    e.i = -1;
    e.segment = null;
  }
}

class _ProviderStack<E> {
  Function createE;
  Function resetE;
  final _stack = new List<E>();
  var _nextI = 0;

  E provide(){
    var e = null;
    if (_nextI == _stack.length) {
      e = createE();
      _stack.add(e);
    } else {
      e = _stack[_nextI];
      resetE(e);
    }
    _nextI++;
    return e;
  }

  reset() {
    _nextI = 0;
  }

  freemem() {
    reset();
    _stack.clear();
  }

  get capacity => _stack.length;
}