import 'dart:html';
import 'dart:math' as math;
import 'package:web_ui/web_ui.dart';
import 'package:dartemis_toolbox/colors.dart';

/// the main goal of the component is to show feature of colors .
class XColorselector extends WebComponent{

  int _color = 0xaaaaaaff;

  @observable
  get color => _color;
  @observable
  set color(v){
    _color = v;
    refresh();
  }

  @observable
  get hex_html => irgba_hexHtml(color);
  @observable
  set hex_html(s){
    color = hexHtml_irgba(s);
  }

  @observable
  get hex_irgba => irgba_hexString(color);
  @observable
  set hex_irgba(s){
    color = hexString_irgba(s);
  }

  @observable
  get rStr => irgba_r255(color).toString();
  @observable
  set rStr(s) {
    if (s == null || s.length < 1) s = "0";
    color = irgba_r255_set(color, int.parse(s, radix : 10));
  }

  @observable
  get gStr => irgba_g255(color).toString();
  @observable
  set gStr(s) {
    if (s == null || s.length < 1) s = "0";
    color = irgba_g255_set(color, int.parse(s, radix : 10));
  }

  @observable
  get bStr => irgba_b255(color).toString();
  @observable
  set bStr(s) {
    if (s == null || s.length < 1) s = "0";
    color = irgba_b255_set(color, int.parse(s, radix : 10));
  }

  @observable
  get hStr => (irgba_hsv(color)[0] * 360).toInt().toString();
  @observable
  set hStr(s) {
    if (s == null || s.length < 1) s = "0";
    var hsv = irgba_hsv(color);
    hsv[0] = int.parse(s, radix : 10) / 360.0;
    color = hsv_irgba(hsv);
  }

  @observable
  get sStr => (irgba_hsv(color)[1] * 100).toInt().toString();
  @observable
  set sStr(s) {
    if (s == null || s.length < 1) s = "0";
    var hsv = irgba_hsv(color);
    hsv[1] = int.parse(s, radix : 10) / 100.0;
    color = hsv_irgba(hsv);
  }

  @observable
  get vStr => (irgba_hsv(color)[2] * 100).toInt().toString();
  @observable
  set vStr(s) {
    if (s == null || s.length < 1) s = "0";
    var hsv = irgba_hsv(color);
    hsv[2] = int.parse(s, radix : 10) / 100.0;
    color = hsv_irgba(hsv);
  }

  @observable
  get triad => hsl_triad(irgba_hsl(color)).map(hsl_irgba);

  @observable
  get tetrad => hsl_tetrad(irgba_hsl(color)).map(hsl_irgba);

  @observable
  get splitcomplement => hsl_splitcomplement(irgba_hsl(color)).map(hsl_irgba);

  @observable
  get analogous => hsl_analogous(irgba_hsl(color)).map(hsl_irgba);

  @observable
  get monochromatic => hsv_monochromatic(irgba_hsv(color)).map(hsv_irgba);

//  irgba_hex(List<double> hsl) => irgba_hexString(hsl_irgba(hsl));
//  irgba_html() => irgba_hexHtml(irgba(hsl));

  complement() {
    color = hsl_irgba(hsl_complement(irgba_hsl(color)));
  }

  saturate() {
    color = hsl_irgba(hsl_saturate(irgba_hsl(color)));
  }

  desaturate() {
    color = hsl_irgba(hsl_desaturate(irgba_hsl(color)));
  }

  greyscale() {
    color = hsl_irgba(hsl_greyscale(irgba_hsl(color)));
  }

  lighten() {
    color = hsl_irgba(hsl_lighten(irgba_hsl(color)));
  }

  darken() {
    color = hsl_irgba(hsl_darken(irgba_hsl(color)));
  }

  random() {
    color = random_irgba();
  }
  /// An common optimisation is to use a color + bacground image with alpha
  /// like done by yui-color-picker [sample](http://www.colorspire.com/s/j/yui282/asset/picker_mask.png)
  draw_sv() {
    var c = this.query('canvas.cs_sv') as CanvasElement;
    var g = c.context2d;
    var sel = 2;
    var w1 = (c.width - 2 * sel)/ 100.0;
    var h1 = (c.height - 2 * sel)/ 100.0;
    var hsv = irgba_hsv(color);
    g.clearRect(0,0, c.width, c.height);
    for(var s0 = 0; s0 < 101; ++s0) {
      for(var v0 = 0; v0 < 101; ++v0) {
        g.fillStyle = irgba_hexHtml(hsv_irgba([hsv[0], s0/100, v0/100]));
        g.fillRect((100 - s0) * w1 + sel, (100 - v0) * h1 + sel, w1, h1);
      }
    }
    g.beginPath();
    g.arc((100 - hsv[1] * 100) * w1 + sel, (100 - hsv[2] * 100) * h1 + sel, sel + math.max(h1, w1), 0, 2 * math.PI);
    g.closePath();
    g.strokeStyle = '#000000';
    g.stroke();
  }

  /// An common optimisation is to use a image for the hue bar
  draw_h() {
    var c = this.query('canvas.cs_h') as CanvasElement;
    var g = c.context2d;
    var sel = 2;
    var w1 = c.width - (2 * sel);
    var h1 = (c.height - (2 * sel))/ 100.0;
    var h0 = irgba_hsv(color)[0];
    g.clearRect(0,0, c.width, c.height);
    for(var y = 0; y < 101; ++y) {
      var s = irgba_hexHtml(hsv_irgba([y/100.0, 1.0, 1.0]));
      //var s = 'rgb(${(y*255/100).toInt()}, 0, 0)';
      g.fillStyle = s;
      g.fillRect(sel, (y * h1) + sel, w1, h1);
    }
    g.strokeStyle = '#000000';
    g.strokeRect(0, (h0 * 100 * h1) + sel, w1 + 2 * sel, h1 + 2 * sel);
  }

  void inserted() {
    color = random_irgba();
    refresh();
  }

  void refresh() {
    draw_sv();
    draw_h();
  }
}
