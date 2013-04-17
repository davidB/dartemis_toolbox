# Overview

`dartemis_addons` is a repository of various addons usable with [dartemis][], like Systems, Components, helpers.
Each addon is defined its own library (often single source file).

Contributions are welcome.

# Dependencies

Except [dartemis][], every dependencies are defined as `dev_dependencies` so :

* users'project aren't pollute by not required thrid-party lib (if you use entity_state, you don't need box2d)
* users should explicitly list dependencies requeried by the dartemis addon (eg: box2d, vector_math) in its own project.


[dartemis]: https://github.com/denniskaselow/dartemis
