terraform {
  required_version = ">= 1.9.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0"
    }
    tagger = {
      source  = "registry.terraform.io/rafalmasiarek/tagger"
      version = ">= 0.1.0"
    }
    # Not yet published to the registry - requires dev_overrides pointing
    # at a local build until a release exists. See
    # https://github.com/rafalmasiarek/terraform-provider-netutils.
    netutils = {
      source = "rafalmasiarek/netutils"
    }
  }
}
