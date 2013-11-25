library utils_math_test;

import 'package:unittest/unittest.dart';
import 'package:dartemis_toolbox/utils_math.dart' as math2;
import 'package:vector_math/vector_math.dart';

main() {
  group("Vector3",(){
    test("==", (){

      expect(new Vector3(49.0,49.0,0.0).storage == new Vector3(49.0,49.0,0.0).storage, equals(false), reason: "v3.storage == v3bis.storage (not supported by vector_math)");
      expect(new Vector3(49.0,49.0,0.0) == new Vector3(49.0,49.0,0.0), equals(false), reason: "v3 == v3bis (not supported by vector_math)");
      expect(math2.VXYZ.eq(new Vector3(49.0,49.0,0.0), new Vector3(49.0,49.0,0.0)), equals(true), reason: "eqV3(v3, v3bis) workaround");
    });
  });
  group("fct", (){
    test('isSeparated', (){
      expect(math2.isSeparated(0.0, 1.0, 2.0, 3.0), equals(true), reason : "no intersection");
      expect(math2.isSeparated(0.0, 2.0, 1.0, 3.0), equals(false), reason : "intersection");
      expect(math2.isSeparated(1.0, 2.0, 0.0, 3.0), equals(false), reason : "B include A");
      expect(math2.isSeparated(0.0, 3.0, 1.0, 2.0), equals(false), reason : "A include B");
      expect(math2.isSeparated(1.0, 2.0, 1.0, 2.0), equals(false), reason : "A in A");
    });
  });
  group("IntersectionFinderXY", (){
    var sut = new math2.IntersectionFinderXY();
    test('poly_point',(){
      //[0.10294092446565628,-131.0096435546875,0.0], [101.5,-122.5,0.0], [98.5,-122.5,0.0], [98.5,-119.5,0.0]] // [[133.2776336669922,732.2805786132812,0.0], [187.3511199951172,732.2805786132812,0.0], [187.3511199951172,732.280517578125,0.0], [133.2776336669922,732.280517578125,0.0]]
      var poly = [ new Vector3(1.0, 1.0,0.0), new Vector3(1.0, -1.0, 0.0), new Vector3(-1.0,-1.0,0.0), new Vector3(-1.0, 1.0,0.0)];
      expect(sut.poly_point(poly, new Vector3(2.0, 0.0, 0.0)), equals(false), reason : "point outside poly axis 1");
      expect(sut.poly_point(poly, new Vector3(0.0, 2.0, 0.0)), equals(false), reason : "point outside poly axis 2");
      expect(sut.poly_point(poly, new Vector3(2.0, 2.0, 0.0)), equals(false), reason : "point outside poly axis 2 & 1");
      expect(sut.poly_point(poly, new Vector3(0.0, 0.0, 0.0)), equals(true), reason : "point 0 inside poly");
      expect(sut.poly_point(poly, new Vector3(0.5, 0.0, 0.0)), equals(true), reason : "point inside poly");
      expect(sut.poly_point(poly, new Vector3(1.0, 0.0, 0.0)), equals(true), reason : "point on edge poly");
      expect(sut.poly_point(poly, poly[0]), equals(true), reason : "point on corner poly");
//      //[DEBUG] collide PS 1 4 // [[61.0,50.5,0.0], [95.44999694824219,4.550000190734863,0.0], [94.55000305175781,4.550000190734863,0.0], [94.55000305175781,5.449999809265137,0.0]] // [[61.187557220458984,59.05839157104492,3.532339096069336], [61.51143264770508,58.10496139526367,-0.46716880798339844], [61.51143264770508,58.10496139526367,-0.4671686887741089], [61.187557220458984,59.05839538574219,3.532339334487915]]
      poly = [[61.187557220458984,59.05839157104492,3.532339096069336], [61.51143264770508,58.10496139526367,-0.46716880798339844], [61.51143264770508,58.10496139526367,-0.4671686887741089], [61.187557220458984,59.05839538574219,3.532339334487915]].map((x) => new Vector3(x[0], x[1], x[2])).toList();
      expect(sut.poly_point(poly, new Vector3(61.0,50.5,0.0)), equals(false), reason : "wrong result if z is not ignored");
    });
    test('segment_sphere', () {
      // [[15.0,-121.0,0.0], [15.0,-121.0,0.0], [15.0,-121.0,0.0], [15.0,-121.0,0.0]] [[15.0,-71.00006103515625,0.0], [15.0,-101.00006103515625,0.0], [15.0,-101.00006103515625,0.0], [15.0,-71.00006103515625,0.0]]
      var poly0 = [ new Vector3(15.0,-121.0,0.0), new Vector3(15.0,-121.0,0.0), new Vector3(15.0,-121.0,0.0), new Vector3(15.0,-121.0,0.0)];
      var poly1 = [ new Vector3(15.0,-71.00006103515625,0.0), new Vector3(15.0,-101.00006103515625,0.0), new Vector3(15.0,-101.00006103515625,0.0), new Vector3(15.0,-71.00006103515625,0.0)];
      expect(sut.segment_sphere(new Vector3(1.0, 0.0, 0.0), new Vector3(4.0, 0.0, 0.0), new Vector3(2.0, 0.0, 0.0), 0.0), equals(true));
      expect(sut.segment_sphere(new Vector3(1.0, 0.0, 0.0), new Vector3(4.0, 0.0, 0.0), new Vector3(2.0, 0.1, 0.0), 0.0), equals(false));
      expect(sut.segment_sphere(new Vector3(1.0, 0.0, 0.0), new Vector3(4.0, 0.0, 0.0), new Vector3(2.0, 0.1, 0.0), 0.2), equals(true));
    });
    test('poly_segment', () {
      // [[15.0,-121.0,0.0], [15.0,-121.0,0.0], [15.0,-121.0,0.0], [15.0,-121.0,0.0]] [[15.0,-71.00006103515625,0.0], [15.0,-101.00006103515625,0.0], [15.0,-101.00006103515625,0.0], [15.0,-71.00006103515625,0.0]]
      var poly = [ new Vector3(1.0, 1.0,0.0), new Vector3(1.0, -1.0, 0.0), new Vector3(-1.0,-1.0,0.0), new Vector3(-1.0, 1.0,0.0)];
      expect(sut.poly_segment(poly, new Vector3(-0.5, -0.5, 0.0), new Vector3(0.5, 0.5, 0.0)), equals(true), reason : "segment inside poly");
      expect(sut.poly_segment(poly, new Vector3(-5.0, -5.0, 0.0), new Vector3(5.0, 5.0, 0.0)), equals(true), reason : "segment cross poly");
      expect(sut.poly_segment(poly, new Vector3(0.0, 0.0, 0.0), new Vector3(5.0, 5.0, 0.0)), equals(true), reason : "segment from inside poly to outside");
      expect(sut.poly_segment(poly, new Vector3(-5.0, 5.0, 0.0), new Vector3(5.0, 8.0, 0.0)), equals(false), reason : "segment larger than poly on axis but no cross poly");
      expect(sut.poly_segment(poly, new Vector3(-0.5, 10.0, 0.0), new Vector3(0.5, 10.0, 0.0)), equals(false), reason : "segment smaller than poly on axis but no cross poly");
      var poly1 = [new Vector3(187.3511199951172,744.4904174804688,0.0), new Vector3(133.2776336669922,744.4904174804688,0.0), new Vector3(133.2776336669922,744.490478515625,0.0), new Vector3(187.3511199951172,744.490478515625,0.0)];
      expect(sut.poly_segment(poly1, new Vector3(47.30211639404297,-93.68658447265625,0.0), new Vector3(47.3272819519043,-93.46804809570312,0.0)), equals(false), reason : "float with very low diff (failed in exp)");
      //[47.30211639404297,-93.68658447265625,0.0], [47.3272819519043,-93.46804809570312,0.0], [98.5,-122.5,0.0], [98.5,-119.5,0.0]] // [[187.3511199951172,744.4904174804688,0.0], [133.2776336669922,744.4904174804688,0.0], [133.2776336669922,744.490478515625,0.0], [187.3511199951172,744.490478515625,0.0]
    });
//    test('test poly_poly', () {
//      var sut = new math2.IntersectionFinderXY();
//      // [[15.0,-121.0,0.0], [15.0,-121.0,0.0], [15.0,-121.0,0.0], [15.0,-121.0,0.0]] [[15.0,-71.00006103515625,0.0], [15.0,-101.00006103515625,0.0], [15.0,-101.00006103515625,0.0], [15.0,-71.00006103515625,0.0]]
//      var poly0 = [ new Vector3(15.0,-121.0,0.0), new Vector3(15.0,-121.0,0.0), new Vector3(15.0,-121.0,0.0), new Vector3(15.0,-121.0,0.0)];
//      var poly1 = [ new Vector3(15.0,-71.00006103515625,0.0), new Vector3(15.0,-101.00006103515625,0.0), new Vector3(15.0,-101.00006103515625,0.0), new Vector3(15.0,-71.00006103515625,0.0)];
//      var b = sut.poly_poly(poly0, poly1);
//      print("$b");
//      expect(b, equals(false));
//    });
  });
}