#normmaly use "this" which means the important resource is defined here
#for each module no hard code, everything use variable to pass in
#no fixed values unless you certainly need it
resource "aws_security_group" "this" {
  name        = var.name
  description = var.description
  vpc_id      = var.vpc_id

#dynamic is used for loop to create multiple ingress/egress rules
  dynamic "ingress" {
    for_each = var.ingress
    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }

  dynamic "egress" {
    for_each = var.egress
    content {
      from_port   = egress.value.from_port
      to_port     = egress.value.to_port
      protocol    = egress.value.protocol
      cidr_blocks = egress.value.cidr_blocks
    }
  }
}
resource "aws_security_group_rule" "allow_sg_ingress" {
  for_each = { for idx, rule in var.allow_sg_ingress : idx => rule }

  type              = "ingress"
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = each.value.protocol
  security_group_id = aws_security_group.this.id
  source_security_group_id = each.value.source_sg
}
