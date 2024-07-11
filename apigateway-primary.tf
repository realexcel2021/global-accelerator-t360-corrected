resource "aws_api_gateway_rest_api" "my_api" {
  name = "t360-rest-api"
  description = "rest api"

  endpoint_configuration {
    types = ["PRIVATE"]
    vpc_endpoint_ids = [module.endpoints.endpoints["api_gateway"].id]
  }
}

resource "aws_api_gateway_rest_api_policy" "this" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  policy      = data.aws_iam_policy_document.apigateway_access.json
}

resource "aws_api_gateway_deployment" "deployment" {
  depends_on = [
    aws_api_gateway_integration.demo,
    aws_api_gateway_method.demo,
    aws_api_gateway_rest_api_policy.this
  ]

  lifecycle {
    create_before_destroy = true
  }

triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.demo,
      aws_api_gateway_integration.demo,
      aws_api_gateway_rest_api_policy.this,


      aws_api_gateway_method.ApiGatewayMethodCreateRemittanceTable_options,
      aws_api_gateway_method.ApiGatewayMethodCreateRemittanceTable,
      aws_api_gateway_integration.ApiGatewayMethodCreateRemittanceTable,
      aws_api_gateway_integration.ApiGatewayMethodCreateRemittanceTable_options,

      aws_api_gateway_method.ApiGatewayMethodGetRemittances,
      aws_api_gateway_method.ApiGatewayMethodGetRemittances_options,
      aws_api_gateway_integration.ApiGatewayMethodGetRemittances_options,
      aws_api_gateway_integration.ApiGatewayMethodGetRemittances,

      aws_api_gateway_method.ResourceCreateRemittance,
      aws_api_gateway_method.ResourceCreateRemittance_options,
      aws_api_gateway_integration.ResourceCreateRemittance,
      aws_api_gateway_integration.ResourceCreateRemittance_options,

      aws_api_gateway_method.ApiGatewayMethodCreateRevenueTable,
      aws_api_gateway_method.ApiGatewayMethodCreateRevenueTable_options,
      aws_api_gateway_integration.ApiGatewayMethodCreateRevenueTable,
      aws_api_gateway_integration.ApiGatewayMethodCreateRevenueTable_options,

      aws_api_gateway_method.ApiGatewayMethodCreateRevenueItem,
      aws_api_gateway_method.ApiGatewayMethodCreateRevenueItem_options,
      aws_api_gateway_integration.ApiGatewayMethodCreateRevenueItem,
      aws_api_gateway_integration.ApiGatewayMethodCreateRevenueItem_options,

      aws_api_gateway_method.ApiGatewayMethodGetRevenueItem,
      aws_api_gateway_method.ApiGatewayMethodGetRevenueItem_options,
      aws_api_gateway_integration.ApiGatewayMethodGetRevenueItem,
      aws_api_gateway_integration.ApiGatewayMethodGetRevenueItem_options,

      aws_api_gateway_method.ApiGatewayMethodUploadImagePublic,
      aws_api_gateway_method.ApiGatewayMethodUploadImagePublic_options,
      aws_api_gateway_integration.ApiGatewayMethodUploadImagePublic,
      aws_api_gateway_integration.ApiGatewayMethodUploadImagePublic_options,

      aws_api_gateway_method.ApiGatewayMethodUploadImagePrivate,
      aws_api_gateway_method.ApiGatewayMethodUploadImagePrivate_options,
      aws_api_gateway_integration.ApiGatewayMethodUploadImagePrivate,
      aws_api_gateway_integration.ApiGatewayMethodUploadImagePrivate_options,



    ]))
  }

  rest_api_id = aws_api_gateway_rest_api.my_api.id
}

resource "aws_api_gateway_domain_name" "this" {
  regional_certificate_arn = var.acm_certificate_arn_primary
  domain_name     = "${var.domain_name}"
  endpoint_configuration {
    types = ["REGIONAL"]
  }
  
}

resource "aws_api_gateway_base_path_mapping" "this" {
  api_id      = aws_api_gateway_rest_api.my_api.id
  stage_name  = aws_api_gateway_stage.this.stage_name
  domain_name = aws_api_gateway_domain_name.this.domain_name

  depends_on = [ aws_api_gateway_deployment.deployment ]
}

resource "aws_api_gateway_stage" "this" {
  deployment_id = aws_api_gateway_deployment.deployment.id
  rest_api_id   = aws_api_gateway_rest_api.my_api.id
  stage_name    = "dev"
}

##########################################
# Get region method
##########################################

resource "aws_api_gateway_resource" "demo" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  parent_id = aws_api_gateway_rest_api.my_api.root_resource_id
  path_part = "get-region"
}

resource "aws_api_gateway_method" "demo" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  resource_id = aws_api_gateway_resource.demo.id
  http_method = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "demo" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  resource_id = aws_api_gateway_resource.demo.id
  http_method = aws_api_gateway_method.demo.http_method
  integration_http_method = "POST"
  type = "AWS_PROXY"
  uri = "${module.lambda_primary.lambda_function_invoke_arn}"  
  credentials = module.apigateway_put_events_to_lambda_us_east_1.iam_role_arn
}

resource "aws_api_gateway_method_response" "demo" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  resource_id = aws_api_gateway_resource.demo.id
  http_method = aws_api_gateway_method.demo.http_method
  status_code = "200"

  //cors section
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Origin" = true
  }

}

resource "aws_api_gateway_integration_response" "demo" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  resource_id = aws_api_gateway_resource.demo.id
  http_method = aws_api_gateway_method.demo.http_method
  status_code = aws_api_gateway_method_response.demo.status_code


  //cors
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" =  "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS,POST,PUT'",
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
}

  depends_on = [
    aws_api_gateway_method.demo,
    aws_api_gateway_integration.demo
  ]
}

##########################################
# create remmitance table method
##########################################

resource "aws_api_gateway_resource" "ApiGatewayMethodCreateRemittanceTable" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  parent_id = aws_api_gateway_rest_api.my_api.root_resource_id
  path_part = "create-tickets-table"
}

resource "aws_api_gateway_method" "ApiGatewayMethodCreateRemittanceTable_options" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  resource_id = aws_api_gateway_resource.ApiGatewayMethodCreateRemittanceTable.id
  http_method = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "ApiGatewayMethodCreateRemittanceTable" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  resource_id = aws_api_gateway_resource.ApiGatewayMethodCreateRemittanceTable.id
  http_method = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_method_settings" "this" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  stage_name  = aws_api_gateway_stage.this.stage_name
  method_path = "*/*"

  settings {
    metrics_enabled = false
    logging_level   = "OFF"
  }
}

resource "aws_api_gateway_integration" "ApiGatewayMethodCreateRemittanceTable" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  resource_id = aws_api_gateway_resource.ApiGatewayMethodCreateRemittanceTable.id
  http_method = aws_api_gateway_method.ApiGatewayMethodCreateRemittanceTable.http_method
  integration_http_method = "POST"
  type = "AWS_PROXY"
  uri = "${module.CreateRemittanceTableLambdaFunction.lambda_function_invoke_arn}"  
  credentials = module.apigateway_put_events_to_lambda_us_east_1.iam_role_arn
}

resource "aws_api_gateway_integration" "ApiGatewayMethodCreateRemittanceTable_options" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  resource_id = aws_api_gateway_resource.ApiGatewayMethodCreateRemittanceTable.id
  http_method = aws_api_gateway_method.ApiGatewayMethodCreateRemittanceTable_options.http_method
  type = "MOCK"
  passthrough_behavior = "WHEN_NO_MATCH"

  request_templates = {
    "application/json" = jsonencode({statusCode = 200})
  }
}

resource "aws_api_gateway_method_response" "ApiGatewayMethodCreateRemittanceTable_options" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  resource_id = aws_api_gateway_resource.ApiGatewayMethodCreateRemittanceTable.id
  http_method = aws_api_gateway_method.ApiGatewayMethodCreateRemittanceTable_options.http_method
  status_code = "200"


  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = false,
    "method.response.header.Access-Control-Allow-Methods" = false,
    "method.response.header.Access-Control-Allow-Origin" = false
  }
}

resource "aws_api_gateway_method_response" "ApiGatewayMethodCreateRemittanceTable" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  resource_id = aws_api_gateway_resource.ApiGatewayMethodCreateRemittanceTable.id
  http_method = aws_api_gateway_method.ApiGatewayMethodCreateRemittanceTable.http_method
  status_code = "200"


  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = false,
    "method.response.header.Access-Control-Allow-Methods" = false,
    "method.response.header.Access-Control-Allow-Origin" = false
  }
}

resource "aws_api_gateway_integration_response" "ApiGatewayMethodCreateRemittanceTable" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  resource_id = aws_api_gateway_resource.ApiGatewayMethodCreateRemittanceTable.id
  http_method = aws_api_gateway_method.ApiGatewayMethodCreateRemittanceTable_options.http_method
  status_code = aws_api_gateway_method_response.ApiGatewayMethodCreateRemittanceTable_options.status_code
  

  depends_on = [
    aws_api_gateway_method.ApiGatewayMethodCreateRemittanceTable,
    aws_api_gateway_integration.ApiGatewayMethodCreateRemittanceTable_options
  ]

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" =  "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS,POST,PUT'",
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
  }

}

resource "aws_api_gateway_integration_response" "ApiGatewayMethodCreateRemittanceTable_get" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  resource_id = aws_api_gateway_resource.ApiGatewayMethodCreateRemittanceTable.id
  http_method = aws_api_gateway_method.ApiGatewayMethodCreateRemittanceTable.http_method
  status_code = aws_api_gateway_method_response.ApiGatewayMethodCreateRemittanceTable.status_code
  

  depends_on = [
    aws_api_gateway_method.ApiGatewayMethodCreateRemittanceTable,
    aws_api_gateway_integration.ApiGatewayMethodCreateRemittanceTable
  ]

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" =  "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS,POST,PUT'",
    "method.response.header.Access-Control-Allow-Origin" = "'*'",
  }
}

###########################################
# Get remittance 
############################################

resource "aws_api_gateway_resource" "ApiGatewayMethodGetRemittances" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  parent_id = aws_api_gateway_rest_api.my_api.root_resource_id
  path_part = "get-tickets"
}

resource "aws_api_gateway_method" "ApiGatewayMethodGetRemittances_options" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  resource_id = aws_api_gateway_resource.ApiGatewayMethodGetRemittances.id
  http_method = "OPTIONS"
  authorization = "NONE"
  api_key_required = false
}

resource "aws_api_gateway_method" "ApiGatewayMethodGetRemittances" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  resource_id = aws_api_gateway_resource.ApiGatewayMethodGetRemittances.id
  http_method = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_method_settings" "ApiGatewayMethodGetRemittances" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  stage_name  = aws_api_gateway_stage.this.stage_name
  method_path = "*/*"

  settings {
    metrics_enabled = false
    logging_level   = "OFF"
  }
}

resource "aws_api_gateway_integration" "ApiGatewayMethodGetRemittances" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  resource_id = aws_api_gateway_resource.ApiGatewayMethodGetRemittances.id
  http_method = aws_api_gateway_method.ApiGatewayMethodGetRemittances.http_method
  integration_http_method = "POST"
  type = "AWS_PROXY"
  uri = "${module.GetRemittancesLambdaFunction.lambda_function_invoke_arn}"  
  credentials = module.apigateway_put_events_to_lambda_us_east_1.iam_role_arn
}

resource "aws_api_gateway_integration" "ApiGatewayMethodGetRemittances_options" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  resource_id = aws_api_gateway_resource.ApiGatewayMethodGetRemittances.id
  http_method = aws_api_gateway_method.ApiGatewayMethodGetRemittances_options.http_method
  type = "MOCK"
  passthrough_behavior = "WHEN_NO_MATCH"

  request_templates = {
    "application/json" = jsonencode({statusCode = 200})
  }
}

resource "aws_api_gateway_method_response" "ApiGatewayMethodGetRemittances_options" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  resource_id = aws_api_gateway_resource.ApiGatewayMethodGetRemittances.id
  http_method = aws_api_gateway_method.ApiGatewayMethodGetRemittances_options.http_method
  status_code = "200"
  

  response_models = {
    "application/json" = "Empty"
  }


  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = false,
    "method.response.header.Access-Control-Allow-Methods" = false,
    "method.response.header.Access-Control-Allow-Origin" = false,
  }
}

resource "aws_api_gateway_integration_response" "ApiGatewayMethodGetRemittances" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  resource_id = aws_api_gateway_resource.ApiGatewayMethodGetRemittances.id
  http_method = aws_api_gateway_method.ApiGatewayMethodGetRemittances_options.http_method
  status_code = aws_api_gateway_method_response.ApiGatewayMethodGetRemittances_options.status_code
  

  depends_on = [
    aws_api_gateway_method.ApiGatewayMethodGetRemittances,
    aws_api_gateway_integration.ApiGatewayMethodGetRemittances_options
  ]

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" =  "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS,POST,PUT'",
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
  }

  response_templates = {
    "application/json" = null
  }
}




############################################
# Create remittance 
############################################

resource "aws_api_gateway_resource" "ResourceCreateRemittance" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  parent_id = aws_api_gateway_rest_api.my_api.root_resource_id
  path_part = "create-ticket"
}

resource "aws_api_gateway_method" "ResourceCreateRemittance_options" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  resource_id = aws_api_gateway_resource.ResourceCreateRemittance.id
  http_method = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "ResourceCreateRemittance" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  resource_id = aws_api_gateway_resource.ResourceCreateRemittance.id
  http_method = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_method_settings" "ResourceCreateRemittance" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  stage_name  = aws_api_gateway_stage.this.stage_name
  method_path = "*/*"

  settings {
    metrics_enabled = false
    logging_level   = "OFF"
  }
}

resource "aws_api_gateway_integration" "ResourceCreateRemittance" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  resource_id = aws_api_gateway_resource.ResourceCreateRemittance.id
  http_method = aws_api_gateway_method.ResourceCreateRemittance.http_method
  integration_http_method = "POST"
  type = "AWS_PROXY"
  uri = "${module.CreateRemittanceLambdaFunction.lambda_function_qualified_invoke_arn}"  
  credentials = module.apigateway_put_events_to_lambda_us_east_1.iam_role_arn
}

resource "aws_api_gateway_integration" "ResourceCreateRemittance_options" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  resource_id = aws_api_gateway_resource.ResourceCreateRemittance.id
  http_method = aws_api_gateway_method.ResourceCreateRemittance_options.http_method
  type = "MOCK"
  passthrough_behavior = "WHEN_NO_MATCH"

  request_templates = {
    "application/json" = jsonencode({statusCode = 200})
  }
}

resource "aws_api_gateway_method_response" "ResourceCreateRemittance_options" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  resource_id = aws_api_gateway_resource.ResourceCreateRemittance.id
  http_method = aws_api_gateway_method.ResourceCreateRemittance_options.http_method
  status_code = "200"


  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = false,
    "method.response.header.Access-Control-Allow-Methods" = false,
    "method.response.header.Access-Control-Allow-Origin" = false
  }
}

resource "aws_api_gateway_integration_response" "ResourceCreateRemittance" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  resource_id = aws_api_gateway_resource.ResourceCreateRemittance.id
  http_method = aws_api_gateway_method.ResourceCreateRemittance_options.http_method
  status_code = aws_api_gateway_method_response.ResourceCreateRemittance_options.status_code
  

  depends_on = [
    aws_api_gateway_method.ResourceCreateRemittance,
    aws_api_gateway_integration.ResourceCreateRemittance_options
  ]

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" =  "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS,POST,PUT'",
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
  }

  response_templates = {
    "application/json" = null
  }
}



##########################################
# create revenue table method
##########################################

resource "aws_api_gateway_resource" "ApiGatewayMethodCreateRevenueTable" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  parent_id = aws_api_gateway_rest_api.my_api.root_resource_id
  path_part = "create-revenue-table"
}

resource "aws_api_gateway_method" "ApiGatewayMethodCreateRevenueTable_options" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  resource_id = aws_api_gateway_resource.ApiGatewayMethodCreateRevenueTable.id
  http_method = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "ApiGatewayMethodCreateRevenueTable" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  resource_id = aws_api_gateway_resource.ApiGatewayMethodCreateRevenueTable.id
  http_method = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "ApiGatewayMethodCreateRevenueTable" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  resource_id = aws_api_gateway_resource.ApiGatewayMethodCreateRevenueTable.id
  http_method = aws_api_gateway_method.ApiGatewayMethodCreateRevenueTable.http_method
  integration_http_method = "POST"
  type = "AWS_PROXY"
  uri = "${module.Create_Revenue_Table.lambda_function_invoke_arn}"  
  credentials = module.apigateway_put_events_to_lambda_us_east_1.iam_role_arn
}

resource "aws_api_gateway_integration" "ApiGatewayMethodCreateRevenueTable_options" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  resource_id = aws_api_gateway_resource.ApiGatewayMethodCreateRevenueTable.id
  http_method = aws_api_gateway_method.ApiGatewayMethodCreateRevenueTable_options.http_method
  type = "MOCK"
  passthrough_behavior = "WHEN_NO_MATCH"

  request_templates = {
    "application/json" = jsonencode({statusCode = 200})
  }
}

resource "aws_api_gateway_method_response" "ApiGatewayMethodCreateRevenueTable_options" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  resource_id = aws_api_gateway_resource.ApiGatewayMethodCreateRevenueTable.id
  http_method = aws_api_gateway_method.ApiGatewayMethodCreateRevenueTable_options.http_method
  status_code = "200"


  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = false,
    "method.response.header.Access-Control-Allow-Methods" = false,
    "method.response.header.Access-Control-Allow-Origin" = false
  }
}

resource "aws_api_gateway_method_response" "ApiGatewayMethodCreateRevenueTable" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  resource_id = aws_api_gateway_resource.ApiGatewayMethodCreateRevenueTable.id
  http_method = aws_api_gateway_method.ApiGatewayMethodCreateRevenueTable.http_method
  status_code = "200"


  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = false,
    "method.response.header.Access-Control-Allow-Methods" = false,
    "method.response.header.Access-Control-Allow-Origin" = false
  }
}

resource "aws_api_gateway_integration_response" "ApiGatewayMethodCreateRevenueTable" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  resource_id = aws_api_gateway_resource.ApiGatewayMethodCreateRevenueTable.id
  http_method = aws_api_gateway_method.ApiGatewayMethodCreateRevenueTable_options.http_method
  status_code = aws_api_gateway_method_response.ApiGatewayMethodCreateRevenueTable_options.status_code
  

  depends_on = [
    aws_api_gateway_method.ApiGatewayMethodCreateRevenueTable,
    aws_api_gateway_integration.ApiGatewayMethodCreateRevenueTable_options
  ]

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" =  "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS,POST,PUT'",
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
  }

}

resource "aws_api_gateway_integration_response" "ApiGatewayMethodCreateRevenueTable_get" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  resource_id = aws_api_gateway_resource.ApiGatewayMethodCreateRevenueTable.id
  http_method = aws_api_gateway_method.ApiGatewayMethodCreateRevenueTable.http_method
  status_code = aws_api_gateway_method_response.ApiGatewayMethodCreateRevenueTable.status_code
  

  depends_on = [
    aws_api_gateway_method.ApiGatewayMethodCreateRevenueTable,
    aws_api_gateway_integration.ApiGatewayMethodCreateRevenueTable
  ]

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" =  "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS,POST,PUT'",
    "method.response.header.Access-Control-Allow-Origin" = "'*'",
  }
}



##########################################
# create revenue item method
##########################################

resource "aws_api_gateway_resource" "ApiGatewayMethodCreateRevenueItem" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  parent_id = aws_api_gateway_rest_api.my_api.root_resource_id
  path_part = "create-revenue-item"
}

resource "aws_api_gateway_method" "ApiGatewayMethodCreateRevenueItem_options" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  resource_id = aws_api_gateway_resource.ApiGatewayMethodCreateRevenueItem.id
  http_method = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "ApiGatewayMethodCreateRevenueItem" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  resource_id = aws_api_gateway_resource.ApiGatewayMethodCreateRevenueItem.id
  http_method = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "ApiGatewayMethodCreateRevenueItem" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  resource_id = aws_api_gateway_resource.ApiGatewayMethodCreateRevenueItem.id
  http_method = aws_api_gateway_method.ApiGatewayMethodCreateRevenueItem.http_method
  integration_http_method = "POST"
  type = "AWS"
  uri  = "arn:aws:apigateway:${var.region1}:events:action/PutEvents" 
  passthrough_behavior = "WHEN_NO_TEMPLATES"
  credentials = module.apigateway_put_events_to_eventbridge_role.iam_role_arn


  request_templates = {
        "application/json" = <<-EOT
            #set($context.requestOverride.header.X-Amz-Target = "AWSEvents.PutEvents")
            #set($context.requestOverride.header.Content-Type = "application/x-amz-json-1.1")            
            #set($inputRoot = $input.json('$')) 
          {
            "Entries": [
              {
                "Detail": "$util.escapeJavaScript($inputRoot).replaceAll("\\'","'")",
                "DetailType": "Order Create", 
                "EventBusName": "${module.eventbridge.eventbridge_bus_name}", 
                "Source": "api.gateway.ca.create" 
              }
            ]
          }
        EOT
  }
}

resource "aws_api_gateway_integration" "ApiGatewayMethodCreateRevenueItem_options" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  resource_id = aws_api_gateway_resource.ApiGatewayMethodCreateRevenueItem.id
  http_method = aws_api_gateway_method.ApiGatewayMethodCreateRevenueItem_options.http_method
  type = "MOCK"
  passthrough_behavior = "WHEN_NO_MATCH"

  request_templates = {
    "application/json" = jsonencode({statusCode = 200})
  }
}

resource "aws_api_gateway_method_response" "ApiGatewayMethodCreateRevenueItem_options" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  resource_id = aws_api_gateway_resource.ApiGatewayMethodCreateRevenueItem.id
  http_method = aws_api_gateway_method.ApiGatewayMethodCreateRevenueItem_options.http_method
  status_code = "200"


  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = false,
    "method.response.header.Access-Control-Allow-Methods" = false,
    "method.response.header.Access-Control-Allow-Origin" = false
  }
}

resource "aws_api_gateway_method_response" "ApiGatewayMethodCreateRevenueItem" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  resource_id = aws_api_gateway_resource.ApiGatewayMethodCreateRevenueItem.id
  http_method = aws_api_gateway_method.ApiGatewayMethodCreateRevenueItem.http_method
  status_code = "200"


  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = false,
    "method.response.header.Access-Control-Allow-Methods" = false,
    "method.response.header.Access-Control-Allow-Origin" = false
  }
}

resource "aws_api_gateway_integration_response" "ApiGatewayMethodCreateRevenueItem" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  resource_id = aws_api_gateway_resource.ApiGatewayMethodCreateRevenueItem.id
  http_method = aws_api_gateway_method.ApiGatewayMethodCreateRevenueItem_options.http_method
  status_code = aws_api_gateway_method_response.ApiGatewayMethodCreateRevenueItem_options.status_code
  

  depends_on = [
    aws_api_gateway_method.ApiGatewayMethodCreateRevenueItem,
    aws_api_gateway_integration.ApiGatewayMethodCreateRevenueItem_options
  ]

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" =  "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS,POST,PUT'",
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
  }

}

resource "aws_api_gateway_integration_response" "ApiGatewayMethodCreateRevenueItem_get" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  resource_id = aws_api_gateway_resource.ApiGatewayMethodCreateRevenueItem.id
  http_method = aws_api_gateway_method.ApiGatewayMethodCreateRevenueItem.http_method
  status_code = aws_api_gateway_method_response.ApiGatewayMethodCreateRevenueItem.status_code
  

  depends_on = [
    aws_api_gateway_method.ApiGatewayMethodCreateRevenueItem,
    aws_api_gateway_integration.ApiGatewayMethodCreateRevenueItem
  ]

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" =  "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS,POST,PUT'",
    "method.response.header.Access-Control-Allow-Origin" = "'*'",
  }
}



##########################################
# get revenue item method
##########################################

resource "aws_api_gateway_resource" "ApiGatewayMethodGetRevenueItem" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  parent_id = aws_api_gateway_rest_api.my_api.root_resource_id
  path_part = "get-revenue-item"
}

resource "aws_api_gateway_method" "ApiGatewayMethodGetRevenueItem_options" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  resource_id = aws_api_gateway_resource.ApiGatewayMethodGetRevenueItem.id
  http_method = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "ApiGatewayMethodGetRevenueItem" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  resource_id = aws_api_gateway_resource.ApiGatewayMethodGetRevenueItem.id
  http_method = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "ApiGatewayMethodGetRevenueItem" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  resource_id = aws_api_gateway_resource.ApiGatewayMethodGetRevenueItem.id
  http_method = aws_api_gateway_method.ApiGatewayMethodGetRevenueItem.http_method
  integration_http_method = "POST"
  type = "AWS_PROXY"
  uri = "${module.Get_Revenue_Item.lambda_function_invoke_arn}"  
  credentials = module.apigateway_put_events_to_lambda_us_east_1.iam_role_arn
}

resource "aws_api_gateway_integration" "ApiGatewayMethodGetRevenueItem_options" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  resource_id = aws_api_gateway_resource.ApiGatewayMethodGetRevenueItem.id
  http_method = aws_api_gateway_method.ApiGatewayMethodGetRevenueItem_options.http_method
  type = "MOCK"
  passthrough_behavior = "WHEN_NO_MATCH"

  request_templates = {
    "application/json" = jsonencode({statusCode = 200})
  }
}

resource "aws_api_gateway_method_response" "ApiGatewayMethodGetRevenueItem_options" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  resource_id = aws_api_gateway_resource.ApiGatewayMethodGetRevenueItem.id
  http_method = aws_api_gateway_method.ApiGatewayMethodGetRevenueItem_options.http_method
  status_code = "200"


  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = false,
    "method.response.header.Access-Control-Allow-Methods" = false,
    "method.response.header.Access-Control-Allow-Origin" = false
  }
}

resource "aws_api_gateway_method_response" "ApiGatewayMethodGetRevenueItem" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  resource_id = aws_api_gateway_resource.ApiGatewayMethodGetRevenueItem.id
  http_method = aws_api_gateway_method.ApiGatewayMethodGetRevenueItem.http_method
  status_code = "200"


  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = false,
    "method.response.header.Access-Control-Allow-Methods" = false,
    "method.response.header.Access-Control-Allow-Origin" = false
  }
}

resource "aws_api_gateway_integration_response" "ApiGatewayMethodGetRevenueItem" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  resource_id = aws_api_gateway_resource.ApiGatewayMethodGetRevenueItem.id
  http_method = aws_api_gateway_method.ApiGatewayMethodGetRevenueItem_options.http_method
  status_code = aws_api_gateway_method_response.ApiGatewayMethodGetRevenueItem_options.status_code
  

  depends_on = [
    aws_api_gateway_method.ApiGatewayMethodGetRevenueItem,
    aws_api_gateway_integration.ApiGatewayMethodGetRevenueItem_options
  ]

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" =  "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS,POST,PUT'",
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
  }

}

resource "aws_api_gateway_integration_response" "ApiGatewayMethodGetRevenueItem_get" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  resource_id = aws_api_gateway_resource.ApiGatewayMethodGetRevenueItem.id
  http_method = aws_api_gateway_method.ApiGatewayMethodGetRevenueItem.http_method
  status_code = aws_api_gateway_method_response.ApiGatewayMethodGetRevenueItem.status_code
  

  depends_on = [
    aws_api_gateway_method.ApiGatewayMethodGetRevenueItem,
    aws_api_gateway_integration.ApiGatewayMethodGetRevenueItem
  ]

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" =  "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS,POST,PUT'",
    "method.response.header.Access-Control-Allow-Origin" = "'*'",
  }
}



##########################################
# Upload public Image to s3
##########################################

resource "aws_api_gateway_resource" "ApiGatewayMethodUploadImagePublic" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  parent_id = aws_api_gateway_rest_api.my_api.root_resource_id
  path_part = "upload-image-public"
}

resource "aws_api_gateway_method" "ApiGatewayMethodUploadImagePublic_options" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  resource_id = aws_api_gateway_resource.ApiGatewayMethodUploadImagePublic.id
  http_method = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "ApiGatewayMethodUploadImagePublic" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  resource_id = aws_api_gateway_resource.ApiGatewayMethodUploadImagePublic.id
  http_method = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "ApiGatewayMethodUploadImagePublic" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  resource_id = aws_api_gateway_resource.ApiGatewayMethodUploadImagePublic.id
  http_method = aws_api_gateway_method.ApiGatewayMethodUploadImagePublic.http_method
  integration_http_method = "POST"
  type = "AWS_PROXY"
  uri = "${module.Image_Uploader_public.lambda_function_invoke_arn}"  
  credentials = module.apigateway_put_events_to_lambda_us_east_1.iam_role_arn
}

resource "aws_api_gateway_integration" "ApiGatewayMethodUploadImagePublic_options" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  resource_id = aws_api_gateway_resource.ApiGatewayMethodUploadImagePublic.id
  http_method = aws_api_gateway_method.ApiGatewayMethodUploadImagePublic_options.http_method
  type = "MOCK"
  passthrough_behavior = "WHEN_NO_MATCH"

  request_templates = {
    "application/json" = jsonencode({statusCode = 200})
  }
}

resource "aws_api_gateway_method_response" "ApiGatewayMethodUploadImagePublic_options" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  resource_id = aws_api_gateway_resource.ApiGatewayMethodUploadImagePublic.id
  http_method = aws_api_gateway_method.ApiGatewayMethodUploadImagePublic_options.http_method
  status_code = "200"


  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = false,
    "method.response.header.Access-Control-Allow-Methods" = false,
    "method.response.header.Access-Control-Allow-Origin" = false
  }
}

resource "aws_api_gateway_method_response" "ApiGatewayMethodUploadImagePublic" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  resource_id = aws_api_gateway_resource.ApiGatewayMethodUploadImagePublic.id
  http_method = aws_api_gateway_method.ApiGatewayMethodUploadImagePublic.http_method
  status_code = "200"


  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = false,
    "method.response.header.Access-Control-Allow-Methods" = false,
    "method.response.header.Access-Control-Allow-Origin" = false
  }
}

resource "aws_api_gateway_integration_response" "ApiGatewayMethodUploadImagePublic" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  resource_id = aws_api_gateway_resource.ApiGatewayMethodUploadImagePublic.id
  http_method = aws_api_gateway_method.ApiGatewayMethodUploadImagePublic_options.http_method
  status_code = aws_api_gateway_method_response.ApiGatewayMethodUploadImagePublic_options.status_code
  

  depends_on = [
    aws_api_gateway_method.ApiGatewayMethodUploadImagePublic,
    aws_api_gateway_integration.ApiGatewayMethodUploadImagePublic_options
  ]

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" =  "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS,POST,PUT'",
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
  }

}

resource "aws_api_gateway_integration_response" "ApiGatewayMethodUploadImagePublic_get" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  resource_id = aws_api_gateway_resource.ApiGatewayMethodUploadImagePublic.id
  http_method = aws_api_gateway_method.ApiGatewayMethodUploadImagePublic.http_method
  status_code = aws_api_gateway_method_response.ApiGatewayMethodUploadImagePublic.status_code
  

  depends_on = [
    aws_api_gateway_method.ApiGatewayMethodUploadImagePublic,
    aws_api_gateway_integration.ApiGatewayMethodUploadImagePublic
  ]

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" =  "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS,POST,PUT'",
    "method.response.header.Access-Control-Allow-Origin" = "'*'",
  }
}



##########################################
# Upload private Image to s3
##########################################

resource "aws_api_gateway_resource" "ApiGatewayMethodUploadImagePrivate" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  parent_id = aws_api_gateway_rest_api.my_api.root_resource_id
  path_part = "upload-image-private"
}

resource "aws_api_gateway_method" "ApiGatewayMethodUploadImagePrivate_options" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  resource_id = aws_api_gateway_resource.ApiGatewayMethodUploadImagePrivate.id
  http_method = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "ApiGatewayMethodUploadImagePrivate" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  resource_id = aws_api_gateway_resource.ApiGatewayMethodUploadImagePrivate.id
  http_method = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "ApiGatewayMethodUploadImagePrivate" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  resource_id = aws_api_gateway_resource.ApiGatewayMethodUploadImagePrivate.id
  http_method = aws_api_gateway_method.ApiGatewayMethodUploadImagePrivate.http_method
  integration_http_method = "POST"
  type = "AWS_PROXY"
  uri = "${module.Image_Uploader.lambda_function_invoke_arn}"  
  credentials = module.apigateway_put_events_to_lambda_us_east_1.iam_role_arn
}

resource "aws_api_gateway_integration" "ApiGatewayMethodUploadImagePrivate_options" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  resource_id = aws_api_gateway_resource.ApiGatewayMethodUploadImagePrivate.id
  http_method = aws_api_gateway_method.ApiGatewayMethodUploadImagePrivate_options.http_method
  type = "MOCK"
  passthrough_behavior = "WHEN_NO_MATCH"

  request_templates = {
    "application/json" = jsonencode({statusCode = 200})
  }
}

resource "aws_api_gateway_method_response" "ApiGatewayMethodUploadImagePrivate_options" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  resource_id = aws_api_gateway_resource.ApiGatewayMethodUploadImagePrivate.id
  http_method = aws_api_gateway_method.ApiGatewayMethodUploadImagePrivate_options.http_method
  status_code = "200"


  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = false,
    "method.response.header.Access-Control-Allow-Methods" = false,
    "method.response.header.Access-Control-Allow-Origin" = false
  }
}

resource "aws_api_gateway_method_response" "ApiGatewayMethodUploadImagePrivate" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  resource_id = aws_api_gateway_resource.ApiGatewayMethodUploadImagePrivate.id
  http_method = aws_api_gateway_method.ApiGatewayMethodUploadImagePrivate.http_method
  status_code = "200"


  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = false,
    "method.response.header.Access-Control-Allow-Methods" = false,
    "method.response.header.Access-Control-Allow-Origin" = false
  }
}

resource "aws_api_gateway_integration_response" "ApiGatewayMethodUploadImagePrivate" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  resource_id = aws_api_gateway_resource.ApiGatewayMethodUploadImagePrivate.id
  http_method = aws_api_gateway_method.ApiGatewayMethodUploadImagePrivate_options.http_method
  status_code = aws_api_gateway_method_response.ApiGatewayMethodUploadImagePrivate_options.status_code
  

  depends_on = [
    aws_api_gateway_method.ApiGatewayMethodUploadImagePrivate,
    aws_api_gateway_integration.ApiGatewayMethodUploadImagePrivate_options
  ]

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" =  "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS,POST,PUT'",
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
  }

}

resource "aws_api_gateway_integration_response" "ApiGatewayMethodUploadImagePrivate_get" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  resource_id = aws_api_gateway_resource.ApiGatewayMethodUploadImagePrivate.id
  http_method = aws_api_gateway_method.ApiGatewayMethodUploadImagePrivate.http_method
  status_code = aws_api_gateway_method_response.ApiGatewayMethodUploadImagePrivate.status_code
  

  depends_on = [
    aws_api_gateway_method.ApiGatewayMethodUploadImagePrivate,
    aws_api_gateway_integration.ApiGatewayMethodUploadImagePrivate
  ]

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" =  "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS,POST,PUT'",
    "method.response.header.Access-Control-Allow-Origin" = "'*'",
  }
}
