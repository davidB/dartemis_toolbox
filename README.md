# Overview

`dartemis_addons` is a repository of various addons usable with [dartemis][], like Systems, Components, helpers.
Each familly of addons define its own library (often single source file).

Contributions are welcome.

# Dependencies

Except [dartemis][], every dependencies are defined as `dev_dependencies` so :

* users'project aren't pollute by not required thrid-party lib (if you use entity_state, you don't need box2d)
* users should explicitly list dependencies in its own project requeried by the dartemis addon (library) (eg: box2d, vector_math)


    [dartemis]: https://github.com/denniskaselow/dartemis
