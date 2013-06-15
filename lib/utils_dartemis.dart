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