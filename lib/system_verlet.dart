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
library darticles;

import 'package:dartemis/dartemis.dart';
import 'dart:math' as math;
import 'package:dartemis_addons/system_particles.dart';

typedef  void Constraint(double stepCoef);

class Constraints extends Component {
  static final CT = ComponentTypeManager.getTypeFor(Constraints);
  final l = new List<Constraint>();
}

class System_Simulator extends EntitySystem {
  ComponentMapper<Particles> _particlesMapper;
  ComponentMapper<Constraints> _constraintsMapper;
  //var gravity = new vec3(0, 0.2, 0.0);
  var friction = 0.99;
  //var groundFriction = 0.8;
  var step = 10;

  System_Simulator({this.step}) : super(Aspect.getAspectForAllOf([Particles, Constraints]));

  void initialize(){
    _particlesMapper = new ComponentMapper<Particles>(Particles, world);
    _constraintsMapper = new ComponentMapper<Constraints>(Constraints, world);
  }

  bool checkProcessing() => true;

  void processEntities(ReadOnlyBag<Entity> entities) {
    var particlesG = new List(entities.size);
    var constraintsG = new List(entities.size);
    entities.forEach((e){
      particlesG.add(_particlesMapper.get(e));
      constraintsG.add(_constraintsMapper.get(e));
    });
    particlesG.forEach((c) {
      c.l.forEach((p) {
        // calculate velocity
        var velocity = (p.position3d - p.position3dPrevious).scale(friction);

//        // ground friction
//        if (particles[i].pos.y >= this.height-1 && velocity.length2() > 0.000001) {
//          var m = velocity.length();
//          velocity.x /= m;
//          velocity.y /= m;
//          velocity.mutableScale(m*this.groundFriction);
//        }

        // save last good state
        p.position3dPrevious.copy(p.position3d);

        // gravity
        //p.position3d.add(this.gravity);

        // inertia
        p.position3d.add(velocity);
      });
    });

    // relax
    var stepCoef = 1/step;
    constraintsG.forEach((c) {
      for (var i=0; i<step; ++i) {
        c.l.forEach((j) {
          j(stepCoef);
        });
      }
    });

//    // bounds checking
//    for (c in this.composites) {
//      var particles = this.composites[c].particles;
//      for (i in particles)
//        this.bounds(particles[i]);
//    }
  }


}
