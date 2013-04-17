import "package:dartemis/dartemis.dart" hide ComponentProvider, EntityState,
       EntityStateComponent;
import "package:unittest/mock.dart";
import "package:unittest/unittest.dart";
import "dart:math" as Math;
import "package:dartemis_addons/entity_state.dart";

main() {

  group('EntityStateSystem tests',(){
    const stateAB = 1;
    const stateAC = 2;
    const stateC = 3;
    const stateCD3 = 4;
    const stateD3 = 5;
    const stateCD4 = 6;
    var pA = new ComponentProvider(ComponentA, (e) => new ComponentA(), () => "A");
    var pB = new ComponentProvider(ComponentB, (e) => new ComponentB(), () => "B");
    var pC = new ComponentProvider(ComponentC, (e) => new ComponentC(), () => "C");
    var esr = new Map<int, EntityState>()
      ..[stateAB] = (new EntityState()
        ..add(pA)
        ..add(pB)
      )
      ..[stateAC] = (new EntityState()
        ..add(pA)
        ..add(pC)
      )
      ..[stateC] = (new EntityState()
        ..add(pC)
      )
      ..[stateCD3] = (new EntityState()
        ..add(pC)
        ..add(new ComponentProvider(ComponentD, (e) => new ComponentD(3), () => "D3"))
      )
      ..[stateD3] = (new EntityState()
        ..add(new ComponentProvider(ComponentD, (e) => new ComponentD(3), () => "D3"))
      )
      ..[stateCD4]= (new EntityState()
        ..add(pC)
        ..add(new ComponentProvider(ComponentD, (e) => new ComponentD(4), ComponentProvider.alwaysNewId))
      )
      ;
    var world = new World();
    world.addSystem(new EntityStateSystem());
    world.initialize();

    setUp(() {
      //expect(e.getComponents().size, equals(0));

    });

    tearDown((){
      world.deleteAllEntities();
    });

    test('start state is apply after next .process()', (){
      var e = world.createEntity();
      var c = new EntityStateComponent(stateCD4, esr);
      e.addComponent(c);
      e.changedInWorld();
      expect(c.currentState, isNull);
      expect(c.previousState, isNull);
      expect(c.state, equals(stateCD4));
      expect(e.getComponents().size, equals(1));
      world.process();
      expect(c.currentState, equals(stateCD4));
      expect(c.previousState, isNull);
      expect(c.state, equals(stateCD4));
      expect(e.getComponents().size, equals(3));
      expect(e.getComponentByClass(ComponentC), isNotNull);
      expect((e.getComponentByClass(ComponentD) as ComponentD).d, equals(4));
    });

    test('states change are idempotent, only previousState is updated', (){
      var e = world.createEntity();
      var c = new EntityStateComponent(stateCD4, esr);
      e.addComponent(c);
      e.changedInWorld();
      world.process();
      expect(c.currentState, equals(stateCD4));
      expect(c.previousState, isNull);
      expect(c.state, equals(stateCD4));

      for(var i =0; i < 3; i++) {
        c.state = stateCD4;
        world.process();
        expect(c.currentState, equals(stateCD4));
        expect(c.previousState, equals(stateCD4));
        expect(c.state, equals(stateCD4));
        expect((e.getComponentByClass(ComponentD) as ComponentD).d, equals(4));
      }

      (e.getComponentByClass(ComponentD) as ComponentD).d = 16;
      for(var i =0; i < 3; i++) {
        c.state = stateCD4;
        world.process();
        expect(c.currentState, equals(stateCD4));
        expect(c.previousState, equals(stateCD4));
        expect(c.state, equals(stateCD4));
        expect((e.getComponentByClass(ComponentD) as ComponentD).d, equals(16));
      }
    });
    test('states change add Component of next state if it s not part of current state', (){
      var e = world.createEntity();
      var c = new EntityStateComponent(stateAB, esr);
      e.addComponent(c);
      e.changedInWorld();

      world.process();
      expect(e.getComponentByClass(ComponentC), isNull);

      c.state = stateAC;
      expect(e.getComponentByClass(ComponentC), isNull);
      world.process();
      expect(e.getComponentByClass(ComponentC), isNotNull);
    });
    test('states change keep Component if ComponentProvider return same id', (){
      var e = world.createEntity();
      var c = new EntityStateComponent(stateCD3, esr);
      e.addComponent(c);
      e.changedInWorld();

      world.process();
      (e.getComponentByClass(ComponentD) as ComponentD).d = 33;
      c.state = stateD3;

      world.process();
      expect((e.getComponentByClass(ComponentD) as ComponentD).d, equals(33));
    });
    test('states change replace Component if ComponentProvider returns different id', (){
      var e = world.createEntity();
      var c = new EntityStateComponent(stateCD3, esr);
      e.addComponent(c);
      e.changedInWorld();

      world.process();
      expect((e.getComponentByClass(ComponentD) as ComponentD).d, equals(3));
      c.state = stateCD4;

      world.process();
      expect((e.getComponentByClass(ComponentD) as ComponentD).d, equals(4));
    });
    test('states change keep Component if its not part of current state', (){
      var e = world.createEntity();
      var c = new EntityStateComponent(stateAB, esr);
      e.addComponent(c);
      e.changedInWorld();

      world.process();
      e.addComponent(new ComponentD(33));
      expect((e.getComponentByClass(ComponentD) as ComponentD).d, equals(33));
      c.state = stateAC;

      world.process();
      expect((e.getComponentByClass(ComponentD) as ComponentD).d, equals(33));
    });
    test('states change keep Component if its not part of current state and ignore ComponentProvider for the same component Type', (){
      var e = world.createEntity();
      var c = new EntityStateComponent(stateAB, esr);
      e.addComponent(c);
      e.changedInWorld();

      world.process();
      e.addComponent(new ComponentD(33));
      expect((e.getComponentByClass(ComponentD) as ComponentD).d, equals(33));
      c.state = stateCD4;

      world.process();
      expect((e.getComponentByClass(ComponentD) as ComponentD).d, equals(33));
    });
    test('states change remove Component of current state if it s not part of next state', (){
      var e = world.createEntity();
      var c = new EntityStateComponent(stateAB, esr);
      e.addComponent(c);
      e.changedInWorld();

      world.process();
      expect(e.getComponentByClass(ComponentB), isNotNull);
      c.state = stateAC;

      world.process();
      expect(e.getComponentByClass(ComponentB), isNull);
    });

  });
}

class ComponentA implements Component {
  ComponentA._();
  factory ComponentA() => new Component(ComponentA, () => new ComponentA._());
}
class ComponentB implements Component {
  ComponentB._();
  factory ComponentB() => new Component(ComponentB, () => new ComponentB._());
}
class ComponentC implements Component {
  ComponentC._();
  factory ComponentC() => new Component(ComponentC, () => new ComponentC._());
}
class ComponentD implements Component {
  int d = 0;
  ComponentD._();
  factory ComponentD(int d) {
    var component = new Component(ComponentD, () => new ComponentD._());
    component.d = d;
    return component;
  }
}
