// This is free and unencumbered software released into the public domain.
//
// Anyone is free to copy, modify, publish, use, compile, sell, or
// distribute this software, either in source code form or as a compiled
// binary, for any purpose, commercial or non-commercial, and by any
// means.
//
// In jurisdictions that recognize copyright laws, the author or authors
// of this software dedicate any and all copyright interest in the
// software to the public domain. We make this dedication for the benefit
// of the public at large and to the detriment of our heirs and
// successors. We intend this dedication to be an overt act of
// relinquishment in perpetuity of all present and future rights to this
// software under copyright law.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
// IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
// OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
// ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
// OTHER DEALINGS IN THE SOFTWARE.
//
// For more information, please refer to <http://unlicense.org/>

/// Use to debug or to prototype display in canvas
/// use it with prefix
///
///    import 'package:dartemis_addons/system_proto2d.dart' as proto;
///
/// It's an unoptimize library (ex : failed 100% of the advices at
/// [Optimizing canvas - MDN](https://developer.mozilla.org/en-US/docs/HTML/Canvas/Tutorial/Optimizing_canvas)
///
/// the library include primitive DrawCanvas function (pseudo "function curring")

library system_proto2d;

import 'package:dartemis/dartemis.dart';
import 'dart:html';
import 'dart:math' as math;
import 'package:dartemis_addons/transform.dart';
import 'package:dartemis_addons/system_particles.dart';
import 'package:vector_math/vector_math.dart';

typedef void DrawCanvas(CanvasRenderingContext2D g, Entity e, vec2 area);

class Drawable extends Component {
  DrawCanvas draw = null;

  Drawable(this.draw);
}

class System_Renderer extends EntityProcessingSystem {
  final CanvasRenderingContext2D _gVisible;
  final CanvasRenderingContext2D _g;
  ComponentMapper<Transform> _transformMapper;
  ComponentMapper<Drawable> _drawMapper;
  var _w = 0;
  var _h = 0;
  /// [_areaEntity] temp variable use fill by [Drawable.draw] to give the modified
  /// area, it is an area with center at (0.0, 0.0)
  vec2 _areaEntity = new vec2(0.0, 0.0);
  /// _areaEntities sum of the _areaEntity in original state.
  /// TODO optim : use _areaEntity and _areaEntities to clear and to update offscreen canvas
  //vec4 _areaEntities = new vec4(0.0, 0.0);


  System_Renderer(canvas) :
    super(Aspect.getAspectForAllOf([Drawable])),
    _gVisible = canvas.context2d,
    _g = new CanvasElement().context2d
    ;

  void initialize(){
    _drawMapper = new ComponentMapper<Drawable>(Drawable, world);
    _transformMapper = new ComponentMapper<Transform>(Transform, world);
    _initCanvasDimension();
  }

  void _initCanvasDimension() {
    // to avoid scale and blur
    // canvas dimensions
    var canvasV = _gVisible.canvas;
    var dpr = window.devicePixelRatio;     // retina
    _w = (dpr * canvasV.clientWidth).round();//parseInt(canvas.style.width);
    _h = (dpr * canvasV.clientHeight).round(); //parseInt(canvas.style.height);

    canvasV.width = _w;
    canvasV.height = _h;
    _gVisible.scale(dpr, dpr);
    _g.canvas.width = _w;
    _g.canvas.height = _h;
    _g.scale(dpr, dpr);
  }

  void begin() {
    //TODO use a viewport (translation, rotation, scale);
    _g.save();
  }

  void processEntity(Entity entity) {
    var d = _drawMapper.get(entity);
    var tf = _transformMapper.getSafe(entity);
    if (tf != null) {
      _g.translate(tf.position3d.x.toInt(), tf.position3d.y.toInt());
      _g.rotate(tf.rotation3d.z);
      _g.scale(tf.scale3d.x, tf.scale3d.y);
    }
    _areaEntity.x = 0.0;
    _areaEntity.y = 0.0;
    d.draw(_g, entity, _areaEntity);
    if (tf != null) {
      _g.translate(-tf.position3d.x.toInt(), -tf.position3d.y.toInt());
      _g.rotate(-tf.rotation3d.z);
      _g.scale(1/tf.scale3d.x, 1/tf.scale3d.y);
    }
    _g.restore();
  }

  void end() {
    _g.restore();
    _gVisible.clearRect(0,0, _w, _h);
    _gVisible.drawImage(_g.canvas, 0, 0);
    _g.clearRect(0,0, _w, _h);
  }
}

DrawCanvas rect(w, h, {fillStyle, strokeStyle, strokeLineWidth : 1, strokeLineDashOffset : 0}) => (CanvasRenderingContext2D g, Entity e, area) {
  if (strokeStyle == null && fillStyle == null) return;
  var rx = - w/2;
  var ry = - h/2;
  if (fillStyle != null) {
    g.fillStyle = fillStyle;
    g.fillRect(rx, ry, w, h);
  }
  if (strokeStyle != null) {
    g.strokeStyle = strokeStyle;
    g.lineWidth = strokeLineWidth;
    g.lineDashOffset = strokeLineDashOffset;
    g.strokeRect(rx, ry, w, h, strokeLineWidth);
  }
  area.x = w.toDouble();
  area.y = h.toDouble();
};

DrawCanvas dot4({fillStyle}) => (CanvasRenderingContext2D g, Entity e, area) {
  if (fillStyle != null) {
    g.fillStyle = fillStyle;
    g.fillRect(-2, -2, 4, 4);
    area.x = 4.0;
    area.y = 4.0;
  }
};

DrawCanvas disc(num radius, {fillStyle, strokeStyle, strokeLineWidth : 1, strokeLineDashOffset : 0})  => (CanvasRenderingContext2D g, Entity e, area) {
  if (strokeStyle == null && fillStyle == null) return;
  g.beginPath();
  g.arc(0, 0, radius,0, math.PI*2,true);
  g.closePath();
  if (fillStyle != null) {
    g.fillStyle = fillStyle;
    g.fill();
  }
  if (strokeStyle != null) {
    g.strokeStyle = strokeStyle;
    g.lineWidth = strokeLineWidth;
    g.lineDashOffset = strokeLineDashOffset;
    g.stroke();
  }
  area.x = radius.toDouble();
  area.y = radius.toDouble();
};

DrawCanvas text(String txt, {fillStyle, strokeStyle, strokeLineWidth : 1, strokeLineDashOffset : 0, textAlign : null})  => (CanvasRenderingContext2D g, Entity e,area) {
  if (strokeStyle == null && fillStyle == null) return;
  //if (textAlign != null) g.textAlign = textAlign;
  if (fillStyle != null) {
    g.fillStyle = fillStyle;
    g.fillText(txt, 0, 0);
  }
  if (strokeStyle != null) {
    g.strokeStyle = strokeStyle;
    g.lineWidth = strokeLineWidth;
    g.lineDashOffset = strokeLineDashOffset;
    g.strokeText(txt, 0, 0);
  }
  //TODO var m = g.measureText(txt);
  //TODO area.x = m.width;
  //TODO area.y = m.h;
};

DrawCanvas particles(num radius, {fillStyle, strokeStyle, strokeLineWidth : 1, strokeLineDashOffset : 0}){
  return (CanvasRenderingContext2D g, Entity entity, area) {
    var particles = entity.getComponent(Particles.CT) as Particles;
    if (particles == null || particles.l.isEmpty) return;
    if (strokeStyle == null && fillStyle == null) return;
    //print("emitter.particles : ${emitter.particles.length}");
    g.beginPath();
    particles.l.forEach((p) {
      var pos = p.position3d;
      if (pos != null) {
        //g.moveTo(pos.x, pos.y);
        //print('${pos.x} // ${pos.y}');
        g.arc(pos.x, pos.y, radius, 0, math.PI*2,true);
      }
    });
    g.closePath();
    if (fillStyle != null) {
      g.fillStyle = fillStyle;
      g.fill();
    }
    if (strokeStyle != null) {
      g.strokeStyle = strokeStyle;
      g.lineWidth = strokeLineWidth;
      g.lineDashOffset = strokeLineDashOffset;
      g.stroke();
    }
    //TODO define the area
//    area.x = radius.toDouble();
//    area.y = radius.toDouble();
  };
}