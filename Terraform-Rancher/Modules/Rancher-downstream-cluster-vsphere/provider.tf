

terraform {
  required_providers {
    rancher2 = {
      source  = "rancher/rancher2"
      version = "3.0.1"  // The code is tested for this specific version 
    }
  }
}

# this block contains the access mechanism to be able to communicate to the rancher using the provider ( accesskeys , secretkeys)

provider "rancher2" {
  api_url    = var.api_url
  access_key = var.access_key
  secret_key = var.secret_key
  insecure   = var.insecure_connection
}
