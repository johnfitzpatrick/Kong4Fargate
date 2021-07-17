#!/bin/bash -xe
clear
terraform apply -auto-approve -var-file=terraform.tfvars

#export task_def_arn=$(aws ecs list-task-definitions | grep kong-api-gateway | awk -F'["]' '{print $2}')
#aws ecs update-service --task-definition ${task_def_arn} --cluster Kong4Fargate-dev-cluster --service Kong4Fargate-dev-gateway --force-new-deployment 1>/dev/null &
