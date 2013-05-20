library ease_test;

import 'package:unittest/unittest.dart';
import 'package:dartemis_toolbox/ease.dart' as ease;

main() {
  group("ease start at baseValue end at baseValue + change", () {
    for(var b in [-10, -1, 0, 1, 10]) {
      for (var c in [-10, -1, 0, 1, 10]) {
        ease.all.forEach((k,v) {
          test('test ${k} with base ${b} change ${c} for ratio 0.0', () {
            expect(v(0.0, c, b), closeTo(b, 0.01));
          });
          test('test ${k} with base ${b} change ${c} for ratio 1.0', () {
            expect(v(1.0, c, b), closeTo(b + c, 0.01));
          });
        });
      }
    }
  });
}
