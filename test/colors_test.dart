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
    test('irgb2vrgb',(){
      expect(irgb2rgb(0xffffff), equalsVec3(255.0, 255.0, 255.0));
      expect(irgb2rgb(0x000000), equalsVec3(0.0, 0.0, 0.0));
    });
  });
}

equalsVec3(x, y, z) => new AllMatcher([
  predicate((v0) => v0.x == x, "same x"),
  predicate((v0) => v0.y == y, "same y"),
  predicate((v0) => v0.z == z, "same z"),
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
