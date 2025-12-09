resource "aws_lambda_function" "dns_lambda" {
  function_name = var.lambda_name
  #the role given to lambda
  #need cloudwatch and route 53 resource change based on the project 
  #also resource = specific hsoted zone
  role          = var.role_arn
  #wwhere should the code start working 
  handler       = "main.lambda_handler"
  #the intepreter (compiler)
  runtime       = "python3.12"
  #the zip file for code
  filename      = var.lambda_zip_path
  #for checking the zip file has been modified or not
  source_code_hash = filebase64sha256(var.lambda_zip_path)
  timeout = var.lambda_timeout
  environment {
    variables = {
        #you can only modify this hosted zone 
      HOSTED_ZONE_ID = var.hosted_zone_id
      #this is the base name
      BASE_DOMAIN    = var.base_domain
    }
  }
}

