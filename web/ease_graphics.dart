import 'dart:html';
import 'package:web_ui/web_ui.dart';
import 'package:dartemis_toolbox/ease.dart' as ease;
import 'package:html_toolbox/html_toolbox.dart';
import 'package:html_toolbox/widgets_charts.dart';

@observable
var eases = ease.all;

/**
 * Learn about the Web UI package by visiting
 * http://www.dartlang.org/articles/dart-web-components/.
 */
void main() {
  // Enable this to use Shadow DOM in the browser.
  //useShadowDom = true;
  var tmpl = new MicroTemplate(querySelector(".ease"));
  var items = eases.keys.map((k) => {
    "k" : k
  }).toList();
  var validator = new NodeValidatorBuilder.common()
  ..allowHtml5()
  ..allowElement('canvas', attributes : ['data-ease'])
  ;
  tmpl.apply(items, validator: validator);

  querySelectorAll("canvas[data-ease]").forEach((Element el){
    var fname = el.dataset["ease"];
    var f = fname.startsWith("goback.") ? ease.goback(eases[fname.substring("goback.".length)]) : eases[fname];
    new ChartF()
    ..el = el
    ..fct = f
    ..update();
  });

}
