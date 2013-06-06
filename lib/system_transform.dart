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
library system_transform;

import 'dart:math' as math;
import 'package:dartemis/dartemis.dart';
import 'package:vector_math/vector_math.dart';
import 'utils_math.dart' as math2;

class Transform extends ComponentPoolable {
  static final CT = ComponentTypeManager.getTypeFor(Transform);

  Vector3 position3d;
  Vector3 rotation3d;
  Vector3 scale3d;

  // 2d view
  Vector2 _position2d = new Vector2.zero();
  double get angle => rotation3d.z;
  set angle(double v) => rotation3d.z = v;
  Vector2 get position {
    _position2d.x = position3d.x;
    _position2d.y = position3d.y;
    return _position2d;
  }
  set position(Vector2 v) {
    position3d.x = v.x;
    position3d.y = v.y;
  }

  Transform._();
  static _ctor() => new Transform._();
  factory Transform.w2d(double x, double y, double a) {
    return new Transform.w3d(new Vector3(x, y, 0.0), new Vector3(0.0, 0.0, a));
  }
  factory Transform.w3d(Vector3 position, [Vector3 rotation, Vector3 scale]) {
    var c = new Poolable.of(Transform, _ctor) as Transform;
    c.position3d = position;
    c.rotation3d = (rotation == null) ? new Vector3(0.0, 0.0, 0.0) : rotation;
    c.scale3d = (scale == null) ? new Vector3(1.0, 1.0, 1.0) : scale;
    return c;
  }
  /// this method mofidy the Transform (usefull for creation)
  /// return this
  Transform lookAt(Vector3 target, [Vector3 up]) {
    math2.lookAt(target, position3d, rotation3d, up);
    return this;
  }
}

//class TransformLink extends Component {
//  /// like parent in a scene tree;
//  Entity target;
//  /// use to cache which previous target we should remove from followers
//  Entity _previousTarget;
//
//  /// like children in a scene tree;
//  List<Entity> _followers;
//
//  /// should delete the host entity when target entity is deleted ?
//  var deleteOnTargetDeleted = true;
//
//  mat4 localTransform;
//}

//class System_TransformLink extends EntitySystem {
//  ComponentMapper<Transform> _transformMapper;
//  ComponentMapper<TransformLink> _transformLinkMapper;
//
//  System_TransformLink() : super(Aspect.getAspectForAllOf([Transform, TransformLink]));
//
//  void initialize(){
//    _transformMapper = new ComponentMapper<Transform>(Transform, world);
//    _transformLinkMapper = new ComponentMapper<TransformLink>(TransformLink, world);
//  }
//
//  bool checkProcessing() => true;
//
//  void processEntities(ReadOnlyBag<Entity> entities) {
//    entities.forEach(e));
//    var t = _transformMapper.get(entity);
//    t.position3d.copyFrom(_targetPosition).add(follower.targetTranslation);
//    t.lookAt(_targetPosition);
//  }
//
//  void changeInFollowers(ReadOnlyBag<Entity> entities) {
//    var roots = List<Entity>();
//    entities.forEach((e) {
//      var tfl =
//    });
//  }
//}