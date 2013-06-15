part of demos;

demo_proto2d(world) {
  addNewEntity(world, [
    new Transform.w2d(50.0, 50.0, 0.0),
    new proto.Drawable(proto.rect(10.0,10.0, fillStyle : foregroundcolorsM[3], strokeStyle : foregroundcolorsM[0]))
  ]);
  addNewEntity(world, [
    new Transform.w2d(0.0, 20.0, 0.0),
    new proto.Drawable(proto.text("Hello World, choose an other demo in the list", strokeStyle : foregroundcolorsM[0], font: '16px sans-serif'))
  ]);
  return new Future.value(world);
}
