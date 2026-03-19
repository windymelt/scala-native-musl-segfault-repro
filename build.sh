#!/bin/sh
# Build a musl static binary in Alpine container.
# Usage: ./build.sh [source.scala] [output-name]
set -e

src="${1:-repro.scala}"
out="${2:-$(basename "$src" .scala)}"

docker run --rm -v "$PWD":/work -w /work alpine:latest sh -c "
  apk add --no-cache bash curl clang lld musl-dev openjdk17-jre-headless &&
  curl -fLo /usr/local/bin/coursier \
    https://github.com/coursier/launchers/raw/master/coursier.jar &&
  chmod +x /usr/local/bin/coursier &&
  coursier launch scala-cli -- --power package $src -o $out -f \
    --native-mode release-fast \
    --native-lto thin \
    --native-gc commix \
    --native-linking '-static'
"

echo "Built: ./$out"
