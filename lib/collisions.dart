library collisions;


import 'dart:math' as math;
import 'package:vector_math/vector_math.dart';
import 'system_particles.dart';
import 'utils_math.dart';
import 'package:dartemis/dartemis.dart'; // for poolable

part 'collisions/checker.dart';
part 'collisions/resolver.dart';
part 'collisions/space.dart';
part 'collisions/quadtreexy.dart';

//TODO add test-case : (collision at end, no-collision, collision during displacement not at start/end) x (immobile , mobile) vs (immobile, mobile)
//TODO add test-case : collision on radius (not center)