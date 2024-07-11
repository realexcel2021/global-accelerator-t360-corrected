module "eventbridge" {
  source = "terraform-aws-modules/eventbridge/aws"

  bus_name = "t360-bus"

  attach_sqs_policy = true
  sqs_target_arns = [
    aws_sqs_queue.queue.arn
  ]

  rules = {
    CA_create = {
      description = "Capture all created orders",
      event_pattern = jsonencode({
        "detail-type" : ["Order Create"],
        "source" : ["api.gateway.ca.create"]
      })
    }
  }

  targets = {
    CA_create = [
      {
        name            = "send-request-to-sqs"
        arn             = aws_sqs_queue.queue.arn
        target_id       = "send-orders-to-sqs"
      }
    ]
  }

  tags = {
    Name = "${random_pet.this.id}-bus"
  }
}


module "eventbridge_secondary" {
  source = "terraform-aws-modules/eventbridge/aws"

  bus_name = "t360-bus-secondary"

  providers = {
    aws = aws.region2
  }

  attach_sqs_policy = true
  sqs_target_arns = [
    aws_sqs_queue.queue_secondary.arn
  ]

  rules = {
    CA_create = {
      description = "Capture all created orders",
      event_pattern = jsonencode({
        "detail-type" : ["Order Create"],
        "source" : ["api.gateway.ca.create"]
      })
    }
  }

  targets = {
    CA_create = [
      {
        name            = "send-request-to-sqs"
        arn             = aws_sqs_queue.queue_secondary.arn
        target_id       = "send-orders-to-sqs"
      }
    ]
  }

}