#!/bin/bash

set -euo pipefail

packer init .
packer fmt .
packer validate .
packer build .
