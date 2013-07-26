part of collisions;

abstract class Resolver {
  void notifyCollisionParticleSegment(Particles psA, int iA, Segment s, double tcoll);
  void notifyCollisionParticleParticle(Particles psA, int iA, Particles psB, int iB, double tcoll);
}

class Resolver_Noop implements Resolver {
  void notifyCollisionParticleSegment(Particles psA, int iA, Segment s, double tcoll) {}
  void notifyCollisionParticleParticle(Particles psA, int iA, Particles psB, int iB, double tcoll){}
}

class Resolver_Print implements Resolver {
  void notifyCollisionParticleSegment(Particles psA, int iA, Segment s, double tcoll) {
    print("notifyCollisionParticleSegment(${psA}, ${iA}, ${s}, ${tcoll});");
  }
  void notifyCollisionParticleParticle(Particles psA, int iA, Particles psB, int iB, double tcoll){
    print("notifyCollisionParticleParticle(${psA}, ${iA}, ${psB}, ${iB}, ${tcoll});");
  }
}

class Resolver_Backward implements Resolver {
  backward(Vector3 vc, Vector3 vp, double t) {
    vc.sub(vp).scale(t).add(vp);
    vp.setValues(vc.x, vc.y, vc.z); //HACK to reset valocity// inertie
  }

  void notifyCollisionParticleSegment(Particles psA, int iA, Segment s, double tcoll) {
    //var t = math.max(0.0, tcoll - 0.5); //small repulsion should not override
    var t = 0.5 * tcoll;
    //ci.psA.position3d[ci.iA].setValues(ci.collA.x, ci.collA.y, ci.collA.z);
    backward(psA.position3d[iA], psA.position3dPrevious[iA], t);
    backward(s.ps.position3d[s.i1], s.ps.position3dPrevious[s.i1], t);
    backward(s.ps.position3d[s.i2], s.ps.position3dPrevious[s.i2], t);
    //print("${ci.psA.hashCode}  ... ${ci.s.ps.hashCode} ${ci.psA == ci.s.ps}");
  }

  void notifyCollisionParticleParticle(Particles psA, int iA, Particles psB, int iB, double tcoll) {
    var body1 = psA.position3d[iA];
    var body2 = psB.position3d[iB];
    var x = body1.x - body2.x;
    var y = body1.y - body2.y;
    var slength = x*x+y*y;
    var length = math.sqrt(slength);
    var target = psA.radius[iA] + psB.radius[iB];

    // if the spheres are closer
    // then their radii combined
    if(length < target){
      var factor = (length-target)/length;
      // move the spheres away from each other
      // by half the conflicting length
      body1.x -= x*factor*0.5;
      body1.y -= y*factor*0.5;
      body2.x += x*factor*0.5;
      body2.y += y*factor*0.5;
    }
  }

}
