# Terraform plans for AppScale ATS deployments on Packet

## Plans

Plans allow for AppScale ATS deployments with different characteristics:

* small : Single host demonstration or testing deployment

## Setup

This Packet and Terraform setup should be completed before provisioning.

### Packet Project

On Packet create a project and:

* note the project id
* allocate some Elastic IPs for cloud use
* add project or user SSH keys
* create a read/write authentication token

### Terraform Install

Ensure the `terraform` command is available. This may be from a local
install, by running a container, etc.

### Terraform Variables

Create a `terraform.tfvars` file in the plan directory and set:

```
project_id = "..."
public_ip_cidr = "..."
auth_token = "..."
```

The `public_ip_cidr` is the CIDR for the allocated Elastic IPs.

### Terraform Initialization

To initialize terraform run the following in the plan directory:

```
terraform init
```

## Provisioning

To provision an AppScale ATS cloud apply from the plan directory:

```
terraform apply
```

Outputs for the deployment show the URL and password to use for access
to the management console as the `eucalyptus` account `admin` user.

To unprovision:

```
terraform destroy
```

## Information

The following can be used to show information on provisioning:

```
terraform plan
terraform show
```

These commands should be run from the plan directory.
