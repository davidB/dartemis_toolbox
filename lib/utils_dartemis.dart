library utils_dartemis;

import 'package:dartemis/dartemis.dart';

addNewEntity(world, List<Component> cs, {String player, List<String> groups}) {
  var e = world.createEntity();
  cs.forEach((c) => e.addComponent(c));
  if (groups != null) {
    var gm = (world.getManager(GroupManager) as GroupManager);
    groups.forEach((group) => gm.add(e, group));
  }
  if (player != null) {
    (world.getManager(PlayerManager) as PlayerManager).setPlayer(e, player);
  }
  world.addEntity(e);
  return e;
}

/**
 * Non generic version of ComponentMapper from dartemis (remove type cast)
 * High performance component retrieval from entities. Use this wherever you need
 * to retrieve components from entities often and fast.
 */
class ComponentMapper0 {
  ComponentType _type;
  Bag<Component> _components;

  ComponentMapper0(Type componentType, World world) {
    this._type = ComponentTypeManager.getTypeFor(componentType);
    _components = world.componentManager.getComponentsByType(this._type);
  }

  /**
   * Fast but unsafe retrieval of a component for this entity.
   * No bounding checks, so this could throw an ArrayIndexOutOfBoundsExeption,
   * however in most scenarios you already know the entity possesses this component.
   */
  get(Entity e) => _components[e.id];

  /**
   * Fast and safe retrieval of a component for this entity.
   * If the entity does not have this component then null is returned.
   */
  getSafe(Entity e) {
    if(_components.isIndexWithinBounds(e.id)) {
      return _components[e.id];
    }
    return null;
  }

  /**
   * Checks if the entity has this type of component.
   */
  bool has(Entity e) => getSafe(e) != null;
}