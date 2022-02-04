# Kong4Fargate
Kong for Fargate

1. You must have AWS Access Key and Secret Access Key in `~/.aws/credentials`

1. Set the AWS profile, `kong_proxy_type`, and other metadata in `terraform/terraform.tfvars`

1. `terraform init`

1. `terraform apply -auto-approve -var-file=terraform.tfvars`

1. You should see your url, like Kong4Fargate01-dev-lb-81be3392be1028d7.elb.us-east-2.amazonaws.com

1. `https --verify=no Kong4Fargate01-dev-lb-81be339b2d1028d7.elb.us-east-2.amazonaws.com:8444`