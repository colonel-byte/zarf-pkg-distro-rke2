#!/usr/bin/env bash

set -u
set -o pipefail

rm -rf   .direnv/bin files
mkdir -p .direnv/bin files

export RKE2_VERSION=$(yq '.package.create.set.rke2_version' zarf-config.yaml)
declare -a ARCH=("amd64" "arm64")

for arch in "${ARCH[@]}"; do
  echo "::debug::message='downloading rke2.linux-$arch at version $RKE2_VERSION'"
  curl ${GITHUB_TOKEN:+" -u \":$GITHUB_TOKEN\""} -s -L -o ./.direnv/bin/rke2.linux-$arch https://github.com/rancher/rke2/releases/download/$RKE2_VERSION/rke2.linux-$arch

  chmod +x .direnv/bin/rke2.linux-$arch

  export sha=$(sha256sum .direnv/bin/rke2.linux-$arch | awk '{ print $1 }')
  echo "::debug::sha='$sha'"

  export yq_sha=$(printf '.package.create.set.rke2_sha_%s = "%s"' "$arch" "$sha")
  echo "::debug::yq_sha='$yq_sha'"

  yq -i "$yq_sha" zarf-config.yaml
  echo "::debug::pulling air-gap image list"
  curl ${GITHUB_TOKEN:+" -u \":$GITHUB_TOKEN\""} -s -L -o files/images-core.linux-$arch.txt https://github.com/rancher/rke2/releases/download/$RKE2_VERSION/rke2-images-core.linux-$arch.txt
done
