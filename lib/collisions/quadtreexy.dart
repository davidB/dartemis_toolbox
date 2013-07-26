// License [CC0](http://creativecommons.org/publicdomain/zero/1.0/)

part of collisions;

////// see
////// * [Quadtree](http://en.wikipedia.org/wiki/Quadtree) at wikipedia
////// * [JavaScript QuadTree Implementation](http://www.mikechambers.com/blog/2011/03/21/javascript-quadtree-implementation/)
////// * [Quick Tip: Use Quadtrees to Detect Likely Collisions in 2D Space](http://gamedev.tutsplus.com/tutorials/implementation/quick-tip-use-quadtrees-to-detect-likely-collisions-in-2d-space/)
//class QuadTreeXY{
//  /// (x, y, width, height) bounds of the QuadTree
//  final double x, y, w, h;
//
//  /// Whether the QuadTree will contain points (true), or items with bounds (width / height)(false).
//  final int maxDepth;
//  /// The maximum number of children that a node can contain before it is split into sub-nodes.
//  final int maxChildren;
//
//  final _children = new List<Vector3>();
//  //TODO optimize to reuse nodes (recycle, pool)
//  final _nodes = new List<QuadTreeXY>(4);
//  var _isLeaf = true;
//  Vector2 _splitPoint;
//
//  QuadTreeXY(this.x, this.y, this.w, this.h, [this.maxDepth = 4, this.maxChildren = 4]) {
//    _splitPoint = new Vector2(w / 2, h / 2);
//  }
//
//  /// use [reset] to reset the instance isntead of create a new one with same bounds.
//  reset() {
//    _children.clear();
//    _nodes.forEach((i){if (i != null) i.reset() ;});
//    _isLeaf = true;
//  }
//
//  bool insert(Vector3 v) {
//    var r = _findRegion(v);
//    if (r != null) {
//      r._insert(v);
//    }
//    return (r != null);
//  }
//
//  QuadTreeXY findRegion(Vector3 v) {
//    if (v.x < x || v.x > (x + w) || (v.y < y) || v.y > (y + w)) {
//      return null;
//    }
//    return _findRegion(v);
//  }
//
//  _insert(Vector3 v) {
//    _children.add(v);
//    if (_isLeaf && _children.length > maxChildren && maxDepth > 0) {
//      _split();
//      _children.forEach((v) => insert(v));
//      _children.clear();
//    }
//  }
//
//  _split() {
//    if(_nodes[0] == null) {
//      _nodes[0] = new QuadTreeXY(x                , y                , _splitPoint.x    , _splitPoint.y    , maxDepth - 1, maxChildren);
//      _nodes[1] = new QuadTreeXY(x + _splitPoint.x, y                , w - _splitPoint.x, _splitPoint.y    , maxDepth - 1, maxChildren);
//      _nodes[2] = new QuadTreeXY(x                , y + _splitPoint.y, _splitPoint.x    , h - _splitPoint.y, maxDepth - 1, maxChildren);
//      _nodes[3] = new QuadTreeXY(x + _splitPoint.x, y + _splitPoint.y, w - _splitPoint.x, h - _splitPoint.y, maxDepth - 1, maxChildren);
//    }
//    _isLeaf = false;
//  }
//
//  _findRegion(Vector3 v) {
//    if (_isLeaf) return this;
//    var x0 = v.x - x;
//    var y0 = v.y - y;
//    var b = (x0 <= _splitPoint.x) ?
//        ((y0 <= _splitPoint.y) ? _nodes[0] : _nodes[2])
//        :((y0 <= _splitPoint.y) ? _nodes[1] : _nodes[3])
//        ;
//    return b._findRegion(v);
//  }
//}

/// see
/// * [Quadtree](http://en.wikipedia.org/wiki/Quadtree) at wikipedia
/// * [JavaScript QuadTree Implementation](http://www.mikechambers.com/blog/2011/03/21/javascript-quadtree-implementation/)
/// * [Quick Tip: Use Quadtrees to Detect Likely Collisions in 2D Space](http://gamedev.tutsplus.com/tutorials/implementation/quick-tip-use-quadtrees-to-detect-likely-collisions-in-2d-space/)
/// TODO add testcase
class QuadTreeXYAabb{
  /// (x, y, width, height) bounds of the QuadTree
  final _dim = new Aabb3();
  final _splitPoint = new Vector3.zero();

  /// Whether the QuadTree will contain points (true), or items with bounds (width / height)(false).
  final int maxDepth;
  /// The maximum number of children that a node can contain before it is split into sub-nodes.
  final int maxChildren;

  //interleave data [AAbb3, obj, AAbb3, obj, ....]
  final _children = new List();
  //TODO optimize to reuse nodes (recycle, pool)
  final _nodes = new List<QuadTreeXYAabb>(4);
  var _isLeaf = true;

  QuadTreeXYAabb(x, y, w, h, [this.maxDepth = 4, int maxChildren = 4]): this.maxChildren = maxChildren << 1 {
    _dim.min.setValues(x, y, 0.0);
    _dim.max.setValues(x + w, y + h, 0.0);
    _splitPoint.setFrom(_dim.min).add(_dim.max).scale(0.5);
  }

  get isLeaf => _isLeaf;
  get nbItems => (_children.length >> 1) + ((_isLeaf)? 0 : (_nodes[0].nbItems + _nodes[1].nbItems + _nodes[2].nbItems + _nodes[3].nbItems));
  get nbItemsL0 => _children.length >> 1;

  /// use [reset] to reset the instance instead of create a new one with same bounds.
  reset() {
    _children.clear();
    _isLeaf = true;
  }

  bool insert(Aabb3 v, obj) {
    var r = findRegion(v);
    if (r != null) {
      r._insert(v, obj);
//      if (this.maxDepth == 10) {
//        obj.ps.color[obj.i] = (r.maxDepth == 10)? 0x0000ffff : 0x00ff00ff;
//      }
    }
    return (r != null);
  }

  QuadTreeXYAabb findRegion(Aabb3 v) {
    if (v.min.x < _dim.min.x || v.max.x > _dim.max.x || (v.min.y < _dim.min.y) || v.max.y > _dim.max.y) {
      return null;
    }
    return _findRegion(v);
  }

  _findRegion(Aabb3 v) {
    var r = null;
    if (!_isLeaf) {
      var n = (v.min.y <= _splitPoint.y)?  0 : 2;
      n = (v.min.x <= _splitPoint.x)?  n : n + 1;
      r = _nodes[n].findRegion(v);
    }
    return (r == null) ? this : r;
  }

  _insert(Aabb3 v, obj) {
    if (_isLeaf && maxDepth > 0 && _children.length >= maxChildren) {
      _split();
      var data = new List.from(_children, growable: false); // TODO use a static arrays
      _children.clear();
      for (var i = 0; i < data.length; i +=2) {
        insert(data[i], data[i+1]);
      }
      insert(v, obj);
    } else {
      _children.add(v);
      _children.add(obj);
    }
  }

  _split() {
    if(_nodes[0] == null) {
      var x = _dim.min.x;
      var y = _dim.min.y;
      var w2 = _splitPoint.x - _dim.min.x;
      var h2 = _splitPoint.y - _dim.min.y;
      var m = maxChildren >> 1;
      var d = maxDepth - 1;
      _nodes[0] = new QuadTreeXYAabb(x     , y     , w2, h2, d, m);
      _nodes[1] = new QuadTreeXYAabb(x + w2, y     , w2, h2, d, m);
      _nodes[2] = new QuadTreeXYAabb(x     , y + h2, w2, h2, d, m);
      _nodes[3] = new QuadTreeXYAabb(x + w2, y + h2, w2, h2, d, m);
    } else {
      _nodes[0].reset();
      _nodes[1].reset();
      _nodes[2].reset();
      _nodes[3].reset();
    }
    _isLeaf = false;
  }

  retrieve(Aabb3 v, List out) {
    var reg = findRegion(v);
    if (reg !=null && reg != this) {
      reg.retrieve(out, v);
    }
    for (var i = 1; i < _children.length; i +=2) {
      out.add(_children[i]);
    }
    return out;
  }

  scan(Function f) {
    for (var i = 1; i < _children.length; i +=2) {
      var a1 = _children[i];
      for (var j = i + 2; j < _children.length; j +=2) {
        f(a1, _children[j]);
      }
      _scanVsNodes(f, a1);
    }
    if (!_isLeaf) {
      for (var i = 0; i < 4; ++i) {
        _nodes[i].scan(f);
      }
    }
  }

  _scanVsNodes(Function f, a1) {
    if (_isLeaf) return;

    for (var i = 0; i < 4; ++i) {
      var n = _nodes[i];
      n._scanVsChildren(f, a1);
      n._scanVsNodes(f, a1);
    }
  }

  _scanVsChildren(Function f, a1) {
    for (var i = 1; i < _children.length; i +=2) {
      f(a1, _children[i]);
    }
  }

}

newDrawCanvas_QuadTreeXYAabb(QuadTreeXYAabb v, lineStyle, textStyle) => (g, Entity e, Vector2 area){
  g.beginPath();
  _debug_drawAxis(v, g);
  g.strokeStyle = lineStyle;
  g.stroke();
  g.fillStyle = textStyle;
  //g.textAlign =
  _debug_drawCount(v, g);
};

_debug_drawAxis(QuadTreeXYAabb v, g) {
  if(!v._isLeaf) {
    g.moveTo(v._dim.min.x, v._splitPoint.y);
    g.lineTo(v._dim.max.x, v._splitPoint.y);
    g.moveTo(v._splitPoint.x, v._dim.min.y);
    g.lineTo(v._splitPoint.x, v._dim.max.y);
    for (var i = 0; i < 4; ++i) {
      _debug_drawAxis(v._nodes[i], g);
    }
  }
}

_debug_drawCount(QuadTreeXYAabb v, g) {
  g.fillText("${v.nbItems }/${v.nbItemsL0 }/${v.maxChildren >> 1}[${v.maxDepth}]", v._splitPoint.x, v._splitPoint.y);
  if(!v._isLeaf) {
    for (var i = 0; i < 4; ++i) {
      _debug_drawCount(v._nodes[i], g);
    }
  }
}