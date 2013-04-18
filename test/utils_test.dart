library utils_test;

import 'package:unittest/unittest.dart';
import 'package:dartemis_addons/utils.dart';

main() {
  test("LinkedBag", () {
    var d = new LinkedBag();
    d.add(1);
    d.add(2);
    d.add(3);
    d.add(1);
    expect(d.length, equals(4));

    //var lbefore = 0;
    //var lafter = 0;

    d.iterateAndUpdate((v) => (v != 2)? v : null);
    //expect(lafter, equals(lbefore - 1), reason : "${lbefore} - ${ndeleted} != ${lafter}");
    expect(d.length, equals(3));

    d.iterateAndUpdate((v) => (v != 1)? v : null);
    //expect(lafter, equals(lbefore - 2), reason : "${lbefore} - ${ndeleted} != ${lafter}");
    expect(d.length, equals(1));

    d.iterateAndUpdate((v) => (v != 1)? v : null);
    //expect(lafter, equals(lbefore - 0), reason : "${lbefore} - ${ndeleted} != ${lafter}");
    expect(d.length, equals(1));

    d.add(3);
    d.add(1);
    d.add(1);
    expect(d.length, equals(4));

    d.iterateAndUpdate((v) => (v != 3)? v : null);
    //expect(lafter, equals(lbefore - 2), reason : "${lbefore} - ${ndeleted} != ${lafter}");
    expect(d.length, equals(2));

    d.iterateAndUpdate((v) => (v != 1)? v : null);
    //expect(lafter, equals(lbefore - 2), reason : "${lbefore} - ${ndeleted} != ${lafter}");
    expect(d.length, equals(0));
  });
}


