library colors_test;

import 'package:unittest/unittest.dart';
import 'package:dartemis_addons/colors.dart';
import 'package:vector_math/vector_math.dart';

main() {
  group("colors", () {
//    test('conversion of red', () {
//      var t = tinycolor("red");
//      expect(t.toHex(), "f00");
//      expect(t.toHexString(), "#f00");
//      expect(t.toRgb(), new vec3(255, 0, 0));
//      expect(t.toRgbString(), "rgb(255, 0, 0)");
//      expect(t.toHsv(), new vec3(0, 1, 1));
//      expect(t.toHsvString(), "hsv(0, 100%, 100%)");
//      expect(t.toHsl(), new vec3(0, 1, 0.5));
//      expect(t.toHslString(), "hsl(0, 100%, 50%)");
//      expect(t.toName(), "red");
//    });
    test('irgba2rgb',(){
      expect(irgba2rgb(0xffffff00), equalsVec3(255.0, 255.0, 255.0));
      expect(irgba2rgb(0xffffffff), equalsVec3(255.0, 255.0, 255.0));
      expect(irgba2rgb(0x00000000), equalsVec3(0.0, 0.0, 0.0));
      expect(irgba2rgb(0x000000ff), equalsVec3(0.0, 0.0, 0.0));
    });
    test('irgba2rgba',(){
      expect(irgba2rgba(0xffffff00), equalsVec4(255.0, 255.0, 255.0, 0.0));
      expect(irgba2rgba(0xffffffff), equalsVec4(255.0, 255.0, 255.0, 255.0));
      expect(irgba2rgba(0x00000000), equalsVec4(0.0, 0.0, 0.0, 0.0));
      expect(irgba2rgba(0x000000ff), equalsVec4(0.0, 0.0, 0.0, 255.0));
    });
  });
}

equalsVec3(x, y, z) => new AllMatcher([
  predicate((v0) => v0.x == x, "same x "),
  predicate((v0) => v0.y == y, "same y "),
  predicate((v0) => v0.z == z, "same z "),
]);

equalsVec4(x, y, z, w) => new AllMatcher([
  predicate((v0) => v0.x == x, "same x "),
  predicate((v0) => v0.y == y, "same y "),
  predicate((v0) => v0.z == z, "same z "),
  predicate((v0) => v0.w == w, "same w "),
]);

class AllMatcher extends Matcher{
 List<Matcher> ms;
 AllMatcher(this.ms);

 Description describe(Description description) =>
   ms.fold(description, (acc, m)=> m.describe(acc));

 Description describeMismatch(item, Description mismatchDescription, MatchState matchState, bool verbose) =>
   ms.fold(mismatchDescription, (acc, m)=> m.describeMismatch(item, acc, matchState, verbose));

 bool matches(item, MatchState matchState) =>
   ms.fold(true, (acc, m) => m.matches(item, matchState) && acc);

}
