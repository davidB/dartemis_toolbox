[![Build Status](https://drone.io/github.com/davidB/dartemis_addons/status.png)](https://drone.io/github.com/davidB/dartemis_addons/latest)
# Overview

`dartemis_addons` is a repository of various addons usable with [dartemis][], like Systems, Components, helpers.
Each addon is defined its own library (often single source file). Some can be used without [dartemis][] like [ease](https://github.com/davidB/dartemis_addons/lib/ease.dart), [utils](https://github.com/davidB/dartemis_addons/lib/utils.dart).
But you don't need to embrace the dartemis framework in your application to use addons.

Current addons :

* [ease](https://github.com/davidB/dartemis_addons/lib/ease.dart) is a set of common ease functions used for interpolation, transition, animations, (*no dependencies*)
* [transform](https://github.com/davidB/dartemis_addons/lib/transform.dart) used to define the position of your entity in space (2D and/or 3D).
* [animator](https://github.com/davidB/dartemis_addons/lib/animator.dart) components + system to manage animation (any update on entity, with a start, a duration (infinity) and a stop).
* [entity_state](https://github.com/davidB/dartemis_addons/lib/entity_state.dart) a way to manage states (of a finite state machine) of your entity : state == group of component (to add, to remove, to modify).
* [simple_audio](https://github.com/davidB/dartemis_addons/lib/entity_state.dart) a way to integrate simple_audio into your dartemis application to play sound, music.
* widgets (webcomponent) :
  * xfchart to display a function (eg: used in the ease_graphics.html)
  * xtchart to display chart of realtime data like time serie (via push)  


# Dependencies

Every dependencies are defined as `dev_dependencies` so :

* users'project aren't pollute by not required thrid-party lib (if you use entity_state, you don't need box2d)
* users should explicitly list dependencies requeried by the dartemis addon (eg: box2d, vector_math) in its own project.

Contributions are welcome.


[dartemis]: https://github.com/denniskaselow/dartemis
