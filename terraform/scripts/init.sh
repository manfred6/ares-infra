#!/bin/bash

set -euo pipefail

terraform init
terraform validate .
terraform plan -var-file="variables.tfvars" -out "plan.tfplan"
terraform apply "plan.tfplan"
