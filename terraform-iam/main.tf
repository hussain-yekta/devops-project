resource "aws_iam_user" "myUser" {
    name = "Jack"
}
resource "aws_iam_user" "myUser2" {
    name = "David"
}


resource "aws_iam_policy" "myCustomPolicy" {
  name = "MyCustomPolicy"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "ec2:GetDefaultCreditSpecification",
                "ec2:DescribeTags",
                "ec2:DescribeVpnConnections",
                "ec2:GetEbsEncryptionByDefault",
                "ec2:GetCapacityReservationUsage",
                "ec2:DescribeVolumesModifications",
                "ec2:GetHostReservationPurchasePreview",
                "ec2:DescribeFastSnapshotRestores",
                "ec2:GetConsoleScreenshot",
                "ec2:GetReservedInstancesExchangeQuote",
                "ec2:GetConsoleOutput",
                "ec2:GetPasswordData",
                "ec2:GetLaunchTemplateData",
                "ec2:DescribeScheduledInstances",
                "ec2:DescribeScheduledInstanceAvailability",
                "ec2:GetEbsDefaultKmsKeyId",
                "ec2:DescribeElasticGpus"
            ],
            "Resource": "*"
        }
    ]
}
  EOF
}

resource "aws_iam_policy_attachment" "policyBind" {
    name = "attachment"
    users = ["${aws_iam_user.myUser.name}"]
    policy_arn = "${aws_iam_policy.myCustomPolicy.arn}"
}

output "iam_user_arn" {
    value = "${aws_iam_user.myUser.arn}"
}
