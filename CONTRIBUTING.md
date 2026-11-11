# How to contribute

Welcome, and thanks for contributing to PHP-Docker!

## Reporting Bugs

Please include as much information as possible when reporting a bug, even if it might not seem relevant; for example:

* Host OS
* Which container you are having an issue with (php version, dev or non-dev)
* Any other containers you are using alongside the PHP-Docker container
* Steps to reproduce the problem
* Expected behavior vs actual behavior

It is also helpful to know if you are a new user or not; are you a new user, and the project is not doing something you'd hoped? Or have you used these containers before, and the issue just began in the past week?

## Pull Requests

These containers aim for a balance between usefulness and efficiency (small size, not a lot of extra overhead). We will happily accept pull requests, but if you are proposing anything large or complex, it may be best to create an issue beforhand.

### Test regeneration locally

With Docker running and the `lastcallmedia/php:8.4-dev` image built, run:

```bash
bash ./test-regenerate.sh
```

This uses the image's `dockerize` 0.6.1 to render all templates in a temporary
directory and validate the generated Compose file. It leaves the repository's
generated files unchanged. Set `DOCKERIZE_IMAGE` to use another image containing
Bash and `dockerize` 0.6.1.

To update the generated files in the repository, install `dockerize` 0.6.1 locally
and run `./regenerate.sh`. CI also checks that those generated files match the
committed files. The local template check does not build the generated images.
