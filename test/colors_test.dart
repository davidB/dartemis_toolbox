library colors_test;

import 'package:unittest/unittest.dart';
import 'package:dartemis_toolbox/colors.dart';

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
    test('irgba_hex3String',(){
      expect(irgba_hex3String(0xff000000), 'ff0000');
      expect(irgba_hex3String(0x00ff0000), '00ff00');
      expect(irgba_hex3String(0x0000ff00), '0000ff');
      expect(irgba_hex3String(0xffffff00), 'ffffff');
      expect(irgba_hex3String(0x00000000), '000000');
      expect(irgba_hex3String(0x000000ff), '000000');
    });
    test('irgba_hexString',(){
      expect(irgba_hexString(0xff000000), '0xff000000');
      expect(irgba_hexString(0x00ff0000), '0x00ff0000');
      expect(irgba_hexString(0x0000ff00), '0x0000ff00');
      expect(irgba_hexString(0xffffff00), '0xffffff00');
      expect(irgba_hexString(0x00000000), '0x00000000');
      expect(irgba_hexString(0x000000ff), '0x000000ff');
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
    test('irgba_rgb always in range',(){
      for(var i = 0x000000; i < 0x1000000; ++i) {
        var c = (i << 8 | 0xff);
        var rgb = irgba_rgb(c);
        expect(rgb[0], inInclusiveRange(0.0, 1.0));//, '0.0 <= r <= 1.0');
        expect(rgb[1], inInclusiveRange(0.0, 1.0));//, '0.0 <= g <= 1.0');
        expect(rgb[2], inInclusiveRange(0.0, 1.0));//, '0.0 <= b <= 1.0');
      }
    });
    test('irgba_rgb symetric with rgb_irgba',(){
      for(var i = 0x000000; i < 0x1000000; ++i) {
        var c = (i << 8 | 0xff);
        var rgb = irgba_rgb(c);
        expect(rgb_irgba(rgb), c);
      }
    });
    test('irgba_hsl always in range',(){
      for(var i = 0x000000; i < 0x1000000; ++i) {
        var c = (i << 8 | 0xff);
        var hsl = irgba_hsl(c);
        expect(hsl[0], inInclusiveRange(0.0, 1.0));//, '0.0 <= h <= 1.0');
        expect(hsl[1], inInclusiveRange(0.0, 1.0));//, '0.0 <= s <= 1.0');
        expect(hsl[2], inInclusiveRange(0.0, 1.0));//, '0.0 <= l <= 1.0');
      }
    });
//    test('irgba_hsl symetric with hsl_irgba',(){
//      for(var i = 0x000000; i < 0x1000000; ++i) {
//        var c = (i << 8 | 0xff);
//        var hsl = irgba_hsl(c);
//        expect(hsl_irgba(hsl), c);
//      }
//    });
    test('irgba_hsv always in range',(){
      for(var i = 0x000000; i < 0x1000000; ++i) {
        var c = (i << 8 | 0xff);
        var hsv = irgba_hsv(c);
        expect(hsv[0], inInclusiveRange(0.0, 1.0));//, '0.0 <= h <= 1.0');
        expect(hsv[1], inInclusiveRange(0.0, 1.0));//, '0.0 <= s <= 1.0');
        expect(hsv[2], inInclusiveRange(0.0, 1.0));//, '0.0 <= v <= 1.0');
      }
    });
//    test('irgba_hsv symetric with hsv_irgba',(){
//      for(var i = 0x000000; i < 0x1000000; ++i) {
//        var c = (i << 8 | 0xff);
//        var hsv = irgba_hsv(c);
//        expect(hsv_irgba(hsv), c);
//      }
//    });
  });
}

