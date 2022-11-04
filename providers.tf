terraform {

  required_providers {

    rancher2 = {
      source  = "rancher/rancher2"
      version = "1.24.2"
    }
  } # End of required_providers
}   # End of terraform

provider "rancher2" {
  api_url   = file("${path.cwd}/files/.rancher_api_url")
  token_key = file("${path.cwd}/files/.rancher_bearer_token")
}