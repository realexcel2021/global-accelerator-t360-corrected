
resource "aws_sqs_queue" "queue" {
  name = "t360-queue"
  visibility_timeout_seconds = 60
}

resource "aws_sqs_queue" "queue_secondary" {
  name = "t360-queue"
  visibility_timeout_seconds = 60

  provider = aws.region2
}


resource "aws_sqs_queue_policy" "queue" {
  queue_url = aws_sqs_queue.queue.id
  policy    = data.aws_iam_policy_document.queue.json
}

resource "aws_sqs_queue_policy" "queue_secondary" {
  queue_url = aws_sqs_queue.queue_secondary.id
  policy    = data.aws_iam_policy_document.queue.json

  provider = aws.region2
}

data "aws_iam_policy_document" "queue" {
  statement {
    sid     = "AllowSendMessage"
    actions = ["sqs:SendMessage"]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }

    resources = ["*"]
  }
}
