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
library system_entity_state;

import "package:dartemis/dartemis.dart";

/**
 * A component containing information about [EntityState] to used for the component.
 *
 * Based on <http://www.richardlord.net/blog/finite-state-machines-with-ash>
 */
class EntityStateComponent extends Component {
  int _currentState = null;
  int _previousState = null;
  Map<int, EntityState> _states;

  /// the name of the 'virtual' state (if != currentState, then it be after next
  /// [EntityStateSystem.process()]
  int state;

  /// the name of the current state.
  get currentState => _currentState;
  /// the name of the previous state (before last [EntityStateSystem.process()])
  get previousState => _previousState;


  EntityStateComponent(this.state, Map<int, EntityState> this._states);
}

/**
 * A System applying [EntityState] on [Entity] based on its [EntityStateComponent].
 * Applying = added/removed/modified [Component] of the [Entity].
 * The System will update [EntityStateComponent.currentState] and
 * [EntityStateComponent.previousState].
 *
 * Based on <http://www.richardlord.net/blog/finite-state-machines-with-ash> but
 * without the EntityStateMachine, because :
 *
 * * [EntityState] changes are applying only on existing [Entity]
 *   via [EntityProcessingSystem] behavior of [System_EntityState].
 * * If a [EntitySystem] change [EntityStateComponent.state],
 *   the [Component] of [Entity] aren't added/modify/removed, so internal
 *   [ComponentMapper] of the System aren't impacted, and Aspect constraints
 *   of the System are keep.
 * * Other [EntitySystem] can compare the value of
 *   [EntityStateComponent.previousState] and [EntityStateComponent.currentState]
 *   to check if state has been changed since last process (to trigger some
 *   modifications).
 * * More EntitySystem way of doing (IMHO)
 */
class System_EntityState extends EntityProcessingSystem {
  ComponentMapper<EntityStateComponent> _escMapper;

  System_EntityState() : super(Aspect.getAspectForAllOf([EntityStateComponent]));

  void initialize(){
    _escMapper = new ComponentMapper<EntityStateComponent>(EntityStateComponent, world);
  }

  void processEntity(Entity entity) {
    var esc = _escMapper.get(entity);
    esc._previousState = esc._currentState;
    if (esc.state != null && esc.state != esc.currentState){
      var current = esc._states[esc.currentState];
      var next = esc._states[esc.state];
      assert(next != null);//, "state '${next}' is not defined");
      _changeStateOf(entity, current, next);
      esc._currentState = esc.state;
    }
  }

  void _changeStateOf(Entity e, EntityState current, EntityState next) {
    if (current == next) {
      // nothing to do
    } else {
      if (current != null) {
        //TODO optimize the computation of component diff
        current.forEach((provider) {
          var np = next.getByType(provider.type);
          if (np == null || np.id() != provider.id()) {
            e.removeComponentByType(provider.type);
          }
        });
      }
      // keep existing Component of the same type
      // (not previously removed because same provider.id or managed outside of the state machine)
      next.forEach((provider){
        var components = world.componentManager.getComponentsByType(provider.type);
        if (components == null || !components.isIndexWithinBounds(e.id) || components[e.id] == null) {
          e.addComponent(provider.createComponent(e));
        }
      });
      next.modifiers.forEach((modifier){
        modifier.applyE(e);
      });
      e.changedInWorld();
    }
  }
}

/**
 * Creates a component that can be added to the entity [e]
 * (but it should not add component to entity [e]).
 */
typedef Component CreateComponent(Entity e);

/**
 * Returns an identifier that is used to determine whether two component providers will
 * return the equivalent components.
 *
 * If an entity is changing state and the state it is leaving and the state is is
 * entering have components of the same type, then the identifiers of the component
 * provders are compared. If the two identifiers are the same then the component
 * is not removed. If they are different, the component from the old state is removed
 * and a component for the new state is added.
 */
typedef dynamic ComponentProviderId();

class ComponentProvider {
  static int _cnt = -1000000;
  static alwaysNewId() => _cnt++;
  static nullId() => null;

  /// Type of the provided Component
  final ComponentType type;

  final CreateComponent createComponent;

  final ComponentProviderId id;

  /**
   * Creates a new [ComponentProvider].
   *
   * The [createComponent] always has to create a [Component] that is returned
   * using the factory constructor of that [Component]. Do not return the same
   * instance for multiple calls, because it can return to [ObjectPool]
   * when it gets removed from the entity on a state change
   * if it extends [Poolable].
   */
  ComponentProvider(Type ctype, this.createComponent, [this.id = nullId]) : type = ComponentTypeManager.getTypeFor(ctype);
}

/**
 * Modify an existing component [c] of the entity.
 */
typedef void ModifyComponent<T>(T c);

class ComponentModifier<T> {
  final ComponentType type;
  final ModifyComponent<T> modifyComponent;

  //TODO use generic to define ctype and secure that ctype == T
  //(see https://code.google.com/p/dart/source/browse/branches/bleeding_edge/dart/tests/language/type_parameter_literal_test.dart)
  ComponentModifier(Type ctype, this.modifyComponent) : type = ComponentTypeManager.getTypeFor(ctype);

  void applyE(Entity e) {
    var c = e.getComponent(type);
    applyC(e.getComponent(type));
  }
  void applyC(T c) {
    if (c != null) modifyComponent(c);
  }
}

class EntityState {
  final _componentProviderByType = new Bag<ComponentProvider>();
  final _indicesP = new Set<int>();

  final modifiers = new List<ComponentModifier>();

  void add(ComponentProvider provider) {
    int index = provider.type.id;
    _componentProviderByType[index] = provider;
    _indicesP.add(index);
  }

  void forEach(void f(ComponentProvider)) {
    _indicesP.forEach((index) => f(_componentProviderByType[index]));
  }

  ComponentProvider getByType(ComponentType type) => _componentProviderByType[type.id];

}
