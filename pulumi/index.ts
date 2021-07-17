import pulumi
import pulumi_aws as aws

main_vpc = aws.ec2.Vpc("mainVpc",
    cidr_block=var["cidr"],
    tags=var["additional_tags"])
main_internet_gateway = aws.ec2.InternetGateway("mainInternetGateway",
    vpc_id=main_vpc.id,
    tags=var["additional_tags"])
public_route_table = aws.ec2.RouteTable("publicRouteTable",
    vpc_id=main_vpc.id,
    tags=var["additional_tags"])
public_subnet = []
for range in [{"value": i} for i in range(0, len(var.public_subnets))]:
    public_subnet.append(aws.ec2.Subnet(f"publicSubnet-{range['value']}",
        vpc_id=main_vpc.id,
        map_public_ip_on_launch=True,
        tags=var["additional_tags"]))
public_route_table_association = []
for range in [{"value": i} for i in range(0, len(var.public_subnets))]:
    public_route_table_association.append(aws.ec2.RouteTableAssociation(f"publicRouteTableAssociation-{range['value']}",
        subnet_id=[__item.id for __item in public_subnet][range["value"]],
        route_table_id=public_route_table.id))
private_subnet = []
for range in [{"value": i} for i in range(0, len(var.private_subnets))]:
    private_subnet.append(aws.ec2.Subnet(f"privateSubnet-{range['value']}",
        vpc_id=main_vpc.id,
        tags=var["additional_tags"]))
private_route_table = []
for range in [{"value": i} for i in range(0, len(var.private_subnets))]:
    private_route_table.append(aws.ec2.RouteTable(f"privateRouteTable-{range['value']}", vpc_id=main_vpc.id))
private_route_table_association = []
for range in [{"value": i} for i in range(0, len(var.private_subnets))]:
    private_route_table_association.append(aws.ec2.RouteTableAssociation(f"privateRouteTableAssociation-{range['value']}",
        subnet_id=[__item.id for __item in private_subnet][range["value"]],
        route_table_id=[__item.id for __item in private_route_table][range["value"]]))
public_route = aws.ec2.Route("publicRoute",
    route_table_id=public_route_table.id,
    destination_cidr_block="0.0.0.0/0",
    gateway_id=main_internet_gateway.id)
nat = []
for range in [{"value": i} for i in range(0, len(var.private_subnets))]:
    nat.append(aws.ec2.Eip(f"nat-{range['value']}", vpc=True))
main_nat_gateway = []
for range in [{"value": i} for i in range(0, len(var.private_subnets))]:
    main_nat_gateway.append(aws.ec2.NatGateway(f"mainNatGateway-{range['value']}",
        allocation_id=[__item.id for __item in nat][range["value"]],
        subnet_id=[__item.id for __item in public_subnet][range["value"]],
        opts=ResourceOptions(depends_on=[main_internet_gateway])))
private_route = aws.ec2.Route("privateRoute",
    route_table_id=[__item.id for __item in private_route_table][count["index"]],
    destination_cidr_block="0.0.0.0/0",
    nat_gateway_id=[__item.id for __item in main_nat_gateway][count["index"]])
main_cluster = aws.ecs.Cluster("mainCluster",
    capacity_providers=[
        "FARGATE_SPOT",
        "FARGATE",
    ],
    default_capacity_provider_strategies=[{
        "capacityProvider": "FARGATE_SPOT",
    }],
    settings=[{
        "name": "containerInsights",
        "value": "disabled",
    }],
    tags=var["additional_tags"])
main_load_balancer = aws.lb.LoadBalancer("mainLoadBalancer",
    tags=var["additional_tags"],
    subnets=[__item.id for __item in public_subnet],
    load_balancer_type="network",
    enable_deletion_protection=False,
    internal=False)
ecs_task_execution_role = aws.iam.Role("ecsTaskExecutionRole", assume_role_policy="""{
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
""")
ecs_task_execution_role_policy_attachment = aws.iam.RolePolicyAttachment("ecs-task-execution-role-policy-attachment",
    role=ecs_task_execution_role.name,
    policy_arn="arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy")
main_log_group = aws.cloudwatch.LogGroup("mainLogGroup")
kong_http_target_group = aws.lb.TargetGroup("kongHttpTargetGroup",
    tags=var["additional_tags"],
    vpc_id=main_vpc.id,
    port=var["lb_tcp_http_listen_port"],
    protocol="TCP",
    target_type="ip",
    health_check={
        "port": var["lb_tcp_health_port"],
        "enabled": True,
        "protocol": "TCP",
        "interval": 30,
        "healthyThreshold": 3,
        "unhealthyThreshold": 3,
    },
    opts=ResourceOptions(depends_on=[main_load_balancer]))
kong_http_listener = aws.lb.Listener("kongHttpListener",
    port=80,
    protocol="TCP",
    load_balancer_arn=main_load_balancer.arn,
    default_actions=[{
        "type": "forward",
        "target_group_arn": kong_http_target_group.arn,
    }],
    opts=ResourceOptions(depends_on=[kong_http_target_group]))
kong_https_target_group = aws.lb.TargetGroup("kongHttpsTargetGroup",
    tags=var["additional_tags"],
    vpc_id=main_vpc.id,
    port=var["lb_tcp_https_listen_port"],
    protocol="TCP",
    target_type="ip",
    health_check={
        "port": var["lb_tcp_health_port"],
        "protocol": "TCP",
        "enabled": True,
        "interval": 30,
        "healthyThreshold": 3,
        "unhealthyThreshold": 3,
    },
    opts=ResourceOptions(depends_on=[main_load_balancer]))
kong_https_listener = aws.lb.Listener("kongHttpsListener",
    port=443,
    protocol="TCP",
    load_balancer_arn=main_load_balancer.arn,
    default_actions=[{
        "type": "forward",
        "target_group_arn": kong_https_target_group.arn,
    }],
    opts=ResourceOptions(depends_on=[kong_https_target_group]))
kong_admin_api_target_group = aws.lb.TargetGroup("kongAdminApiTargetGroup",
    tags=var["additional_tags"],
    vpc_id=main_vpc.id,
    port=var["lb_tcp_admin_api_listen_port"],
    protocol="TCP",
    target_type="ip",
    health_check={
        "port": var["lb_tcp_health_port"],
        "protocol": "TCP",
        "enabled": True,
        "interval": 30,
        "healthyThreshold": 3,
        "unhealthyThreshold": 3,
    },
    opts=ResourceOptions(depends_on=[main_load_balancer]))
kong_admin_api_listener = aws.lb.Listener("kongAdminApiListener",
    port=var["lb_tcp_admin_api_listen_port"],
    protocol="TCP",
    load_balancer_arn=main_load_balancer.arn,
    default_actions=[{
        "type": "forward",
        "target_group_arn": kong_admin_api_target_group.arn,
    }])
kong_admin_gui_target_group = aws.lb.TargetGroup("kongAdminGuiTargetGroup",
    tags=var["additional_tags"],
    vpc_id=main_vpc.id,
    port=var["lb_tcp_admin_gui_listen_port"],
    protocol="TCP",
    target_type="ip",
    health_check={
        "port": var["lb_tcp_health_port"],
        "protocol": "TCP",
        "enabled": True,
        "interval": 30,
        "healthyThreshold": 3,
        "unhealthyThreshold": 3,
    },
    opts=ResourceOptions(depends_on=[main_load_balancer]))
kong_admin_gui_listener = aws.lb.Listener("kongAdminGuiListener",
    port=var["lb_tcp_admin_gui_listen_port"],
    protocol="TCP",
    load_balancer_arn=main_load_balancer.arn,
    default_actions=[{
        "type": "forward",
        "target_group_arn": kong_admin_gui_target_group.arn,
    }])
main_task_definition = aws.ecs.TaskDefinition("mainTaskDefinition",
    family="kong-api-gateway",
    network_mode="awsvpc",
    requires_compatibilities=[var["capabilities"]],
    cpu=256,
    memory=1024,
    execution_role_arn=ecs_task_execution_role.arn,
    container_definitions=data["template_file"]["td_proxy"]["rendered"])
kong_gateway = aws.ec2.SecurityGroup("kongGateway",
    vpc_id=main_vpc.id,
    ingress=[
        {
            "protocol": "tcp",
            "to_port": var["lb_tcp_http_listen_port"],
            "from_port": var["lb_tcp_http_listen_port"],
            "cidr_blocks": ["0.0.0.0/0"],
            "ipv6_cidr_blocks": ["::/0"],
            "description": "proxy http listener port",
        },
        {
            "protocol": "tcp",
            "from_port": var["lb_tcp_https_listen_port"],
            "to_port": var["lb_tcp_https_listen_port"],
            "cidr_blocks": ["0.0.0.0/0"],
            "ipv6_cidr_blocks": ["::/0"],
            "description": "proxy https listener port",
        },
        {
            "protocol": "tcp",
            "from_port": var["lb_tcp_admin_api_listen_port"],
            "to_port": var["lb_tcp_admin_api_listen_port"],
            "cidr_blocks": ["0.0.0.0/0"],
            "ipv6_cidr_blocks": ["::/0"],
            "description": "proxy admin api listener port",
        },
        {
            "protocol": "tcp",
            "from_port": var["lb_tcp_admin_gui_listen_port"],
            "to_port": var["lb_tcp_admin_gui_listen_port"],
            "cidr_blocks": ["0.0.0.0/0"],
            "ipv6_cidr_blocks": ["::/0"],
            "description": "proxy admin gui listener port",
        },
        {
            "protocol": "tcp",
            "from_port": var["lb_tcp_health_port"],
            "to_port": var["lb_tcp_health_port"],
            "cidr_blocks": ["0.0.0.0/0"],
            "ipv6_cidr_blocks": ["::/0"],
            "description": "status check",
        },
        {
            "protocol": "tcp",
            "from_port": "5432",
            "to_port": "5432",
            "cidr_blocks": ["0.0.0.0/0"],
            "ipv6_cidr_blocks": ["::/0"],
            "description": "status check",
        },
    ],
    egress=[{
        "protocol": "-1",
        "from_port": 0,
        "to_port": 0,
        "cidr_blocks": ["0.0.0.0/0"],
        "ipv6_cidr_blocks": ["::/0"],
    }],
    tags=var["additional_tags"])
pulumi.export("dns", main_load_balancer.dns_name)
name = "Kong4Fargate"
revision = "v00.07.24"
aws_profile = "default"
environment = "dev"
additional_tags = {
    "Name": "Kong4Fargate",
    "ownerName": "usrbinkat",
    "Application": "kong-api-gateway",
    "Revision": "v00.07.23",
    "Environment": "dev",
}
kong_proxy_type = "dbfull"
image_kong_proxy = "quay.io/containercraft/kong:b64lsup-a02-d9eccaa"
kong_log_level = "debug"
kong_pg_port = "5432"
kong_database = "postgres"
kong_pg_user = "rdspostgresql"
kong_pg_host = "db-kong-fargate-dev.ctzjaxtr66nw.us-east-2.rds.amazonaws.com"
kong_pg_password = "rdspostgresql"
kong_pg_database = "kong"
kong_pg_ssl_verify = "off"
region = "us-east-2"
availability_zones = [
    "us-east-2a",
    "us-east-2b",
    "us-east-2c",
]
capabilities = "FARGATE"
cidr = "192.19.0.0/16"
public_subnets = [
    "192.19.11.0/24",
    "192.19.12.0/24",
    "192.19.13.0/24",
]
private_subnets = [
    "192.19.21.0/24",
    "192.19.22.0/24",
    "192.19.23.0/24",
]

