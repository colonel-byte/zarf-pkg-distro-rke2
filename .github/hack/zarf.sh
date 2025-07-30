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

echo "::debug::pulling down the rke2 linux tar bundle"
curl ${GITHUB_TOKEN:+" -u \":$GITHUB_TOKEN\""} -s -L -o ./.direnv/bin/rke2.linux-amd64.tar.gz https://github.com/rancher/rke2/releases/download/$RKE2_VERSION/rke2.linux-amd64.tar.gz

echo "::debug::extracting the contents of the rke2 linux tar bundle"
zarf tools archiver decompress .direnv/bin/rke2.linux-amd64.tar.gz .direnv/bin/

echo "::debug::copy and update the agent service file to be compatible with zarf config"
cp .direnv/bin/lib/systemd/system/rke2-agent.service  files/rke2-agent.service
sed -i 's!/usr/local/bin/rke2 agent!/var/lib/rancher/rke2/bin/rke2 agent ###ZARF_VAR_RKE2_ARGS###!g' files/rke2-agent.service

echo "::debug::copy and update the server service file to be compatible with zarf config"
cp .direnv/bin/lib/systemd/system/rke2-server.service files/rke2-server.service
sed -i 's!/usr/local/bin/rke2 server!/var/lib/rancher/rke2/bin/rke2 server ###ZARF_VAR_RKE2_ARGS###!g' files/rke2-server.service
