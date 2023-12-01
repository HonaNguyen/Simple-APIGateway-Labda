provider "aws" {
    region = "us-east-1"
}

# IAM Role
resource "aws_iam_role" "iam" {
    name = "lambda-apiGateway"
    assume_role_policy = jsonencode({
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Principal": {
                    "Service": "lambda.amazonaws.com"
                },
                "Action": "sts:AssumeRole"
            }
        ]
    })

    managed_policy_arns = ["arn:aws:iam::aws:policy/CloudWatchFullAccess"]
}

# Lambda
data "archive_file" "get-func"{
    type = "zip"
    source_dir = "./iris"
    output_path = "iris.zip" 
    # source{
    #     content = file("./iris/lambda/get-func.py")
    #     filename = "get-func.py"
    # }

}

data "archive_file" "post-func"{
    type = "zip"
    output_path = "post-func.zip" 

    source{
        content = file("./iris/lambda/post-func.py")
        filename = "post-func.py"
    }
}


resource "aws_lambda_function" "get-func"{
    function_name = "get-func"
    role = aws_iam_role.iam.arn

    filename = "iris.zip"
    source_code_hash = data.archive_file.get-func.output_base64sha256

    architectures = ["x86_64"]
    runtime = "python3.9"
    handler = "main.lambda_handler"
}

resource "aws_lambda_function" "post-func" {
    function_name = "post-func"
    role = aws_iam_role.iam.arn

    filename = "post-func.zip"
    source_code_hash = data.archive_file.post-func.output_base64sha256

    architectures = ["x86_64"]
    runtime = "python3.9"
    handler = "post-func.lambda_handler"
}



# API Gateway
resource "aws_api_gateway_rest_api" "deploy-api" {
    name = "deploy-api"
    endpoint_configuration {
        types = ["REGIONAL"]
    }
}

# Path: /user 
resource "aws_api_gateway_resource" "user-api-resource" {
    rest_api_id = aws_api_gateway_rest_api.deploy-api.id
    parent_id = aws_api_gateway_rest_api.deploy-api.root_resource_id
    path_part = "user"
}

## Get Method
resource "aws_api_gateway_method" "user-get" {
    rest_api_id = aws_api_gateway_rest_api.deploy-api.id
    resource_id = aws_api_gateway_resource.user-api-resource.id
    http_method = "GET"
    authorization = "NONE"
}

resource "aws_api_gateway_integration" "user-get-integration" {
    rest_api_id = aws_api_gateway_rest_api.deploy-api.id
    resource_id = aws_api_gateway_resource.user-api-resource.id
    http_method = aws_api_gateway_method.user-get.http_method
    type = "AWS_PROXY"
    integration_http_method = "POST"
    uri = aws_lambda_function.get-func.invoke_arn
}

## Give API gateway permission to access AWS Lambda
resource "aws_lambda_permission" "get-func-permission"{
    statement_id = "AllowAPIGatewayInvoke"
    action = "lambda:InvokeFunction"
    function_name = aws_lambda_function.get-func.function_name
    principal = "apigateway.amazonaws.com"

    source_arn = "${aws_api_gateway_rest_api.deploy-api.execution_arn}/*"
}

## Post Method
resource "aws_api_gateway_method" "user-post" {
    rest_api_id = aws_api_gateway_rest_api.deploy-api.id
    resource_id = aws_api_gateway_resource.user-api-resource.id
    http_method = "POST"
    authorization = "NONE"
}

resource "aws_api_gateway_integration" "user-post-integration" {
    rest_api_id = aws_api_gateway_rest_api.deploy-api.id
    resource_id = aws_api_gateway_resource.user-api-resource.id
    http_method = aws_api_gateway_method.user-post.http_method
    type = "AWS_PROXY"
    integration_http_method = "POST"
    uri = aws_lambda_function.post-func.invoke_arn
}

## Give API gateway permission to access AWS Lambda
resource "aws_lambda_permission" "post-func-permission"{
    statement_id = "AllowAPIGatewayInvoke"
    action = "lambda:InvokeFunction"
    function_name = aws_lambda_function.post-func.function_name
    principal = "apigateway.amazonaws.com"

    source_arn = "${aws_api_gateway_rest_api.deploy-api.execution_arn}/*"
}

## Add stage to API
resource "aws_api_gateway_deployment" "api-deploy" {
    rest_api_id = aws_api_gateway_rest_api.deploy-api.id
    lifecycle {
        create_before_destroy = true
    }
    depends_on = [ 
        aws_api_gateway_resource.user-api-resource,
        
        aws_api_gateway_method.user-get,
        aws_api_gateway_integration.user-get-integration,

        aws_api_gateway_method.user-post,
        aws_api_gateway_integration.user-post-integration
    ]
}

resource "aws_api_gateway_stage" "v1" {
    stage_name = "v1"
    rest_api_id = aws_api_gateway_rest_api.deploy-api.id
    deployment_id = aws_api_gateway_deployment.api-deploy.id
}




