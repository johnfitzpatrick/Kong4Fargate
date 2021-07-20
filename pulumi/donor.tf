resource "aws_vpc" "main" {
  cidr_block = var.cidr
  tags = var.additional_tags
}
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = var.additional_tags
}
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  tags = var.additional_tags
}
resource "aws_route_table_association" "public" {
  count = length(var.public_subnets)
  subnet_id = element(aws_subnet.public.*.id, count.index)
  route_table_id = aws_route_table.public.id
}
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  count                   = length(var.public_subnets)
  map_public_ip_on_launch = true
  tags                    = var.additional_tags
}
resource "aws_subnet" "private" {
  vpc_id                  = aws_vpc.main.id
  count                   = length(var.private_subnets)
  tags                    = var.additional_tags
}
resource "aws_route_table" "private" {
  count  = length(var.private_subnets)
  vpc_id = aws_vpc.main.id
}
resource "aws_route_table_association" "private" {
  count          = length(var.private_subnets)
  subnet_id      = element(aws_subnet.private.*.id, count.index)
  route_table_id = element(aws_route_table.private.*.id, count.index)
}
resource "aws_route" "public" {
  route_table_id = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.main.id
}
resource "aws_route" "private" {
  route_table_id         = element(aws_route_table.private.*.id, count.index)
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = element(aws_nat_gateway.main.*.id, count.index)
}
resource "aws_eip" "nat" {
  count = length(var.private_subnets)
  vpc = true
}
resource "aws_nat_gateway" "main" {
  count = length(var.private_subnets)
  allocation_id = element(aws_eip.nat.*.id, count.index)
  subnet_id = element(aws_subnet.public.*.id, count.index)
  depends_on = [aws_internet_gateway.main]
}
resource "aws_ecs_cluster" "main" {
  name = "${var.name}-${var.environment}-cluster"
  capacity_providers = ["FARGATE_SPOT", "FARGATE"]
  default_capacity_provider_strategy {
      capacity_provider = "FARGATE_SPOT"
  }
  setting {
    name  = "containerInsights"
    value = "disabled"
  }
  tags = var.additional_tags
}
resource "aws_lb" "main" {
  name                       = "${var.name}-${var.environment}-lb"
  tags                       = var.additional_tags
  subnets                    = aws_subnet.public.*.id
  load_balancer_type         = "network"
  enable_deletion_protection = false
  internal                   = false
}
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.name}-ecsTaskExecutionRole"
  assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": "sts:AssumeRole",
     "Principal": {
       "Service": "ecs-tasks.amazonaws.com"
     },
     "Effect": "Allow",
     "Sid": ""
   }
 ]
}
EOF
}
resource "aws_iam_role_policy_attachment" "ecs-task-execution-role-policy-attachment" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
resource "aws_cloudwatch_log_group" "main" {
  name = "${var.aws_cloudwatch_group}-${var.environment}"
}
resource "aws_lb_listener" "kong_http" {
  port     = 80
  protocol = "TCP"
  load_balancer_arn = aws_lb.main.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.kong_http.arn
  }
  depends_on = [aws_lb_target_group.kong_http]
}
resource "aws_lb_target_group" "kong_http" {
  name            = "${var.name}-${var.environment}-tcp-http"
  tags            = var.additional_tags
  vpc_id          = aws_vpc.main.id
  port            = var.lb_tcp_http_listen_port
  protocol        = "TCP"
  target_type     = "ip"
  health_check {
    port                = var.lb_tcp_health_port
    enabled             = true
    protocol            = "TCP"
    interval            = 30
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }
  depends_on      = [aws_lb.main]
}
resource "aws_lb_listener" "kong_https" {
  port     = 443
  protocol = "TCP"
  load_balancer_arn = aws_lb.main.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.kong_https.arn
  }
  depends_on = [aws_lb_target_group.kong_https]
}
resource "aws_lb_target_group" "kong_https" {
  name            = "${var.name}-${var.environment}-tcp-https"
  tags            = var.additional_tags
  vpc_id          = aws_vpc.main.id
  port            = var.lb_tcp_https_listen_port
  protocol        = "TCP"
  target_type     = "ip"
  health_check {
    port                = var.lb_tcp_health_port
    protocol            = "TCP"
    enabled             = true
    interval            = 30
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }
  depends_on      = [aws_lb.main]
}
resource "aws_lb_listener" "kong_admin_api" {
  port     = var.lb_tcp_admin_api_listen_port
  protocol = "TCP"
  load_balancer_arn = aws_lb.main.arn
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.kong_admin_api.arn
  }
}
resource "aws_lb_target_group" "kong_admin_api" {
  name            = "${var.name}-${var.environment}-tcp-admin-api"
  tags            = var.additional_tags
  vpc_id          = aws_vpc.main.id
  port            = var.lb_tcp_admin_api_listen_port
  protocol        = "TCP"
  target_type     = "ip"
  health_check {
    port                = var.lb_tcp_health_port
    protocol            = "TCP"
    enabled             = true
    interval            = 30
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }
  depends_on = [aws_lb.main]
}
resource "aws_lb_listener" "kong_admin_gui" {
  port     = var.lb_tcp_admin_gui_listen_port
  protocol = "TCP"
  load_balancer_arn = aws_lb.main.arn
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.kong_admin_gui.arn
  }
}
resource "aws_lb_target_group" "kong_admin_gui" {
  name            = "${var.name}-${var.environment}-tcp-admin-gui"
  tags            = var.additional_tags
  vpc_id          = aws_vpc.main.id
  port            = var.lb_tcp_admin_gui_listen_port
  protocol        = "TCP"
  target_type     = "ip"
  health_check {
    port                = var.lb_tcp_health_port
    protocol            = "TCP"
    enabled             = true
    interval            = 30
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }
  depends_on = [aws_lb.main]
}
resource "aws_ecs_task_definition" "main" {
  family                   = "kong-api-gateway"
  network_mode             = "awsvpc"
  requires_compatibilities = ["${var.capabilities}"]
  cpu                      = 256
  memory                   = 1024
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  container_definitions    = data.template_file.td_proxy.rendered  
}
resource "aws_security_group" "kong_gateway" {
  name   = "${var.name}-${var.environment}"
  vpc_id = aws_vpc.main.id
 
  ingress {
   protocol         = "tcp"
   to_port          = var.lb_tcp_http_listen_port
   from_port        = var.lb_tcp_http_listen_port
   cidr_blocks      = ["0.0.0.0/0"]
   ipv6_cidr_blocks = ["::/0"]
   description      = "proxy http listener port"
  }
 
  ingress {
   protocol         = "tcp"
   from_port        = var.lb_tcp_https_listen_port
   to_port          = var.lb_tcp_https_listen_port
   cidr_blocks      = ["0.0.0.0/0"]
   ipv6_cidr_blocks = ["::/0"]
   description      = "proxy https listener port"
  }
 
  ingress {
   protocol         = "tcp"
   from_port        = var.lb_tcp_admin_api_listen_port
   to_port          = var.lb_tcp_admin_api_listen_port
   cidr_blocks      = ["0.0.0.0/0"]
   ipv6_cidr_blocks = ["::/0"]
   description      = "proxy admin api listener port"
  }
 
  ingress {
   protocol         = "tcp"
   from_port        = var.lb_tcp_admin_gui_listen_port
   to_port          = var.lb_tcp_admin_gui_listen_port
   cidr_blocks      = ["0.0.0.0/0"]
   ipv6_cidr_blocks = ["::/0"]
   description      = "proxy admin gui listener port"
  }
 
  ingress {
   protocol         = "tcp"
   from_port        = var.lb_tcp_health_port
   to_port          = var.lb_tcp_health_port
   cidr_blocks      = ["0.0.0.0/0"]
   ipv6_cidr_blocks = ["::/0"]
   description      = "status check"
  }
 
  ingress {
   protocol         = "tcp"
   from_port        = "5432"
   to_port          = "5432"
   cidr_blocks      = ["0.0.0.0/0"]
   ipv6_cidr_blocks = ["::/0"]
   description      = "status check"
  }
  egress {
   protocol         = "-1"
   from_port        = 0
   to_port          = 0
   cidr_blocks      = ["0.0.0.0/0"]
   ipv6_cidr_blocks = ["::/0"]
  }
  tags = var.additional_tags
}
output "dns" {
  description = "Load Balancer DNS"
  value       = aws_lb.main.dns_name
}
name                 = "Kong4Fargate"
revision             = "v00.07.24"
aws_profile          = "default"
environment          = "dev"
additional_tags      = { 
    Name : "Kong4Fargate",
    ownerName : "usrbinkat",
    Application : "kong-api-gateway",
    Revision    : "v00.07.23"
    Environment : "dev"
}


// ----------------------------------------------------------------------
// Kong Configuration
// ----------------------------------------------------------------------

kong_proxy_type      = "dbfull"                                          // supported: dbless,  dbfull
image_kong_proxy     = "quay.io/containercraft/kong:b64lsup-a02-d9eccaa" // testing base64 encoded license support
#image_kong_proxy     = "docker.io/kong/kong-gateway:2.4-alpine"
kong_log_level       = "debug"
kong_pg_port         = "5432"
kong_database        = "postgres"
kong_pg_user         = "rdspostgresql"
kong_pg_host         = "db-kong-fargate-dev.ctzjaxtr66nw.us-east-2.rds.amazonaws.com"
kong_pg_password     = "rdspostgresql"
kong_pg_database     = "kong"
kong_pg_ssl_verify   = "off"



// ----------------------------------------------------------------------
//  AWS Configuration
// ----------------------------------------------------------------------

// AWS Region & Zones
region               = "us-east-2"
availability_zones   = ["us-east-2a", "us-east-2b", "us-east-2c"]
capabilities         = "FARGATE"        // supported: FARGATE, FARGATE_SPOT

// VPC CIDRs
cidr                 = "192.19.0.0/16"
public_subnets       = ["192.19.11.0/24", "192.19.12.0/24", "192.19.13.0/24"]
private_subnets      = ["192.19.21.0/24", "192.19.22.0/24", "192.19.23.0/24"]

