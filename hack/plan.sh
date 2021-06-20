#!/bin/bash -x
terraform plan -var-file=terraform.tfvars $@
