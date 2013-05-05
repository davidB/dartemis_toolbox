import 'dart:html';
import 'package:web_ui/web_ui.dart';

class XFgraph extends WebComponent{
  String fname = "noname";
  Function fapply;

  printGraph() {
    var g = (_canvas as CanvasElement).context2d;
    g.beginPath();
    g.moveTo(0.5, 30.5);
    g.lineTo(199.5, 30.5);
    g.lineTo(199.5, 109.5);
    g.lineTo(0.5, 109.5);
    g.closePath();

    g.strokeStyle = 0xFF000000;
    g.stroke();
    //g.fillColor(0xFFDFDFDF);

    g.beginPath();
    g.moveTo(0.5, 109.5);
    if (fapply != null && fapply is Function) {
      for(int i = 0; i <= 199; i++) {
        var ratio = i / 199.0;
        var x = 0.5 + ratio * 199.0;
        var y = fapply(ratio, -79.0, 109.5);
        g.lineTo(x, y);
      }
    }

    g.strokeStyle = 0xFF0000FF;
    g.stroke();
  }

  @protected
  void created() {
  }

  @protected
  void inserted() {
    printGraph();
  }

  get _canvas => this.query('canvas') as CanvasElement;

}
