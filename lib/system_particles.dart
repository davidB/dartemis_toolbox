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

///TODO lot of test (unit, ...)
///TODO benchmark, profiling, optimisation
library system_particles;

import 'package:dartemis/dartemis.dart';
import 'package:vector_math/vector_math.dart';

class Particle {
  final Vector3 position3d;

  Vector3 position3dPrevious = null;
  Particle([pos]): position3d = (pos==null)? new Vector3.zero() : pos;
}

class ParticleInfo0 {
  /// The lifetime of the particle, in seconds.
  double lifetime = double.INFINITY;

  int color = 0x000000ff;

  /// The scale of the particle ( 1 is normal size ).
  double scale = 1.0;

  /// The mass of the particle ( 1 is the default ).
  double mass = 1.0;

  /// The radius of the particle, for collision approximation
  double radius = 1.0;

  /// The age of the particle, in seconds.
  double age = 0.0;

  /// The energy of the particle.
  double energy= 1.0;

  /// Whether the particle is dead and should be removed from the stage.
  var isDead = false;
}

class Particles extends Component {
  static final CT = ComponentTypeManager.getTypeFor(Particles);
  final List<Particle> l;

  Particles([nb = 0]) :
    l = (nb == 0)
      ? new List<Particle>()
      : new List.generate(nb, (i) => new Particle())
      ;

}

class ParticleInfo0s extends Component {
  static final CT = ComponentTypeManager.getTypeFor(ParticleInfo0s);
  final List<ParticleInfo0> l;

  ParticleInfo0s([nb = 0]) :
    l = (nb == 0)
      ? new List<ParticleInfo0>()
      : new List.generate(nb, (i) => new ParticleInfo0())
      ;

}

//--- UpdateP ------------------------------------------------------------------

///// Update the [Particle.energy] based on its age and the easing function.
//UpdateP energyFromAge(ease.Ease easing) => (dt, Particle particle){
//  particle.age += dt;
//  if( particle.age >= particle.lifetime ) {
//    particle.energy = 0.0;
//    particle.isDead = true;
//  } else {
//    particle.energy = easing( particle.age / particle.lifetime, -1.0, 1.0);
//  }
//};
//
///// Update the transparency of the [Particle.color] based on the values defined
///// [startAlpha] and [endAlpha] and the [Particle.energy] level.
//UpdateP alphaFromEnergy({startAlpha : 1.0, endAlpha: 0.0}) => (dt, Particle particle){
//  num alpha = endAlpha + (startAlpha - endAlpha) * particle.energy;
//  particle.color = ( particle.color & 0xFFFFFF ) | ( ( alpha * 255 ).round() << 24 );
//};

