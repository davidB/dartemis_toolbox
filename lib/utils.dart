// License [CC0](http://creativecommons.org/publicdomain/zero/1.0/)

library utils;

class LinkedBag<E> {
  LinkedEntry _head = new LinkedEntry();

  get length {
    int i = 0;
    for(var a = _head; a != null; a = a._next) {
      if (a._obj != null) i++;
    }
    return i;
  }

  void clear() {
    for(var a = _head; a != null; a = a._next) {
      a._obj = null;
    }
  }

  void add(E obj) {
    var a = _head;
    while(a != null) {
      if (a._obj == null) {
        a._obj = obj;
        return;
      }
      if (a._next == null) {
        var e = new LinkedEntry();
        e._obj = obj;
        a._next = e;
        return;
      }
      a = a._next;
    }
  }

  /**
   * Iterate over the entries (!= null) in the bag.
   * [f] update the entry in the bag (return null => free the entry)
   * The function can be used to loop (forEach) over entry if [f] return
   * its parameter.
   */
  void iterateAndUpdate(E f(E)) {
    int i = 0;
    for(var current = _head; current != null; current = current._next) {
      if (current._obj != null) {
        current._obj = f(current._obj);
      }
    }
  }
}

class LinkedEntry {
  LinkedEntry _next = null;
  var _obj;
}

abstract class ItemOption<T> {
  T operator[](int i);
  operator[]=(int i, T v);
  setAll(T v);
}

class ItemSome<T> extends ItemOption<T> {
  final List<T> _vs;
  ItemSome(this._vs);
  T operator[](int i) => _vs[i];
  operator[]=(int i, T v) => _vs[i] = v;
  setAll(T v) {
    for(var i = _vs.length - 1; i > -1; i--) {_vs[i] = v;};
  }
}

class ItemDefault<T> extends ItemOption<T>{
  T _value;
  ItemDefault(this._value);
  T operator[](int i) => _value;
  /// do nothing
  operator[]=(int i, T v) {}
  setAll(T v) {
    _value = v;
  }

}