library ease_test;

import 'package:unittest/unittest.dart';
import 'package:dartemis_toolbox/collisions.dart';
import 'package:vector_math/vector_math.dart';

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
      sat.scan((a, b){
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
      sat.scan((a, b){
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
      sat.scan((a, b){
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
      sat.scan((a, b){
        nbCall++;
        var z = (a.compareTo(b) < 0) ? b + a : a + b;
        expect(done, isNot(contains(z)));
        done.add(z);
      });
      expect(nbCall, done.length);
      expect(nbCall, (2 * n + 1) + ((n * (n - 1) / 2)).toInt());
    });
  });
}

