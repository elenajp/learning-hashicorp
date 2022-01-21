data "aws_iam_policy_document" "describe_ec2" {
  // Required by Consul (Cloud auto-join)
  statement {
    actions   = ["ec2:Describe*"]
    resources = ["*"]
    effect    = "Allow"
  }
}

resource "aws_iam_policy" "describe_ec2" {
  name   = "${local.stack_id}_describe_ec2"
  policy = data.aws_iam_policy_document.describe_ec2.json
}