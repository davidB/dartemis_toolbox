import 'dart:html';
import 'package:web_ui/web_ui.dart';

class XFchart extends WebComponent{
  Function fct;

  printChart() {
    var c = this.query('canvas') as CanvasElement;
    var g = c.context2d;
    var ymargin = c.height * 0.25;
    var x0 = 0.5;
    var y0 = 0.5 + ymargin;
    var w0 = c.width - 1;
    var h0 = c.height - 1 - 2 * ymargin;


    g.rect(x0, y0, w0, h0);
    g.lineWidth = 1.0;
    g.strokeStyle = 'rgb(100,100,100)';
    g.stroke();
    g.fillStyle = 'rgb(240, 240, 240)';
    //g.fillStyle = 0xFFDFDFDF;
    g.fill();

    g.beginPath();
    g.moveTo(x0, y0 + h0);
    if (fct != null && fct is Function) {
      for(int i = 0; i <= w0; i++) {
        var ratio = i / w0;
        var x = 0.5 + ratio * w0;
        var y = fct(ratio, -h0, y0 + h0);
        g.lineTo(x, y);
      }
    }

    g.lineWidth = 3.0;
    g.strokeStyle = 'rgb(255,100,100)';
    g.stroke();
  }

  void inserted() {
    printChart();
  }
}
