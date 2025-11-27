#SG is the base, most other module need to use it 
#so it needs to have an output SG for other module to refer to
output "sg_id" {
  value = aws_security_group.this.id
}
