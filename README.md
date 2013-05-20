[![Build Status](https://drone.io/github.com/davidB/dartemis_toolbox/status.png)](https://drone.io/github.com/davidB/dartemis_toolbox/latest)
# Overview

`dartemis_toolbox` is a repository of libraries for gamedev (in dart) for 2D or 3D.
There 2 categories of libraryource file) Some can be used without [dartemis][] like [ease](https://github.com/davidB/dartemis_toolbox/lib/ease.dart), [utils](https://github.com/davidB/dartemis_toolbox/lib/utils.dart).
But you don't need to embrace the dartemis framework in your application to use addons.

# Libraries :

## Lightweight

* [ease](https://github.com/davidB/dartemis_toolbox/blob/master/lib/ease.dart) is a set of common ease functions for interpolation, transition, animations, (*no dependencies*)
  [graphics of functions](http://davidb.github.io/dartemis_toolbox/ease_graphics.html) [API](http://davidb.github.io/dartemis_toolbox/apidoc/ease.html)
* [colors](https://github.com/davidB/dartemis_toolbox/)
  [demonstration](http://davidb.github.io/dartemis_toolbox/colors_demo.html)[API](http://davidb.github.io/dartemis_toolbox/apidoc/colors.html)
* quadtree
* collisions

## Dartemis'brick

* [transform](https://github.com/davidB/dartemis_toolbox/lib/transform.dart) used to define the position of your entity in space (2D and/or 3D).
* [animator](https://github.com/davidB/dartemis_toolbox/lib/animator.dart) components + system to manage animation (any update on entity, with a start, a duration (infinity) and a stop).
* [entity_state](https://github.com/davidB/dartemis_toolbox/lib/entity_state.dart) a way to manage states (of a finite state machine) of your entity : state == group of component (to add, to remove, to modify).
* [simple_audio](https://github.com/davidB/dartemis_toolbox/lib/entity_state.dart) a way to integrate simple_audio into your dartemis application to play sound, music.
* proto2d
* emitter
* particle
* verlet simulator (~ physic engine)
* three.js integration (TODO)
* box2d integration (TODO)

## Widgets (webcomponent)

* xfchart to display a function (eg: used in the ease_graphics.html)
* xtchart to display chart of realtime data like time serie (via push)  

# Dependencies

Every dependencies are defined as `dev_dependencies` so :

* users'project aren't pollute by not required thrid-party lib (if you use entity_state, you don't need box2d)
* users should explicitly list dependencies requeried by the dartemis addon (eg: box2d, vector_math) in its own project.

Contributions are welcome.


[dartemis]: https://github.com/denniskaselow/dartemis
