
# Overview

`dartemis_toolbox` is a repository of libraries for gamedev (in dart) for 2D or 3D.

* [API](http://davidb.github.io/dartemis_toolbox/apidoc/)
* Examples :
  * [demonstrations](http://davidb.github.io/dartemis_toolbox/demos.html) : animation, particle, verlet, ... in proto2d
  * [graphics of functions](http://davidb.github.io/dartemis_toolbox/ease_graphics.html)
  * [color editor](http://davidb.github.io/dartemis_toolbox/colors_demo.html)

# Libraries :

## Lightweight

* [ease](http://davidb.github.io/dartemis_toolbox/apidoc/ease.html) is a set of common ease functions for interpolation, transition, animations, 
* [colors](http://davidb.github.io/dartemis_toolbox/apidoc/colors.html) functions to convert and modified colors (irgba, rgb, hsv, hsl, darken, lighten, triad, tetrad, ...)
* quadtree *WIP*
* collisions 2D *WIP*

## Dartemis'brick

You don't need to embrace the dartemis framework in your application to use the brick in.

* [transform](http://davidb.github.io/dartemis_toolbox/apidoc/system_transform.html) used to define the position, rotation and scale of your entity in space (2D + 3D).
* [animator](http://davidb.github.io/dartemis_toolbox/apidoc/system_animator.html) components + system to manage animation (any update on entity, with a start, a duration (infinity) and a stop).
* [entity_state](http://davidb.github.io/dartemis_toolbox/apidoc/system_entity_state.html) a way to manage states (of a finite state machine) of your entity : state == group of component (to add, to remove, to modify).
* [simple_audio](http://davidb.github.io/dartemis_toolbox/apidoc/system_simple_audio.html) a way to integrate simple_audio into your dartemis application to play sound, music.
* [proto2d](http://davidb.github.io/dartemis_toolbox/apidoc/system_proto2d.html) used to debug or to prototype display in canvas (eg: as blueprint in [demonstrations](http://davidb.github.io/dartemis_toolbox/demos.html))
* [emitter](http://davidb.github.io/dartemis_toolbox/apidoc/system_emitter.html) used to create entity (regular or particles)
* [particles](http://davidb.github.io/dartemis_toolbox/apidoc/system_particles.html) basic definitions of particles *WIP*
* [verlet simulator](http://davidb.github.io/dartemis_toolbox/apidoc/system_verlet.html) (~ physic engine) *WIP*
* three.js integration *WIP*
* box2d integration *WIP*

## Widgets (webcomponent)

* xfchart to display a function (eg: used in the ease_graphics.html)
* xtchart to display chart of realtime data like time serie (via push)  

# Dependencies

Every dependencies are defined as `dev_dependencies` so :

* users'project aren't pollute by not required thrid-party lib (if you use entity_state, you don't need box2d)
* users should explicitly list dependencies requeried by the dartemis addon (eg: box2d, vector_math) in its own project.

Contributions are welcome.

[![Build Status](https://drone.io/github.com/davidB/dartemis_toolbox/status.png)](https://drone.io/github.com/davidB/dartemis_toolbox/latest)


[dartemis]: https://github.com/denniskaselow/dartemis