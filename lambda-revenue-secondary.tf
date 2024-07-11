
module "Create_Revenue_Table_secondary" {
  source = "terraform-aws-modules/lambda/aws"
  layers = [ aws_lambda_layer_version.lambda_layer_sec.arn, "arn:aws:lambda:${var.region2}:580247275435:layer:LambdaInsightsExtension:21" ]

  providers = {
    aws = aws.region2
  }

  function_name = "Create_Revenue_Table_secondary"
  handler       = "api.revenue_codes"
  runtime       = "python3.8"
  architectures = ["x86_64"]
  timeout       = 900
  tracing_mode  = "Active"
  publish       = true
  store_on_s3   = false
  memory_size   = 1024

  source_path = "${path.module}/src/EventBridgeApi/"

  vpc_subnet_ids = module.vpc_secondary.private_subnets
  vpc_security_group_ids = [module.LambdaSecurityGroup_secondary.security_group_id]

   attach_policies    = true
   policies           = ["arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole", "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"]
   number_of_policies = 2

   attach_policy_statements = true
   policy_statements = {
     secrets_manager = {
      effect = "Allow"
      actions = [
        "secretsmanager:GetSecretValue"
      ]
      resources = ["*"]
     }
   }
}



module "Create_Revenue_Item_secondary" {
  source = "terraform-aws-modules/lambda/aws"
  layers = [ aws_lambda_layer_version.lambda_layer_sec.arn, "arn:aws:lambda:${var.region2}:580247275435:layer:LambdaInsightsExtension:21" ]
  providers = {
    aws = aws.region2
  }

  event_source_mapping = {
    sqs = {
      function_response_types = ["ReportBatchItemFailures"]
      event_source_arn = aws_sqs_queue.queue_secondary.arn
    }
  }

  allowed_triggers = {
    sqs = {
      principal  = "sqs.amazonaws.com"
      source_arn = aws_sqs_queue.queue_secondary.arn
    }
  }

  function_name = "Create_Revenue_Item_secondary"
  handler       = "api.create_item"
  runtime       = "python3.8"
  architectures = ["x86_64"]
  timeout       = 60
  tracing_mode  = "Active"
  publish       = true
  store_on_s3   = false
  memory_size   = 1024

  source_path = "${path.module}/src/EventBridgeApi/"

  vpc_subnet_ids = module.vpc_secondary.private_subnets
  vpc_security_group_ids = [module.LambdaSecurityGroup_secondary.security_group_id]

   attach_policies    = true
   policies           = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole", 
    "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole",
    "arn:aws:iam::aws:policy/service-role/AWSLambdaSQSQueueExecutionRole"
    ]
   number_of_policies = 3

   attach_policy_statements = true
   policy_statements = {
     secrets_manager = {
      effect = "Allow"
      actions = [
        "secretsmanager:GetSecretValue"
      ]
      resources = ["*"]
     }
   }
}


module "Get_Revenue_Item_secondary" {
  source = "terraform-aws-modules/lambda/aws"
  layers = [ aws_lambda_layer_version.lambda_layer_sec.arn, "arn:aws:lambda:${var.region2}:580247275435:layer:LambdaInsightsExtension:21" ]
  providers = {
    aws = aws.region2
  }

  function_name = "Get_Revenue_Item_secondary"
  handler       = "api.get_item"
  runtime       = "python3.8"
  architectures = ["x86_64"]
  timeout       = 900
  tracing_mode  = "Active"
  publish       = true
  store_on_s3   = false
  memory_size   = 1024

  source_path = "${path.module}/src/EventBridgeApi/"

  vpc_subnet_ids = module.vpc_secondary.private_subnets
  vpc_security_group_ids = [module.LambdaSecurityGroup_secondary.security_group_id]

   attach_policies    = true
   policies           = ["arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole", "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"]
   number_of_policies = 2

   attach_policy_statements = true
   policy_statements = {
     secrets_manager = {
      effect = "Allow"
      actions = [
        "secretsmanager:GetSecretValue"
      ]
      resources = ["*"]
     }
   }
}
