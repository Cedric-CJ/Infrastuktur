resource "aws_iam_role" "lambda_exec" {
  name = "${var.project}-${var.env}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "logs" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "aws_iam_policy_document" "ddb" {
  statement {
    sid     = "DynamoDBAccess"
    actions = [
      "dynamodb:PutItem",
      "dynamodb:UpdateItem",
      "dynamodb:GetItem",
      "dynamodb:Query"
    ]

    resources = [
      var.comments_table_arn,
      var.reactions_table_arn,
      var.logs_table_arn,
      var.users_table_arn
    ]
  }
}

resource "aws_iam_policy" "ddb" {
  name   = "${var.project}-${var.env}-lambda-ddb"
  policy = data.aws_iam_policy_document.ddb.json
}

resource "aws_iam_role_policy_attachment" "ddb" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.ddb.arn
}
