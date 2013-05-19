library colors_test;

import 'package:unittest/unittest.dart';
import 'package:dartemis_addons/colors.dart';
import 'package:vector_math/vector_math.dart';

main() {
  group("colors", () {
    test('irgba_rgbString',(){
      expect(irgba_rgbString(0xff000000), 'rgb(255, 0, 0)');
      expect(irgba_rgbString(0x00ff0000), 'rgb(0, 255, 0)');
      expect(irgba_rgbString(0x0000ff00), 'rgb(0, 0, 255)');
      expect(irgba_rgbString(0xffffffff), 'rgb(255, 255, 255)');
      expect(irgba_rgbString(0x00000000), 'rgb(0, 0, 0)');
      expect(irgba_rgbString(0x000000ff), 'rgb(0, 0, 0)');
    });
    test('irgba_rgbaString',(){
      expect(irgba_rgbaString(0xff000000), 'rgba(255, 0, 0, 0.0)');
      expect(irgba_rgbaString(0x00ff0000), 'rgba(0, 255, 0, 0.0)');
      expect(irgba_rgbaString(0x0000ff00), 'rgba(0, 0, 255, 0.0)');
      expect(irgba_rgbaString(0xffffffff), 'rgba(255, 255, 255, 1.0)');
      expect(irgba_rgbaString(0x00000000), 'rgba(0, 0, 0, 0.0)');
      expect(irgba_rgbaString(0x000000ff), 'rgba(0, 0, 0, 1.0)');
    });
    test('irgba_hexString',(){
      expect(irgba_hexString(0xff000000), 'ff0000');
      expect(irgba_hexString(0x00ff0000), '00ff00');
      expect(irgba_hexString(0x0000ff00), '0000ff');
      expect(irgba_hexString(0xffffff00), 'ffffff');
      expect(irgba_hexString(0x00000000), '000000');
      expect(irgba_hexString(0x000000ff), '000000');
    });
    test('irgba_r255',(){
      expect(irgba_r255(0xff000000), 255);
      expect(irgba_r255(0x00ffffff), 0);
    });
    test('irgba_g255',(){
      expect(irgba_g255(0x00ff0000), 255);
      expect(irgba_g255(0xff00ffff), 0);
    });
    test('irgba_b255',(){
      expect(irgba_b255(0x0000ff00), 255);
      expect(irgba_b255(0xffff00ff), 0);
    });
    test('irgba_a255',(){
      expect(irgba_a255(0x000000ff), 255);
      expect(irgba_a255(0xffffff00), 0);
    });
    test('irgba_a1',(){
      expect(irgba_a1(0x000000ff), 1.0);
      expect(irgba_a1(0xffffff00), 0.0);
    });
  });
}

//equalsVec3(x, y, z) => new AllMatcher([
//  predicate((v0) => v0.x == x, "same x "),
//  predicate((v0) => v0.y == y, "same y "),
//  predicate((v0) => v0.z == z, "same z "),
//]);
//
//equalsVec4(x, y, z, w) => new AllMatcher([
//  predicate((v0) => v0.x == x, "same x "),
//  predicate((v0) => v0.y == y, "same y "),
//  predicate((v0) => v0.z == z, "same z "),
//  predicate((v0) => v0.w == w, "same w "),
//]);
//
//class AllMatcher extends Matcher{
// List<Matcher> ms;
// AllMatcher(this.ms);
//
// Description describe(Description description) =>
//   ms.fold(description, (acc, m)=> m.describe(acc));
//
// Description describeMismatch(item, Description mismatchDescription, MatchState matchState, bool verbose) =>
//   ms.fold(mismatchDescription, (acc, m)=> m.describeMismatch(item, acc, matchState, verbose));
//
// bool matches(item, MatchState matchState) =>
//   ms.fold(true, (acc, m) => m.matches(item, matchState) && acc);
//
//}
