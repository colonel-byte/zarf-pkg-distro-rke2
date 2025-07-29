# Zarf `distro-rke2`

This is a very simple zarf package that bundles all the images, binaries, and systemd files for boot-strapping `rke2` inside an air-gapped network.

## Components

- `binary`
    - **required**
    - Validates that the system meets k8s stands for nodes
    - Stages the `rke2` binary at `/var/lib/rancher/rke2/bin/rke2`
- `server`
    - **optional**
    - Create the systemd service file for starting a server
    - Create symbolic link that enables the service to run during startup
- `agent`
    - **optional**
    - Create the systemd service file for starting an agent
    - Create symbolic link that enables the service to run during startup
- `images`
    - **required**
    - Caches required offline images for initial `rke2` deployment at `/var/lib/rancher/rke2/images`
