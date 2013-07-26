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

import 'dart:math' as math;
import 'dart:typed_data';
import 'package:dartemis/dartemis.dart';
import 'package:vector_math/vector_math.dart';
import 'utils.dart';
import 'utils_math.dart';

//class ParticleInfo0 {
//  /// The age of the particle, in seconds.
//  double age = 0.0;
//
//  /// The energy of the particle.
//  double energy= 1.0;
//
//  /// Whether the particle is dead and should be removed from the stage.
//  var isDead = false;
//}


typedef Particles ParticlesConstructor(int nb);

class Particles extends Component {
  static final CT = ComponentTypeManager.getTypeFor(Particles);
  final int length;
  List<Vector3> position3d;
  //List<Vector3> get position3d => _position3d;
  /// all the positions in a single list (can be used in webgl to set vertices in one call)
  final Float32List position3dBuff;
  final List<Vector3> position3dPrevious;

  final ItemOption<int> color;

  /// The lifetime of the particle, in seconds.
  //final ItemOption<double> lifetime; = double.INFINITY;

  /// The mass of the particle ( 1.0 is the default ) is used to resolve Constraint distance.
  final ItemOption<double> mass;
  /// The radius of the particle, for collision approximation
  final ItemOption<double> radius;
  /// if the particule collide
  final ItemOption<int> collide;
  bool intraCollide;
  /// the (accumulated) acceleration on particule
  final ItemOption<Vector3> acc;
  /// the inertia on particule how it keep movement (velocity)
  final ItemOption<double> inertia;
  /// link to extra data, can be the host Entity or array, map, structure
  /// for energy, ttl, kind,...
  var extradata;

  Particles(length, {
    withPrevious: true,
    withColors: false, color0: 0x000000ff,
    withMass:   false, mass0: 1.0,
    withRadius: false, radius0: 1.0,
    withCollides: false, collide0: 0,
    withAccs: false, acc0: null,
    withInertias: false, inertia0: 1.0,
    this.intraCollide: false
  }) :
    this.length = length,
    position3dBuff = new Float32List(length * 3),
    position3dPrevious = withPrevious ? new List.generate(length, (i) => new Vector3.zero()) : null,
    color = withColors ? new ItemSome(new List.generate(length, (i) => color0)) : new ItemDefault(color0),
    mass = withMass ? new ItemSome(new List.generate(length, (i) => mass0)) : new ItemDefault(mass0),
    radius = withRadius ? new ItemSome(new List.generate(length, (i) => radius0)) : new ItemDefault(radius0),
    collide = withCollides ? new ItemSome(new List.generate(length, (i) => collide0)) : new ItemDefault(collide0),
    acc = withAccs ? new ItemSome(new List.generate(length, (i) => acc0 == null ? new Vector3.zero() : new Vector3.copy(acc0))) : new ItemDefault(acc0 == null ? new Vector3.zero() : acc0),
    inertia = withInertias ? new ItemSome(new List.generate(length, (i) => inertia0)) : new ItemDefault(inertia0)
  {
    position3d = new List.generate(length, (i) => new Vector3.view(new Float32List.view(position3dBuff.buffer, i * 4 * 3, 3)));
  }

  copyPosition3dIntoPrevious() {
    for (int i = length -1; i > -1; --i) {
      position3dPrevious[i].setFrom(position3d[i]);
    }
  }
}

class Segment {
  final Particles ps;
  final int i1;
  final int i2;
  int collide = 0;

  Segment(this.ps, this.i1, this.i2, [this.collide = 0]);
}

