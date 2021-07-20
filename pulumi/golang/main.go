package main

import (
	"fmt"

	"github.com/pulumi/pulumi-aws/sdk/v3/go/aws/cloudwatch"
	"github.com/pulumi/pulumi-aws/sdk/v3/go/aws/ec2"
	"github.com/pulumi/pulumi-aws/sdk/v3/go/aws/ecs"
	"github.com/pulumi/pulumi-aws/sdk/v3/go/aws/iam"
	"github.com/pulumi/pulumi-aws/sdk/v4/go/aws/s3"
	"github.com/pulumi/pulumi-aws/sdk/v3/go/aws/lb"
	"github.com/pulumi/pulumi/sdk/v2/go/pulumi"
)

func main() {
	pulumi.Run(func(ctx *pulumi.Context) error {
		// Create an AWS resource (S3 Bucket)
		bucket, err := s3.NewBucket(ctx, "my-bucket", nil)
		if err != nil {
			return err
		}

		// Export the name of the bucket
		ctx.Export("bucketName", bucket.ID())
		return nil
		mainVpc, err := ec2.NewVpc(ctx, "mainVpc", &ec2.VpcArgs{
			CidrBlock: pulumi.Any(_var.Cidr),
			Tags:      _var.Additional_tags,
		})
		if err != nil {
			return err
		}
		mainInternetGateway, err := ec2.NewInternetGateway(ctx, "mainInternetGateway", &ec2.InternetGatewayArgs{
			VpcId: mainVpc.ID(),
			Tags:  _var.Additional_tags,
		})
		if err != nil {
			return err
		}
		publicRouteTable, err := ec2.NewRouteTable(ctx, "publicRouteTable", &ec2.RouteTableArgs{
			VpcId: mainVpc.ID(),
			Tags:  _var.Additional_tags,
		})
		if err != nil {
			return err
		}
		mainLoadBalancer, err := lb.NewLoadBalancer(ctx, "mainLoadBalancer", &lb.LoadBalancerArgs{
			Tags:             _var.Additional_tags,
			Subnets:          aws_subnet.Public.Id,
			LoadBalancerType: pulumi.String("network"),
			Internal:         pulumi.Bool(false),
		})
		if err != nil {
			return err
		}
		ctx.Export("dns", mainLoadBalancer.DnsName)
		_, err = ec2.NewSecurityGroup(ctx, "kongGateway", &ec2.SecurityGroupArgs{
			VpcId: mainVpc.ID(),
			Ingress: ec2.SecurityGroupIngressArray{
				&ec2.SecurityGroupIngressArgs{
					Protocol: pulumi.String("tcp"),
					ToPort:   pulumi.Any(_var.Lb_tcp_http_listen_port),
					FromPort: pulumi.Any(_var.Lb_tcp_http_listen_port),
					CidrBlocks: pulumi.StringArray{
						pulumi.String("0.0.0.0/0"),
					},
					Ipv6CidrBlocks: pulumi.StringArray{
						pulumi.String("::/0"),
					},
					Description: pulumi.String("proxy http listener port"),
				},
				&ec2.SecurityGroupIngressArgs{
					Protocol: pulumi.String("tcp"),
					FromPort: pulumi.Any(_var.Lb_tcp_https_listen_port),
					ToPort:   pulumi.Any(_var.Lb_tcp_https_listen_port),
					CidrBlocks: pulumi.StringArray{
						pulumi.String("0.0.0.0/0"),
					},
					Ipv6CidrBlocks: pulumi.StringArray{
						pulumi.String("::/0"),
					},
					Description: pulumi.String("proxy https listener port"),
				},
				&ec2.SecurityGroupIngressArgs{
					Protocol: pulumi.String("tcp"),
					FromPort: pulumi.Any(_var.Lb_tcp_admin_api_listen_port),
					ToPort:   pulumi.Any(_var.Lb_tcp_admin_api_listen_port),
					CidrBlocks: pulumi.StringArray{
						pulumi.String("0.0.0.0/0"),
					},
					Ipv6CidrBlocks: pulumi.StringArray{
						pulumi.String("::/0"),
					},
					Description: pulumi.String("proxy admin api listener port"),
				},
				&ec2.SecurityGroupIngressArgs{
					Protocol: pulumi.String("tcp"),
					FromPort: pulumi.Any(_var.Lb_tcp_admin_gui_listen_port),
					ToPort:   pulumi.Any(_var.Lb_tcp_admin_gui_listen_port),
					CidrBlocks: pulumi.StringArray{
						pulumi.String("0.0.0.0/0"),
					},
					Ipv6CidrBlocks: pulumi.StringArray{
						pulumi.String("::/0"),
					},
					Description: pulumi.String("proxy admin gui listener port"),
				},
				&ec2.SecurityGroupIngressArgs{
					Protocol: pulumi.String("tcp"),
					FromPort: pulumi.Any(_var.Lb_tcp_health_port),
					ToPort:   pulumi.Any(_var.Lb_tcp_health_port),
					CidrBlocks: pulumi.StringArray{
						pulumi.String("0.0.0.0/0"),
					},
					Ipv6CidrBlocks: pulumi.StringArray{
						pulumi.String("::/0"),
					},
					Description: pulumi.String("status check"),
				},
				&ec2.SecurityGroupIngressArgs{
					Protocol: pulumi.String("tcp"),
					FromPort: pulumi.Int(5432),
					ToPort:   pulumi.Int(5432),
					CidrBlocks: pulumi.StringArray{
						pulumi.String("0.0.0.0/0"),
					},
					Ipv6CidrBlocks: pulumi.StringArray{
						pulumi.String("::/0"),
					},
					Description: pulumi.String("status check"),
				},
			},
			Egress: ec2.SecurityGroupEgressArray{
				&ec2.SecurityGroupEgressArgs{
					Protocol: pulumi.String("-1"),
					FromPort: pulumi.Int(0),
					ToPort:   pulumi.Int(0),
					CidrBlocks: pulumi.StringArray{
						pulumi.String("0.0.0.0/0"),
					},
					Ipv6CidrBlocks: pulumi.StringArray{
						pulumi.String("::/0"),
					},
				},
			},
			Tags: _var.Additional_tags,
		})
		if err != nil {
			return err
		}
		kongAdminGuiTargetGroup, err := lb.NewTargetGroup(ctx, "kongAdminGuiTargetGroup", &lb.TargetGroupArgs{
			Tags:       _var.Additional_tags,
			VpcId:      mainVpc.ID(),
			Port:       pulumi.Any(_var.Lb_tcp_admin_gui_listen_port),
			Protocol:   pulumi.String("TCP"),
			TargetType: pulumi.String("ip"),
			HealthCheck: &lb.TargetGroupHealthCheckArgs{
				Port:               pulumi.Any(_var.Lb_tcp_health_port),
				Protocol:           pulumi.String("TCP"),
				Enabled:            pulumi.Bool(true),
				Interval:           pulumi.Int(30),
				HealthyThreshold:   pulumi.Int(3),
				UnhealthyThreshold: pulumi.Int(3),
			},
		}, pulumi.DependsOn([]pulumi.Resource{
			mainLoadBalancer,
		}))
		if err != nil {
			return err
		}
		ecsTaskExecutionRole, err := iam.NewRole(ctx, "ecsTaskExecutionRole", &iam.RoleArgs{
			AssumeRolePolicy: pulumi.String(fmt.Sprintf("%v%v%v%v%v%v%v%v%v%v%v%v%v", "{\n", " \"Version\": \"2012-10-17\",\n", " \"Statement\": [\n", "   {\n", "     \"Action\": \"sts:AssumeRole\",\n", "     \"Principal\": {\n", "       \"Service\": \"ecs-tasks.amazonaws.com\"\n", "     },\n", "     \"Effect\": \"Allow\",\n", "     \"Sid\": \"\"\n", "   }\n", " ]\n", "}\n")),
		})
		if err != nil {
			return err
		}
		_, err = ecs.NewTaskDefinition(ctx, "mainTaskDefinition", &ecs.TaskDefinitionArgs{
			Family:               pulumi.String("kong-api-gateway"),
			NetworkMode:          pulumi.String("awsvpc"),
			Cpu:                  pulumi.String("256"),
			Memory:               pulumi.String("1024"),
			ExecutionRoleArn:     ecsTaskExecutionRole.Arn,
			ContainerDefinitions: pulumi.Any(_var.Container_definition),
		})
		if err != nil {
			return err
		}
		kongAdminApiTargetGroup, err := lb.NewTargetGroup(ctx, "kongAdminApiTargetGroup", &lb.TargetGroupArgs{
			Tags:       _var.Additional_tags,
			VpcId:      mainVpc.ID(),
			Port:       pulumi.Any(_var.Lb_tcp_admin_api_listen_port),
			Protocol:   pulumi.String("TCP"),
			TargetType: pulumi.String("ip"),
			HealthCheck: &lb.TargetGroupHealthCheckArgs{
				Port:               pulumi.Any(_var.Lb_tcp_health_port),
				Protocol:           pulumi.String("TCP"),
				Enabled:            pulumi.Bool(true),
				Interval:           pulumi.Int(30),
				HealthyThreshold:   pulumi.Int(3),
				UnhealthyThreshold: pulumi.Int(3),
			},
		}, pulumi.DependsOn([]pulumi.Resource{
			mainLoadBalancer,
		}))
		if err != nil {
			return err
		}
		_, err = lb.NewListener(ctx, "kongAdminGuiListener", &lb.ListenerArgs{
			Port:            pulumi.Any(_var.Lb_tcp_admin_gui_listen_port),
			Protocol:        pulumi.String("TCP"),
			LoadBalancerArn: mainLoadBalancer.Arn,
			DefaultActions: lb.ListenerDefaultActionArray{
				&lb.ListenerDefaultActionArgs{
					Type:           pulumi.String("forward"),
					TargetGroupArn: kongAdminGuiTargetGroup.Arn,
				},
			},
		})
		if err != nil {
			return err
		}
		kongHttpsTargetGroup, err := lb.NewTargetGroup(ctx, "kongHttpsTargetGroup", &lb.TargetGroupArgs{
			Tags:       _var.Additional_tags,
			VpcId:      mainVpc.ID(),
			Port:       pulumi.Any(_var.Lb_tcp_https_listen_port),
			Protocol:   pulumi.String("TCP"),
			TargetType: pulumi.String("ip"),
			HealthCheck: &lb.TargetGroupHealthCheckArgs{
				Port:               pulumi.Any(_var.Lb_tcp_health_port),
				Protocol:           pulumi.String("TCP"),
				Enabled:            pulumi.Bool(true),
				Interval:           pulumi.Int(30),
				HealthyThreshold:   pulumi.Int(3),
				UnhealthyThreshold: pulumi.Int(3),
			},
		}, pulumi.DependsOn([]pulumi.Resource{
			mainLoadBalancer,
		}))
		if err != nil {
			return err
		}
		_, err = lb.NewListener(ctx, "kongAdminApiListener", &lb.ListenerArgs{
			Port:            pulumi.Any(_var.Lb_tcp_admin_api_listen_port),
			Protocol:        pulumi.String("TCP"),
			LoadBalancerArn: mainLoadBalancer.Arn,
			DefaultActions: lb.ListenerDefaultActionArray{
				&lb.ListenerDefaultActionArgs{
					Type:           pulumi.String("forward"),
					TargetGroupArn: kongAdminApiTargetGroup.Arn,
				},
			},
		})
		if err != nil {
			return err
		}
		kongHttpTargetGroup, err := lb.NewTargetGroup(ctx, "kongHttpTargetGroup", &lb.TargetGroupArgs{
			Tags:       _var.Additional_tags,
			VpcId:      mainVpc.ID(),
			Port:       pulumi.Any(_var.Lb_tcp_http_listen_port),
			Protocol:   pulumi.String("TCP"),
			TargetType: pulumi.String("ip"),
			HealthCheck: &lb.TargetGroupHealthCheckArgs{
				Port:               pulumi.Any(_var.Lb_tcp_health_port),
				Enabled:            pulumi.Bool(true),
				Protocol:           pulumi.String("TCP"),
				Interval:           pulumi.Int(30),
				HealthyThreshold:   pulumi.Int(3),
				UnhealthyThreshold: pulumi.Int(3),
			},
		}, pulumi.DependsOn([]pulumi.Resource{
			mainLoadBalancer,
		}))
		if err != nil {
			return err
		}
		_, err = lb.NewListener(ctx, "kongHttpsListener", &lb.ListenerArgs{
			Port:            pulumi.Int(443),
			Protocol:        pulumi.String("TCP"),
			LoadBalancerArn: mainLoadBalancer.Arn,
			DefaultActions: lb.ListenerDefaultActionArray{
				&lb.ListenerDefaultActionArgs{
					Type:           pulumi.String("forward"),
					TargetGroupArn: kongHttpsTargetGroup.Arn,
				},
			},
		}, pulumi.DependsOn([]pulumi.Resource{
			kongHttpsTargetGroup,
		}))
		if err != nil {
			return err
		}
		_, err = iam.NewRolePolicyAttachment(ctx, "ecs_task_execution_role_policy_attachment", &iam.RolePolicyAttachmentArgs{
			Role:      ecsTaskExecutionRole.Name,
			PolicyArn: pulumi.String("arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"),
		})
		if err != nil {
			return err
		}
		_, err = cloudwatch.NewLogGroup(ctx, "mainLogGroup", nil)
		if err != nil {
			return err
		}
		_, err = lb.NewListener(ctx, "kongHttpListener", &lb.ListenerArgs{
			Port:            pulumi.Int(80),
			Protocol:        pulumi.String("TCP"),
			LoadBalancerArn: mainLoadBalancer.Arn,
			DefaultActions: lb.ListenerDefaultActionArray{
				&lb.ListenerDefaultActionArgs{
					Type:           pulumi.String("forward"),
					TargetGroupArn: kongHttpTargetGroup.Arn,
				},
			},
		}, pulumi.DependsOn([]pulumi.Resource{
			kongHttpTargetGroup,
		}))
		if err != nil {
			return err
		}
		_ := "Kong4Fargate"
		_ := "v00.07.24"
		_ := "default"
		_ := "dev"
		_ := map[string]interface{}{
			"Name":        "Kong4Fargate",
			"ownerName":   "usrbinkat",
			"Application": "kong-api-gateway",
			"Revision":    "v00.07.23",
			"Environment": "dev",
		}
		_, err = ecs.NewCluster(ctx, "mainCluster", &ecs.ClusterArgs{
			CapacityProviders: pulumi.StringArray{
				pulumi.String("FARGATE_SPOT"),
				pulumi.String("FARGATE"),
			},
			DefaultCapacityProviderStrategies: ecs.ClusterDefaultCapacityProviderStrategyArray{
				&ecs.ClusterDefaultCapacityProviderStrategyArgs{
					CapacityProvider: pulumi.String("FARGATE_SPOT"),
				},
			},
			Settings: ecs.ClusterSettingArray{
				&ecs.ClusterSettingArgs{
					Name:  pulumi.String("containerInsights"),
					Value: pulumi.String("disabled"),
				},
			},
			Tags: _var.Additional_tags,
		})
		if err != nil {
			return err
		}
		_, err = ec2.NewRoute(ctx, "private", &ec2.RouteArgs{
			RouteTableId:         pulumi.Any(_var.Aws_route_table.Private[0].Id),
			DestinationCidrBlock: pulumi.String("0.0.0.0/0"),
			NatGatewayId:         pulumi.Any(_var.Aws_nat_gateway.Main[0].Id),
		})
		if err != nil {
			return err
		}
		_, err = ec2.NewRoute(ctx, "publicRoute", &ec2.RouteArgs{
			RouteTableId:         publicRouteTable.ID(),
			DestinationCidrBlock: pulumi.String("0.0.0.0/0"),
			GatewayId:            mainInternetGateway.ID(),
		})
		if err != nil {
			return err
		}
		_ := "us-east-2"
		_ := []string{
			"us-east-2a",
			"us-east-2b",
			"us-east-2c",
		}
		_ := "FARGATE"
		_ := "192.19.0.0/16"
		_ := []string{
			"192.19.11.0/24",
			"192.19.12.0/24",
			"192.19.13.0/24",
		}
		_ := []string{
			"192.19.21.0/24",
			"192.19.22.0/24",
			"192.19.23.0/24",
		}
		_ := "debug"
		_ := "5432"
		_ := "postgres"
		_ := "rdspostgresql"
		_ := "db-kong-fargate-dev.ctzjaxtr66nw.us-east-2.rds.amazonaws.com"
		_ := "rdspostgresql"
		_ := "kong"
		_ := "off"
		_ := "dbfull"
		_ := "quay.io/containercraft/kong:b64lsup-a02-d9eccaa"
		return nil
	})
}

