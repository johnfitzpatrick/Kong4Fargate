variable "name" {
    description = "Deployment Name"
    default = "kong4fargate"
}
variable "revision" {
    description = "Deployment Revision"
    default = "v00.07"
}
variable "environment" {
    default = "prod"
}
variable "kong_proxy_type" {
    description = "Kong Proxy DB enabled or disabled"
    default = "dbless"
}
variable "image_kong_proxy" {
    description = "Kong Proxy Image"
    default = "kong/kong-gateway:2.4-alpine"
}
variable "additional_tags" {
    description = "Extra AWS Resource tags"
    default = { 
        "Name" : "Kong4Fargate",
        "Application" : "kong-api-gateway",
        "Environment" : "dev"
    }
}
variable "region" {
    description = "AWS Region"
    default = "us-east-2"
}
variable "capabilities" {
    description = "AWS Fargate Type | FARGATE, FARGATE_SPOT"
    default = "FARGATE"
}
variable "availability_zones" {
    description = "AWS VPC Availability Zones"
    default = ["us-east-2a", "us-east-2b", "us-east-2c"]
}
variable "aws_profile" {
    description = "AWS User Profile"
    default = "default"
}
variable "ecs_service_security_groups" {
    default = []
}
variable "cidr" {
    description = "AWS VPC Subnet Allocation"
    default = "192.19.0.0/16"
}
variable "public_subnets" {
    description = "Public | AWS Availability Zone Subnet CIDR List"
    default = ["192.19.0.0/24", "192.19.1.0/24", "192.19.2.0/24"]
}
variable "private_subnets" {
    description = "Private | AWS Availability Zone Subnet CIDR List"
    default = ["192.19.10.0/24", "192.19.11.0/24", "192.19.12.0/24"]
}
variable "aws_cloudwatch_group" {
    description = "AWS CloudWatch Group"
    default = "awslogs-fargate-kong"
}
variable "lb_tcp_health_port" {
    default = "8100"
}
variable "lb_tcp_http_listen_port" {
    default = "8080"
}
variable "lb_tcp_https_listen_port" {
    default = "8443"
}
variable "lb_tcp_admin_api_listen_port" {
    default = "8444"
}
variable "lb_tcp_admin_gui_listen_port" {
    default = "8445"
}
variable "kong_log_level" {
    default = "info"
}
variable "kong_pg_port" {
    default = "5432"
}
variable "kong_database" {
    default = "postgres"
}
variable "kong_pg_user" {
    default = "kong"
}
variable "kong_pg_host" {
    default = ""
}
variable "kong_pg_password" {
    default = "kong"
}
variable "kong_pg_database" {
    default = "kong"
}
variable "kong_pg_ssl_verify" {
    default = "on"
}