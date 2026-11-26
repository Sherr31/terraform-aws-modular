# examples/vpc/outputs.tf
#
# The module already exports many values. This root configuration exposes the
# ones an application or another example is most likely to need first.

output "vpc_id" {
  description = "ID of the VPC created by the example."
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs created by the example."
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs created by the example."
  value       = module.vpc.private_subnet_ids
}

output "azs" {
  description = "Availability Zones used by the example VPC."
  value       = module.vpc.azs
}

output "internet_gateway_id" {
  description = "Internet Gateway ID."
  value       = module.vpc.internet_gateway_id
}

output "public_route_table_id" {
  description = "Public route table ID."
  value       = module.vpc.public_route_table_id
}

output "private_route_table_id" {
  description = "Private route table ID."
  value       = module.vpc.private_route_table_id
}

