library progress_controler;

import 'dart:async';
import 'dart:html';
import 'dart:math' as math;
import 'package:asset_pack/asset_pack.dart';

typedef num Ease(double ratio, num change, num base);

/**
 * A [ProgressControler] to bind a [Stream]<[AssetPackTraceEvent]> to an
 * html [ProgressElement.value] or [Element.style.width].
 *
 * The [Stream]<[AssetPackTraceEvent]> can be provide by
 * [AssetPackTrace.asStream()].
 *
 *    var bar = query("#assetProgressTestAssets");
 *    var log = query("#assetLogTestAssets");
 *    var tracer = new AssetPackTrace();
 *    var stream = tracer.asStream().asBroadcastStream();
 *    new ProgressControler(bar).bind(stream);
 *    new EventsPrintControler(log).bind(stream);
 *
 * * Asset doesn't provide estimation of ready so every assets are managed
 *   with same weight (big file == small), a way correct
 *   is to use an custom [ease], or simply to provide an other fealing to user.
 * * The progress can go back when number of download increase,
 *   set [displayBackward] = false, if you don't want do diplay it (progression
 *   always increase).
 * * If every download are completed, next download will reset the progression.
 * * To customise style of [ProgressElement] you can take a look at
 *   [Cross Browser HTML5 Progress Bars In Depth](http://www.useragentman.com/blog/2012/01/03/cross-browser-html5-progress-bars-in-depth/)
 * * [ProgressElement.max] define the precision of the display (eg 100, 1000).
 * * [ProgressControler] modify only the [ProgressElement.value] via a
 *   function of [ProgressElement.max]
 *   OR [Element.style.width] if view parameter (constructor)
 *   is not a [ProgressElement].
 *
 */
class ProgressControler {
  static num linear(double ratio, num change, num baseValue) {
    return change * ratio + baseValue;
  }

  ProgressElement _pview;
  Element _wview;

  /// The function use to display the ratio on the progress bar
  /// default is linear, but other is allowed to display a quick start,...
  final Ease ease;

  /// The progress can go back when ratio decrease (completed/total)
  var displayBackward = true;

  var _total = 0;
  var _current = 0;
  var _ratio = 0.0;

  ProgressControler(Element view, {
    Ease this.ease : linear,
    this.displayBackward : true
  }) {
    if (view is ProgressElement) {
      _pview = view;
    } else {
      _wview = view;
    }
  }

  StreamSubscription bind(Stream<AssetPackTraceEvent> tracer) {
    return tracer.listen(onEvent);
  }

  void _resetCountersIfEqual() {
    if (_total == _current) {
      _total = 0;
      _current = 0;
      _ratio = 0.0;
    }
  }

  void onEvent(AssetPackTraceEvent event) {
    switch(event.type) {
      case AssetPackTraceEvent.PackImportStart:
      case AssetPackTraceEvent.AssetImportStart:
      case AssetPackTraceEvent.AssetLoadStart:
        start(1);
        break;
      case AssetPackTraceEvent.PackImportEnd:
      case AssetPackTraceEvent.AssetLoadEnd:
      case AssetPackTraceEvent.AssetImportEnd:
        end(1);
        break;
    }
  }

  void start([weight = 1]) {
    _resetCountersIfEqual();
    _total += weight;
    _update();
  }

  void end([weight = 1]) {
    _current += weight;
    _update();
  }

  void _update() {
    var n = (_total == 0) ? 0.0 : _current/_total;
    _ratio = (displayBackward) ? n : math.max(_ratio, n);
    if (_pview != null) {
      _pview.value = ease(_ratio, _pview.max, 0).toInt();
    }
    if (_wview != null) {
      _wview.style.width = ease(_ratio, 100, 0).toString() +  "%";
    }
  }
}
