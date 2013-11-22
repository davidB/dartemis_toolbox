library collisions_test;

import 'package:unittest/unittest.dart';
import 'package:dartemis_toolbox/collisions.dart';
import 'package:vector_math/vector_math.dart';
import 'package:dartemis_toolbox/system_verlet.dart' as Verlet;
import 'package:dartemis_toolbox/system_particles.dart';

main() {
  group("quadtree", () {
    var x = 0.0;
    var y = 0.0;
    var w = 100.0;
    var h = 50.0;
    var maxDepth = 4;
    var maxChildren = 4;
    var aabbTL = new Aabb3.minmax(new Vector3(x + 10.0, y + 10.0, 0.0), new Vector3(x + 15.0, y + 12.0, 0.0));
    var aabbTR = new Aabb3.minmax(new Vector3(x + w /2 + 10.0, y + 10.0, 0.0), new Vector3(x + w / 2 + 15.0, y + 12.0, 0.0));
    var aabbBR = new Aabb3.minmax(new Vector3(x + w /2 + 10.0, y + h / 2 + 10.0, 0.0), new Vector3(x + w / 2 + 15.0, y + h / 2 + 12.0, 0.0));
    var aabbBL = new Aabb3.minmax(new Vector3(x + 10.0, y + h / 2 + 10.0, 0.0), new Vector3(x + 15.0, y + h / 2 + 12.0, 0.0));
    var aabbT  = new Aabb3.minmax(new Vector3(x + 10.0, y + 10.0, 0.0), new Vector3(x + 10.0 + w / 2, y + 12.0, 0.0));
    var aabbB  = new Aabb3.minmax(new Vector3(x + 10.0, y + h / 2 + 10.0, 0.0), new Vector3(x + 10.0 + w / 2, y + h / 2 + 12.0, 0.0));
    test('test for simple insertion (TL, TR, BR BL) <= maxChildren', () {
      var sat = new QuadTreeXYAabb(x, y, w, h, maxDepth, maxChildren);
      expect(sat.nbItems, equals(0));
      expect(sat.isLeaf, equals(true));
      sat.insert(aabbTL, "tl");
      expect(sat.nbItems, equals(1));
      expect(sat.isLeaf, equals(true));
      sat.insert(aabbTR, "tr");
      expect(sat.nbItems, equals(2));
      expect(sat.isLeaf, equals(true));
      sat.insert(aabbBR, "br");
      expect(sat.nbItems, equals(3));
      expect(sat.isLeaf, equals(true));
      sat.insert(aabbBL, "bl");
      expect(sat.nbItems, equals(4));
      expect(sat.isLeaf, equals(true));
    });
    test('test for insertion + collision 3 x TL', () {
      var sat = new QuadTreeXYAabb(x, y, w, h, maxDepth, maxChildren);
      for (var i = 0; i < 3; i++) {
        sat.insert(aabbTL, "tl${i}");
      }
      expect(sat.nbItems, equals(3));
      expect(sat.isLeaf, equals(true));
      var nbCall = 0;
      sat.scanVs((a, b){
        nbCall++;
        expect(a[0], equals(b[0]));
        expect(a[1], equals(b[1]));
        expect(a[2], isNot(equals(b[2])));
      });
      expect(nbCall, 2 + 1);
    });
    test('test for collision  split 3 x TL + 3 x TR', () {
      var sat = new QuadTreeXYAabb(x, y, w, h, maxDepth, maxChildren);
      for (var i = 0; i < 3; i++) {
        sat.insert(aabbTL, "tl${i}");
        sat.insert(aabbTR, "tr${i}");
      }
      expect(sat.nbItems, equals(6));
      expect(sat.isLeaf, equals(false));
      var nbCall = 0;
      sat.scanVs((a, b){
        nbCall++;
        expect(a[0], equals(b[0]));
        expect(a[1], equals(b[1]));
        expect(a[2], isNot(equals(b[2])));
      });
      expect(nbCall, (2 + 1) * 2 );
    });
    test('test for collision split and out of subnode : 3 x TL + 3 x TR + T', () {
      var sat = new QuadTreeXYAabb(x, y, w, h, maxDepth, maxChildren);
      var n = maxChildren - 1;
      for (var i = 0; i < n; i++) {
        sat.insert(aabbTL, "tl${i}");
        sat.insert(aabbTR, "tr${i}");
      }
      sat.insert(aabbT, "tx5");
      expect(sat.nbItems, equals(7));
      expect(sat.isLeaf, equals(false));
      var nbCall = 0;
      sat.scanVs((a, b){
        nbCall++;
        expect(a[0], equals(b[0]));
        expect(a[2], isNot(equals(b[2])));
      });
      // (n * (n - 1) / 2) intra tl (in the same subnode)
      // (1 * (n + n) tx5 check vs n * tl + n * tr
      expect(nbCall, (n * (n - 1) / 2) * 2 + 1 * (n + n));
    });
    test('test for collision split and out of subnode : (maxChildren x maxDepth) x TL + 1 x T + 1 B', () {
      var sat = new QuadTreeXYAabb(x, y, w, h, maxDepth, maxChildren);
      var n = maxChildren * maxDepth;
      for (var i = 0; i < n; i++) {
        sat.insert(aabbTL, "a${i}");
      }
      sat.insert(aabbT, "t");
      sat.insert(aabbB, "b");
      expect(sat.nbItems, equals(n + 2));
      expect(sat.isLeaf, equals(false));
      var nbCall = 0;
      var done = new Set();
      sat.scanVs((a, b){
        nbCall++;
        var z = (a.compareTo(b) < 0) ? b + a : a + b;
        expect(done, isNot(contains(z)));
        done.add(z);
      });
      expect(nbCall, done.length);
      expect(nbCall, (2 * n + 1) + (n * (n - 1) ~/ 2));
    });
  });
  group("scan near", () {
    var spaceHelper = new SpaceHelper();
    var area0 = new Aabb3()
    ..min.setValues(0.0, 0.0, 0.0)
    ..max.setValues(10.0, 10.0, 0.0)
    ;
    var box_origin = new Vector3(3.0, 5.0, 0.0);
    var box_width = new Vector3(3.0, 0.0, 0.0);
    var box_height = new Vector3(0.0, 3.0, 0.0);
    var space0 = new Space_XY0(new Checker_Noop(), new Resolver_Noop());
    _addBox(space0, box_origin, box_width, box_height);
    var space1 = new Space_QuadtreeXY(new Checker_Noop(), new Resolver_Noop(), grid : new QuadTreeXYAabb(area0.min.x, area0.min.y, area0.max.x - area0.min.x, area0.max.y - area0.min.y));
    _addBox(space1, box_origin, box_width, box_height);
    test('test for all', () {
      var sat = space0;
      var nbCall = 0;
      sat.scanNear(area0.min, area0.max,(x){
        nbCall++;
      });
      expect(nbCall, 4);
    });
    test('findFirstIntersection length 0 never collide', (){
      var sat = space1;
      [
        area0.min,
        area0.max,
        new Vector3(1.0, 0.0, 0.0), // a point out of box
        new Vector3(3.0, 5.0, 0.0), // a point in box
        new Vector3(3.0 - 3.0, 5.0, 0.0), // a point in edge of box
        new Vector3(3.0 - 3.0, 5.0 - 3.0, 0.0) // a poinr in corner of box
      ].forEach((v0){
        expect( spaceHelper.findFirstIntersection(sat, v0, v0), lessThan(0.0));
      });
    });
    test('findFirstIntersection no collide (before box)', (){
      var sat = space1;
      var v0 = box_origin - box_height.scaled(0.5) + box_width.scaled(0.5);
      var v1 = v0 + box_height.scaled(0.3);
      var scol0 = spaceHelper.findFirstIntersection(space0, v0, v1);
      var scol1 = spaceHelper.findFirstIntersection(space1, v0, v1);
      expect(scol1 , scol0);
      expect(scol1 , -1.0);
    });
    test('findFirstIntersection collide (after box)', (){
      var v0 = box_origin - box_height.scaled(0.5) + box_width.scaled(0.5);
      var v1 = v0 + box_height.scaled(2.0);
      var scol0 = spaceHelper.findFirstIntersection(space0, v0, v1);
      var scol1 = spaceHelper.findFirstIntersection(space1, v0, v1);
      expect(scol1 , scol0);
      expect(scol1 , 0.25);
    });
    test('findFirstIntersection collide (inside box)', (){
      var v0 = box_origin - box_height.scaled(0.5) + box_width.scaled(0.5);
      var v1 = v0 + box_height;
      var scol0 = spaceHelper.findFirstIntersection(space0, v0, v1);
      var scol1 = spaceHelper.findFirstIntersection(space1, v0, v1);
      expect(scol1 , scol0);
      expect(scol1 , 0.5);
    });
  });
}

_addBox(collSpace, Vector3 origin, Vector3 width, Vector3 height){
  var b = true;
  ParticlesConstructor genP = (nb) => new Particles(nb, withCollides: true, collide0: 1);
  var components = Verlet.makeParallelogram(origin, width, height, 1.0, genP);
  collSpace.addParticles(components[0]);
  Verlet.forEachSegment(components[1], (s) {
    s.collide = 1;
    b = collSpace.addSegment(s) && b;
  });
  return b;
}

