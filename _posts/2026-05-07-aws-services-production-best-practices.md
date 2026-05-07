# AWS云服务生产环境最佳实践：DevOps/SRE云原生架构指南

## 情境与背景

AWS是云原生架构的主流选择，熟练掌握AWS服务是DevOps/SRE工程师的必备技能。本文按类别系统介绍AWS核心服务，并提供生产环境最佳配置示例，帮助读者快速搭建高可用、低成本、安全合规的云原生架构。

## 一、计算服务（Compute）

### 1.1 EC2 弹性计算云服务器

```hcl
# Terraform EC2 配置示例
resource "aws_instance" "web_server" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t3.medium"
  
  subnet_id = aws_subnet.public.id
  
  vpc_security_group_ids = [aws_security_group.web.id]
  
  user_data = file("init.sh")
  
  root_block_device {
    volume_type = "gp3"
    volume_size = 50
    encrypted   = true
  }
  
  tags = {
    Name        = "web-server"
    Environment = "prod"
    ManagedBy   = "terraform"
  }
}

# 自动扩缩容配置
resource "aws_autoscaling_group" "web_asg" {
  vpc_zone_identifier = [aws_subnet.public.id]
  
  min_size         = 3
  max_size         = 10
  desired_capacity = 3
  
  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }
  
  tag {
    key                 = "Name"
    value               = "web-asg"
    propagate_at_launch = true
  }
}
```

**生产要点**：
- 多AZ部署，确保高可用
- 使用ASG自动扩缩容
- 安全组+NACL双层防护
- 启用EBS加密

### 1.2 EKS 弹性Kubernetes服务

```yaml
# EKS NodeGroup配置
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig
metadata:
  name: prod-cluster
  region: ap-northeast-1

managedNodeGroups:
  - name: prod-ng
    instanceType: t3.medium
    desiredCapacity: 3
    minSize: 2
    maxSize: 10
    volumeSize: 100
    volumeType: gp3
    privateNetworking: true
    tags:
      Environment: prod
```

```bash
# 获取EKS集群凭证
aws eks update-kubeconfig --name prod-cluster --region ap-northeast-1

# 查看节点
kubectl get nodes -o wide

# NodeGroup扩缩容
aws eks update-nodegroup-version \
  --cluster-name prod-cluster \
  --nodegroup-name prod-ng \
  --kubernetes-version 1.28
```

### 1.3 Lambda 无服务器计算

```yaml
# Serverless Application Model (SAM) 模板
AWSTemplateFormatVersion: '2010-09-09'
Transform: AWS::Serverless-2016-10-31

Resources:
  LogProcessorFunction:
    Type: AWS::Serverless::Function
    Properties:
      Handler: index.handler
      Runtime: python3.11
      Policies:
        - S3CrudPolicy:
            BucketName: !Ref DataBucket
        - CloudWatchLogsWritePolicy:
            LogGroupName: !Ref LogProcessorLogGroup
      Events:
        S3Event:
          Type: S3
          Properties:
            Bucket: !Ref DataBucket
            Events: s3:ObjectCreated:*
            Filter:
              S3Key:
                Rules:
                  - Name: prefix
                    Value: logs/
```

### 1.4 Fargate 无服务器容器

```yaml
# ECS Fargate任务定义
{
  "family": "my-app",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "256",
  "memory": "512",
  "containerDefinitions": [{
    "name": "my-app",
    "image": "123456789.dkr.ecr.ap-northeast-1.amazonaws.com/my-app:latest",
    "portMappings": [{
      "containerPort": 8080
    }],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "/ecs/my-app",
        "awslogs-region": "ap-northeast-1",
        "awslogs-stream-prefix": "ecs"
      }
    }
  }]
}
```

## 二、网络服务（Networking）

### 2.1 VPC 虚拟私有云

```hcl
# Terraform VPC配置
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = {
    Name = "prod-vpc"
  }
}

# 公有子网（多AZ）
resource "aws_subnet" "public" {
  count = 3
  
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.${count.index + 1}.0.0/24"
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
  
  tags = {
    Name = "public-subnet-${count.index + 1}"
  }
}

# NAT网关（私有子网出向流量）
resource "aws_eip" "nat" {
  domain = "vpc"
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id
  
  tags = {
    Name = "prod-nat"
  }
}

# 私有子网路由表
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }
  
  tags = {
    Name = "private-route-table"
  }
}
```

### 2.2 ELB 负载均衡

```yaml
# ALB(Application Load Balancer)
apiVersion: elbv2.k8s.aws/v1beta1
kind: TargetGroupBinding
metadata:
  name: my-app-tgb
spec:
  serviceRef:
    name: my-app
    port: 8080
  targetGroupARN: arn:aws:elasticloadbalancing:ap-northeast-1:123456:targetgroup/my-tg/xxx
  targetType: ip
```

```bash
# ALB配置
aws elbv2 create-load-balancer \
  --name my-alb \
  --subnets subnet-xxx subnet-yyy \
  --security-groups sg-xxx \
  --scheme internet-facing \
  --type application

# 健康检查配置
aws elbv2 configure-health-check \
  --load-balancer-arn arn:aws:elasticloadbalancing:xxx \
  --health-check Protocol=HTTP,Port=8080,Path=/health,Interval=30,Timeout=5,UnhealthyThreshold=2,HealthyThreshold=2
```

### 2.3 Route53 DNS服务

```yaml
# Route53 托管配置
apiVersion: externaldns.k8s.io/v1alpha1
kind: DNSEndpoint
metadata:
  name: my-app-dns
spec:
  endpoints:
  - dnsName: myapp.example.com
    recordType: A
    targets:
    - "alb-dns-name.elb.amazonaws.com"
    setIdentifier: my-app
    recordTTL: 300

# 健康检查
aws route53 create-health-check \
  --caller-reference $(date +%s) \
  --health-check-config '{"Type":"HTTP","FullyQualifiedDomainName":"myapp.example.com","Port":443,"Path":"/health","RequestInterval":10,"Threshold":3}'
```

### 2.4 CloudFront CDN加速

```yaml
# CloudFront分配配置
resource "aws_cloudfront_distribution" "my_cdn" {
  origin {
    domain_name = "my-app.s3.amazonaws.com"
    origin_id   = "my-s3-origin"
    
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }
  
  enabled             = true
  is_ipv6_enabled     = true
  price_class         = "PriceClass_All"
  
  default_cache_behavior {
    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD", "OPTIONS"]
    
    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }
  
  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = ["CN", "HK", "TW"]
    }
  }
  
  viewer_certificate {
    acm_certificate_arn = "arn:aws:acm:us-east-1:123456:certificate/xxx"
    ssl_support_method  = "sni-only"
  }
}
```

## 三、存储服务（Storage）

### 3.1 S3 对象存储

```hcl
# S3桶配置
resource "aws_s3_bucket" "data_bucket" {
  bucket = "prod-data-bucket"
  
  tags = {
    Environment = "prod"
    ManagedBy   = "terraform"
  }
}

# 启用版本控制
resource "aws_s3_bucket_versioning" "data" {
  bucket = aws_s3_bucket.data_bucket.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

# 生命周期规则
resource "aws_s3_bucket_lifecycle_configuration" "data" {
  bucket = aws_s3_bucket.data_bucket.id
  
  rule {
    id     = "archive-old-data"
    status = "Enabled"
    
    filter {
      prefix = "logs/"
    }
    
    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
    
    transition {
      days          = 90
      storage_class = "GLACIER"
    }
    
    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class  = "STANDARD_IA"
    }
    
    noncurrent_version_expiration {
      noncurrent_days = 365
    }
  }
}

# 跨区域复制
resource "aws_s3_bucket_replication_configuration" "data" {
  bucket = aws_s3_bucket.data_bucket.id
  
  role = aws_iam_role.replication.arn
  
  rule {
    id     = "replicate-to-dr"
    status = "Enabled"
    
    filter {
      prefix = ""
    }
    
    destination {
      bucket        = "arn:aws:s3:::dr-data-bucket"
      storage_class = "STANDARD"
    }
  }
}
```

### 3.2 EBS 弹性块存储

```hcl
# EBS卷配置
resource "aws_ebs_volume" "data" {
  availability_zone = "ap-northeast-1a"
  size              = 100
  type              = "gp3"
  encrypted         = true
  
  tags = {
    Name = "data-volume"
  }
}

# 挂载到EC2
resource "aws_volume_attachment" "data_att" {
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.data.id
  instance_id = aws_instance.web_server.id
}
```

### 3.3 EFS 弹性文件系统

```yaml
# EFS存储类
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: efs-sc
provisioner: efs.csi.aws.com
parameters:
  provisioningMode: efs-ap
  fileSystemId: fs-xxx
  directoryPerms: "755"
  gidRangeStart: "1000"
  gidRangeEnd: "2000"
  basePath: "/dynamic_provisioning"
```

## 四、数据库服务（Database）

### 4.1 RDS 托管关系数据库

```hcl
# RDS Multi-AZ配置
resource "aws_db_instance" "prod_db" {
  identifier           = "prod-mysql"
  engine               = "mysql"
  engine_version        = "8.0"
  instance_class        = "db.t3.medium"
  
  allocated_storage     = 100
  max_allocated_storage = 500
  storage_type          = "gp3"
  storage_encrypted     = true
  
  db_name  = "proddb"
  username = "admin"
  password = data.aws_secretsmanager_secret_version.db_password.secret_string
  
  multi_az               = true
  db_subnet_group_name   = aws_db_subnet_group.prod.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  
  backup_retention_period = 7
  backup_window          = "03:00-04:00"
  maintenance_window      = "mon:04:00-mon:05:00"
  
  enabled_cloudwatch_logs_exports = ["error", "general", "slowquery"]
  
  parameters = {
    max_connections = "500"
    wait_timeout    = "300"
  }
  
  tags = {
    Environment = "prod"
  }
}

# 只读副本
resource "aws_db_instance" "read_replica" {
  identifier           = "prod-db-replica"
  source_db_instance   = aws_db_instance.prod_db.id
  instance_class       = "db.t3.medium"
  publicly_accessible  = false
  
  replica_mode = "opened-replicas"
}
```

### 4.2 ElastiCache Redis

```hcl
# ElastiCache Redis集群
resource "aws_elasticache_replication_group" "prod_redis" {
  replication_group_id       = "prod-redis"
  replication_group_description = "Production Redis Cluster"
  
  engine               = "redis"
  engine_version       = "7.0"
  node_type            = "cache.r6g.large"
  number_cache_clusters = 3
  
  automatic_failover_enabled = true
  multi_az_enabled          = true
  
  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  auth_token_enabled         = true
  
  snapshot_retention_limit   = 7
  snapshot_window           = "03:00-05:00"
  
  maintenance_window = "mon:05:00-mon:07:00"
  
  log_delivery_configuration {
    destination      = aws_cloudwatch_log_group.redis_slow.name
    destination_type = "cloudwatch-logs"
    log_format      = "json"
    log_type        = "slow-log"
  }
}
```

## 五、DevOps与IaC

### 5.1 Terraform 基础设施即代码

```hcl
# Terraform模块化结构
# main.tf
terraform {
  required_version = ">= 1.5.0"
  
  backend "s3" {
    bucket = "tf-state-prod"
    key    = "prod/main.tfstate"
    region = "ap-northeast-1"
    encrypt = true
  }
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# 变量定义
variable "environment" {
  type    = string
  default = "prod"
}

# 输出定义
output "cluster_endpoint" {
  value       = aws_eks_cluster.main.endpoint
  description = "EKS集群端点"
}
```

### 5.2 CodePipeline 原生CI/CD

```yaml
# CodePipeline配置
AWSTemplateFormatVersion: '2010-09-09'
Resources:
  Pipeline:
    Type: AWS::CodePipeline::Pipeline
    Properties:
      RoleArn: !GetAtt CodePipelineRole.Arn
      Stages:
        - Name: Source
          Actions:
            - Name: SourceAction
              ActionTypeId:
                Category: Source
                Owner: AWS
                Provider: CodeCommit
                Version: '1'
              Configuration:
                RepositoryName: my-app
                BranchName: main
                PollForSourceChanges: false
              OutputArtifacts:
                - SourceOutput
        - Name: Build
          Actions:
            - Name: BuildAction
              ActionTypeId:
                Category: Build
                Owner: AWS
                Provider: CodeBuild
                Version: '1'
              Configuration:
                ProjectName: !Ref CodeBuildProject
              InputArtifacts:
                - SourceOutput
              OutputArtifacts:
                - BuildOutput
        - Name: Deploy
          Actions:
            - Name: DeployAction
              ActionTypeId:
                Category: Deploy
                Owner: AWS
                Provider: ECS
                Version: '1'
              Configuration:
                ClusterName: !Ref ECSCluster
                ServiceName: !Ref ECSService
                DeploymentTimeout: 60
              InputArtifacts:
                - BuildOutput
```

## 六、监控与安全

### 6.1 CloudWatch 监控告警

```yaml
# CloudWatch告警配置
resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "prod-cpu-utilization-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "CPU使用率超过80%"
  
  dimensions = {
    InstanceId = aws_instance.web_server.id
  }
  
  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]
}
```

### 6.2 IAM 身份管理

```hcl
# IAM角色和策略
resource "aws_iam_role" "eks_node_role" {
  name = "eks-node-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_node_cni" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "eks_node_worker" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}
```

## 七、面试1分钟标准回答

**完整版（1分钟）**：

我用AWS构建高可用云原生架构，核心用过：
- 计算：**EC2、EKS、Fargate、Lambda**，覆盖虚拟机、K8s容器、无服务器场景；
- 网络：**VPC、ELB、Route53、CloudFront**，做多AZ高可用、全局流量调度与CDN加速；
- 存储：**S3、EBS、EFS**，满足对象、块、文件存储及备份归档；
- 数据库：**RDS、DynamoDB、ElastiCache、MSK**，托管关系型、NoSQL、缓存与消息队列；
- DevOps：用**Terraform/CloudFormation**做IaC，**CodePipeline**搭建CI/CD流水线，配合**SSM/Secrets Manager**管理配置与密钥；
- 监控安全：**CloudWatch、X-Ray、CloudTrail、IAM、KMS**，实现全链路可观测、权限最小化与数据加密；
- 同时通过**Cost Explorer**做成本优化，保障架构稳定、安全、低成本。

**30秒超短版**：

我用AWS做云原生架构：EKS跑K8s集群，VPC+ELB+Route53做高可用，S3+EFS做存储，RDS+ElastiCache做数据层，Terraform做IaC，CodePipeline做CI/CD，CloudWatch+IAM做监控安全。

---

## 八、总结

### 8.1 AWS服务速查表

| 类别 | 服务 | 核心用途 |
|:----:|------|---------|
| **计算** | EC2 | 虚拟机部署应用 |
| **计算** | EKS | K8s生产集群 |
| **计算** | Lambda | 无服务器计算 |
| **计算** | Fargate | 无服务器容器 |
| **网络** | VPC | 私有网络规划 |
| **网络** | ELB | 负载均衡 |
| **网络** | Route53 | DNS+GSLB |
| **网络** | CloudFront | CDN加速 |
| **存储** | S3 | 对象存储+备份 |
| **存储** | EBS | 块存储 |
| **存储** | EFS | 文件存储 |
| **数据库** | RDS | 托管MySQL/PG |
| **数据库** | DynamoDB | NoSQL数据库 |
| **数据库** | ElastiCache | Redis缓存 |
| **DevOps** | Terraform | IaC基础设施 |
| **DevOps** | CodePipeline | CI/CD流水线 |
| **监控** | CloudWatch | 监控告警 |
| **安全** | IAM | 权限管理 |
| **安全** | KMS | 密钥管理 |

### 8.2 AWS口诀

```
计算EC2/EKSLambda，网络VPC/ELB/53/Front
存储S3三剑客，数据库RDS缓存DynamoDB
DevOps用Terraform，监控CloudWatch加IAM
```

> **参考链接**：[SRE运维面试题全解析：从理论到实践（第二部分）]({% post_url 2026-04-15-sre-interview-questions-part2 %})