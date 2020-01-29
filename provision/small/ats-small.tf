# Terraform plan for ats small deployment on packet

variable "auth_token" {
  type        = string
  default     = null
  description = "The packet authorization token if not in environment"
}

variable "project_id" {
  type        = string
  description = "The id of the packet project to use."
}

variable "public_ip_cidr" {
  type        = string
  description = "The CIDR for the pre-allocated ATS public IP addresses."
}

variable "public_ip_count" {
  type        = string
  default     = 16
  description = "The number of addresses to allocate from the public CIDR range."
}

variable "facility" {
  type        = string
  default     = "sjc1"
  description = "The packet facility for the deployment."
}

variable "device_hostname" {
  type        = string
  default     = "ats"
  description = "The hostname for the packet device being provisioned."
}

variable "device_plan" {
  type        = string
  default     = "c2.medium.x86"
  description = "The plan for the packet device being provisioned."
}

variable "billing_cycle" {
  type        = string
  default     = "hourly"
  description = "The packet billing cycle to use, hourly or monthly."
}

variable "console_admin_password" {
  type        = string
  default     = ""
  description = "The password for the administrative console eucalyptus/admin user."
}

locals {
  ansible_repo_commit = "b51f4d3e3a7e3a503244132d207470bcf3783850"
  ansible_repo_org    = "appscale"
  auth_token      = var.auth_token
  billing_cycle   = var.billing_cycle
  console_admin_password = var.console_admin_password
  device_hostname = var.device_hostname
  device_plan     = var.device_plan
  facility        = var.facility
  project_id      = var.project_id
  public_ip_cidr  = var.public_ip_cidr
  public_ip_count = var.public_ip_count
}

provider "packet" {
  auth_token = local.auth_token
  version = "~> 2.7"
}

provider "random" {
  version = "~> 2.2"
}

resource "random_string" "ats_console_password" {
  length = 10
  min_upper = 1
  min_lower = 1
  number = false
  special = false
}

resource "packet_ip_attachment" "ats_elasticip_attachment" {
  device_id     = packet_device.ats.id
  cidr_notation = local.public_ip_cidr
}

resource "packet_device" "ats" {
  hostname         = local.device_hostname
  plan             = local.device_plan
  facilities       = ["${local.facility}"]
  operating_system = "centos_7"
  billing_cycle    = local.billing_cycle
  project_id       = local.project_id
  ip_address_types = ["private_ipv4", "public_ipv4"]
  user_data        = templatefile("ats-small-userdata.yaml", {
    ansible_repo_org = local.ansible_repo_org,
    ansible_repo_commit = local.ansible_repo_commit,
    console_pass_b64 = "%{if local.console_admin_password != ""}${base64encode(local.console_admin_password)}%{ else }${base64encode(random_string.ats_console_password.result)}%{ endif }",
    net_public_ip_cidr = local.public_ip_cidr,
    net_public_ip_range = "${cidrhost(local.public_ip_cidr, 0)}-${cidrhost(local.public_ip_cidr, local.public_ip_count - 1)}",
  })
}

output "console_location" {
  description = "The location of the ATS administrative console."
  value = "https://console.ats-${replace(packet_device.ats.network.0.address,".","-")}.euca.me/"
}

output "console_password" {
  description = "The eucalyptus account admin user console password (if generated)"
  value = "%{if local.console_admin_password == ""}${random_string.ats_console_password.result}%{ endif }"
}
