locals {
  cloudgateway_subnets = [
    "AzureFirewallSubnet",
    "GatewaySubnet"
  ]

  cloudworkload_subnets = [
    "Compute",
    "Data"
  ]

  onpremgateway_subnets = [
    "AzureFirewallSubnet",
    "GatewaySubnet"
  ]

  onpremworkload_subnets = [
    "Compute",
    "Data"
  ]
}