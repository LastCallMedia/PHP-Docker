#!/bin/bash

set -euo pipefail

repo_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
test_dir=$(mktemp -d "${TMPDIR:-/tmp}/php-docker-regenerate.XXXXXX")
trap 'rm -rf "$test_dir"' EXIT

# Use the built development image, which includes Bash and dockerize 0.6.1.
image=${DOCKERIZE_IMAGE:-lastcallmedia/php:8.4-dev}
cp "$repo_dir/regenerate.sh" "$test_dir/"
cp -R "$repo_dir/template" "$test_dir/template"

bash -n "$test_dir/regenerate.sh"
docker run --rm --entrypoint /bin/bash \
  -v "$test_dir:/work" -w /work \
  "$image" -e ./regenerate.sh
docker compose -f "$test_dir/docker-compose.yml" config --quiet

echo "All Dockerfile and test templates rendered; generated Compose configuration is valid."
