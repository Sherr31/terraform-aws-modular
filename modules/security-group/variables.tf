# variables.tf — inputs for the reusable security group module

# -----------------------------------------------------------------------------
# Basic info
# -----------------------------------------------------------------------------

variable "name" {
  description = "Name of the security group. Must be unique within the VPC."
  type        = string
}

variable "description" {
  description = "Description of the security group."
  type        = string
  default     = "Managed by Terraform"
}

variable "vpc_id" {
  description = "ID of the VPC where the security group will be created."
  type        = string
}

# -----------------------------------------------------------------------------
# Rule deletion behavior
# -----------------------------------------------------------------------------

variable "revoke_rules_on_delete" {
  description = <<-EOT
    Whether to revoke all rules from the security group before deleting it.

    When true, Terraform removes all rules before deleting the security group.
    This avoids errors when the security group is in use.

    Default is false to match Terraform's default behavior.
  EOT
  type        = bool
  default     = false
}

# -----------------------------------------------------------------------------
# Ingress rules
# -----------------------------------------------------------------------------

variable "ingress_rules" {
  description = <<-EOT
    List of ingress (incoming traffic) rules.

    Each rule supports:

    - protocol: Protocol name or number (e.g. "tcp", "udp", "icmp", "-1" for all)
    - from_port: Start of port range
    - to_port: End of port range
    - cidr_blocks: List of CIDR blocks to allow
    - ipv6_cidr_blocks: List of IPv6 CIDR blocks to allow (optional)
    - prefix_list_ids: List of prefix list IDs (optional)
    - security_groups: List of security group IDs to allow (optional)
    - self: If true, allow traffic from the same security group (optional)
    - description: Rule description (optional)

    Example — allow SSH from a specific IP:

    ```hcl
    ingress_rules = [
      {
        protocol  = "tcp"
        from_port = 22
        to_port   = 22
        cidr_blocks = ["203.0.113.0/24"]
        description = "SSH access from office"
      }
    ]
    ```

    Example — allow HTTP from anywhere:

    ```hcl
    ingress_rules = [
      {
        protocol  = "tcp"
        from_port = 80
        to_port   = 80
        cidr_blocks = ["0.0.0.0/0"]
        description = "HTTP from internet"
      }
    ]
    ```

    Example — allow traffic between security groups:

    ```hcl
    ingress_rules = [
      {
        protocol      = "tcp"
        from_port     = 8080
        to_port       = 8080
        security_groups = ["sg-12345678"]
        description   = "App traffic from backend SG"
      }
    ]
    ```
  EOT
  type = list(object({
    protocol         = string
    from_port        = number
    to_port          = number
    cidr_blocks      = list(string)
    ipv6_cidr_blocks = optional(list(string))
    prefix_list_ids  = optional(list(string))
    security_groups  = optional(list(string))
    self             = optional(bool)
    description      = optional(string)
  }))
  default = []
}

# -----------------------------------------------------------------------------
# Egress rules
# -----------------------------------------------------------------------------

variable "egress_rules" {
  description = <<-EOT
    List of egress (outgoing traffic) rules.

    Same structure as ingress_rules, but for outgoing traffic.

    Example — allow all outbound HTTPS:

    ```hcl
    egress_rules = [
      {
        protocol  = "tcp"
        from_port = 443
        to_port   = 443
        cidr_blocks = ["0.0.0.0/0"]
        description = "HTTPS outbound"
      }
    ]
    ```

    Example — restrict outbound to specific destinations:

    ```hcl
    egress_rules = [
      {
        protocol      = "tcp"
        from_port     = 443
        to_port       = 443
        prefix_list_ids = ["pl-12345678"]
        description   = "HTTPS to S3 only"
      }
    ]
    ```
  EOT
  type = list(object({
    protocol         = string
    from_port        = number
    to_port          = number
    cidr_blocks      = list(string)
    ipv6_cidr_blocks = optional(list(string))
    prefix_list_ids  = optional(list(string))
    security_groups  = optional(list(string))
    self             = optional(bool)
    description      = optional(string)
  }))
  default = []
}

# -----------------------------------------------------------------------------
# Tags
# -----------------------------------------------------------------------------

variable "tags" {
  description = "Additional tags to apply to the security group."
  type        = map(string)
  default     = {}
}
