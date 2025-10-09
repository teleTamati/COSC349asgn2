provider "aws" {
  region = var.aws_region
}

# Security Groups
resource "aws_security_group" "allow_ssh" {
  name        = "tasktracker_ssh"
  description = "Allow SSH access"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "allow_web" {
  name        = "tasktracker_web"
  description = "Allow HTTP and HTTPS traffic"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "allow_mysql" {
  name        = "tasktracker_mysql"
  description = "Allow MySQL access"

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]  # Private networks only
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# EC2 Instances
resource "aws_instance" "frontend_server" {
  ami           = "ami-0360c520857e3138f"
  instance_type = "t2.micro"
  key_name      = var.key_pair_name 

  vpc_security_group_ids = [
    aws_security_group.allow_ssh.id,
    aws_security_group.allow_web.id
  ]

  user_data = templatefile("${path.module}/build-frontend-vm.tpl", {
    api_server_ip = aws_instance.api_server.public_ip
  })

  tags = {
    Name = "TaskTracker-Frontend"
  }
}

resource "aws_instance" "api_server" {
  ami           = "ami-0360c520857e3138f"
  instance_type = "t2.micro"
  key_name      = var.key_pair_name

  vpc_security_group_ids = [
    aws_security_group.allow_ssh.id,
    aws_security_group.allow_web.id
  ]

  user_data = templatefile("${path.module}/build-api-vm.tpl", {
    database_server_private_ip = aws_instance.database_server.private_ip
  })

  tags = {
    Name = "TaskTracker-API"
  }
}

resource "aws_instance" "database_server" {
  ami           = "ami-0360c520857e3138f"
  instance_type = "t2.micro"
  key_name      = var.key_pair_name

  vpc_security_group_ids = [
    aws_security_group.allow_ssh.id,
    aws_security_group.allow_mysql.id
  ]

  user_data = templatefile("${path.module}/build-database-vm.tpl", {})

  tags = {
    Name = "TaskTracker-Database"
  }
}

# Outputs
output "frontend_server_ip" {
  value = aws_instance.frontend_server.public_ip
}

output "api_server_ip" {
  value = aws_instance.api_server.public_ip
}

output "database_server_ip" {
  value = aws_instance.database_server.public_ip
}

# Variables for portability
variable "key_pair_name" {
  description = "AWS Key Pair name"
  default     = "Assignment2-task"
}

variable "aws_region" {
  description = "AWS Region"
  default     = "us-east-1"
}

# CloudWatch Dashboard with comprehensive monitoring
resource "aws_cloudwatch_dashboard" "task_tracker" {
  dashboard_name = "TaskTracker-Monitoring"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/EC2", "CPUUtilization", "InstanceId", aws_instance.frontend_server.id],
            ["AWS/EC2", "CPUUtilization", "InstanceId", aws_instance.api_server.id],
            ["AWS/EC2", "CPUUtilization", "InstanceId", aws_instance.database_server.id]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "EC2 CPU Utilization"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/EC2", "NetworkIn", "InstanceId", aws_instance.frontend_server.id],
            ["AWS/EC2", "NetworkOut", "InstanceId", aws_instance.frontend_server.id],
            ["AWS/EC2", "NetworkIn", "InstanceId", aws_instance.api_server.id],
            ["AWS/EC2", "NetworkOut", "InstanceId", aws_instance.api_server.id]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "Network Traffic"
          period  = 300
        }
      }
    ]
  })
}

# CloudWatch Alarms for monitoring
resource "aws_cloudwatch_metric_alarm" "high_cpu_frontend" {
  alarm_name          = "tasktracker-frontend-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors frontend server cpu utilization"

  dimensions = {
    InstanceId = aws_instance.frontend_server.id
  }
}

resource "aws_cloudwatch_metric_alarm" "high_cpu_api" {
  alarm_name          = "tasktracker-api-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors api server cpu utilization"

  dimensions = {
    InstanceId = aws_instance.api_server.id
  }
}

resource "aws_cloudwatch_metric_alarm" "high_cpu_database" {
  alarm_name          = "tasktracker-database-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors database server cpu utilization"

  dimensions = {
    InstanceId = aws_instance.database_server.id
  }
}

# CloudWatch Dashboard URL
output "cloudwatch_dashboard_url" {
  value = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${aws_cloudwatch_dashboard.task_tracker.dashboard_name}"
}

output "cloudwatch_alarms_url" {
  value = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#alarmsV2:"
}
