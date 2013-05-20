import 'dart:html';
import 'package:web_ui/web_ui.dart';
import 'package:dartemis_toolbox/ease.dart' as ease;
import 'dart:async';

@observable
var eases = ease.all;

/**
 * Learn about the Web UI package by visiting
 * http://www.dartlang.org/articles/dart-web-components/.
 */
void main() {
  // Enable this to use Shadow DOM in the browser.
  //useShadowDom = true;
  // xtag is null until the end of the event loop (known dart web ui issue)
  new Timer(const Duration(), () {
    var cnt = 0;
    const interval = 1000 ~/ 30;
    const duration = 2000 / interval;
    var values = new List<double>(2);
    new Timer.periodic(const Duration(milliseconds: interval), (timer) {
      var chart = query("#xtchart_demo0").xtag;
      //var v0 = random.nextDouble() * 100.0;
      cnt = (cnt + 1) % duration;
      values[0] = ease.inQuad(cnt/duration, chart.ymax, chart.ymin );
      values[1] = ease.outCubic(cnt/duration, chart.ymax, chart.ymin );
      chart.push(values);
    });
  });
}
