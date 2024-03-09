resource "azurerm_resource_group" "cloudgateway_rg" {
  provider = azurerm.cloud
  name     = "cloudgatewayrg"
  location = "centralus"
}

resource "azurerm_resource_group" "cloudworkload_rg" {
  provider = azurerm.cloud
  name     = "cloudworkloadrg"
  location = "centralus"
}

/*resource "azurerm_log_analytics_workspace" "cloudgateway_oms" {
  provider            = azurerm.cloud
  name                = "cloudgatewayoms"
  location            = azurerm_resource_group.cloudgateway_rg.location
  resource_group_name = azurerm_resource_group.cloudgateway_rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}*/

resource "azurerm_virtual_network" "cloudgateway_vnet" {
  provider            = azurerm.cloud
  name                = "cloudgatewayvnet"
  location            = azurerm_resource_group.cloudgateway_rg.location
  resource_group_name = azurerm_resource_group.cloudgateway_rg.name
  address_space       = ["10.10.0.0/16"]
}

resource "azurerm_virtual_network" "cloudworkload_vnet" {
  provider            = azurerm.cloud
  name                = "cloudworkloadvnet"
  location            = azurerm_resource_group.cloudworkload_rg.location
  resource_group_name = azurerm_resource_group.cloudworkload_rg.name
  address_space       = ["10.11.0.0/16"]
}

resource "azurerm_virtual_network_peering" "cloudgateway_peering" {
  provider                     = azurerm.cloud
  name                         = "${azurerm_virtual_network.cloudgateway_vnet.name}-to-${azurerm_virtual_network.cloudworkload_vnet.name}"
  resource_group_name          = azurerm_virtual_network.cloudgateway_vnet.resource_group_name
  virtual_network_name         = azurerm_virtual_network.cloudgateway_vnet.name
  remote_virtual_network_id    = azurerm_virtual_network.cloudworkload_vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = true
  use_remote_gateways          = false
}

resource "azurerm_virtual_network_peering" "cloudworkload_peering" {
  provider                     = azurerm.cloud
  name                         = "${azurerm_virtual_network.cloudworkload_vnet.name}-to-${azurerm_virtual_network.cloudgateway_vnet.name}"
  resource_group_name          = azurerm_virtual_network.cloudworkload_vnet.resource_group_name
  virtual_network_name         = azurerm_virtual_network.cloudworkload_vnet.name
  remote_virtual_network_id    = azurerm_virtual_network.cloudgateway_vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = true
}

resource "azurerm_subnet" "cloudgateway_subnet" {
  provider = azurerm.cloud
  for_each = toset(local.cloudgateway_subnets)

  name                 = each.value
  resource_group_name  = azurerm_virtual_network.cloudgateway_vnet.resource_group_name
  virtual_network_name = azurerm_virtual_network.cloudgateway_vnet.name
  address_prefixes     = ["10.10.${index(local.cloudgateway_subnets, each.value)}.0/24"]
}

resource "azurerm_subnet" "cloudworkload_subnet" {
  provider = azurerm.cloud
  for_each = toset(local.cloudworkload_subnets)

  name                 = each.value
  resource_group_name  = azurerm_virtual_network.cloudworkload_vnet.resource_group_name
  virtual_network_name = azurerm_virtual_network.cloudworkload_vnet.name
  address_prefixes     = ["10.11.${index(local.cloudworkload_subnets, each.value)}.0/24"]
}

/*resource "azurerm_route_table" "cloudgateway_rt" {
  provider                      = azurerm.cloud
  name                          = "cloudgatewayrt"
  location                      = azurerm_resource_group.cloudgateway_rg.location
  resource_group_name           = azurerm_resource_group.cloudgateway_rg.name
  disable_bgp_route_propagation = false
}*/

#resource "azurerm_subnet_route_table_association" "cloudgateway_rt_association" {
#  provider = azurerm.cloud
#
#  subnet_id      = azurerm_subnet.cloudgateway_subnet["GatewaySubnet"].id
#  route_table_id = azurerm_route_table.cloudgateway_rt.id
#}

/*resource "azurerm_route_table" "cloudworkload_rt" {
  provider                      = azurerm.cloud
  name                          = "cloudworkloadrt"
  location                      = azurerm_resource_group.cloudworkload_rg.location
  resource_group_name           = azurerm_resource_group.cloudworkload_rg.name
  disable_bgp_route_propagation = false
}

resource "azurerm_subnet_route_table_association" "cloudworkload_rt_association" {
  provider = azurerm.cloud
  for_each = toset(local.cloudworkload_subnets)

  subnet_id      = azurerm_subnet.cloudworkload_subnet[each.value].id
  route_table_id = azurerm_route_table.cloudworkload_rt.id
}*/

resource "random_string" "random" {
  length           = 24
  special          = true
  override_special = "-_"
}

/*resource "azurerm_public_ip" "cloudgateway_afw_pip" {
  provider            = azurerm.cloud
  name                = "cloudgatewayafwpip"
  location            = azurerm_resource_group.cloudgateway_rg.location
  resource_group_name = azurerm_resource_group.cloudgateway_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}*/

resource "azurerm_public_ip" "cloudgateway_vpn_pip1" {
  provider            = azurerm.cloud
  name                = "cloudgatewayvpnpip1"
  location            = azurerm_resource_group.cloudgateway_rg.location
  resource_group_name = azurerm_resource_group.cloudgateway_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"

  zones = [1, 2, 3]
}

resource "azurerm_public_ip" "cloudgateway_vpn_pip2" {
  provider            = azurerm.cloud
  name                = "cloudgatewayvpnpip2"
  location            = azurerm_resource_group.cloudgateway_rg.location
  resource_group_name = azurerm_resource_group.cloudgateway_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"

  zones = [1, 2, 3]
}

/*resource "azurerm_firewall_policy" "cloudgateway_afwp" {
  provider            = azurerm.cloud
  name                = "cloudgatewayafwp"
  location            = azurerm_resource_group.cloudgateway_rg.location
  resource_group_name = azurerm_resource_group.cloudgateway_rg.name
  sku                 = "Premium"

  insights {
    enabled                            = true
    default_log_analytics_workspace_id = azurerm_log_analytics_workspace.cloudgateway_oms.id
    retention_in_days                  = 30
  }

  intrusion_detection {
    mode = "Alert"
  }
}*/

/*resource "azurerm_firewall" "cloudgateway_afw" {
  provider            = azurerm.cloud
  name                = "cloudgatewayafw"
  location            = azurerm_virtual_network.cloudgateway_vnet.location
  resource_group_name = azurerm_virtual_network.cloudgateway_vnet.resource_group_name
  dns_proxy_enabled   = false
  threat_intel_mode   = "Alert"

  sku_name           = "AZFW_VNet"
  sku_tier           = "Premium"
  firewall_policy_id = azurerm_firewall_policy.cloudgateway_afwp.id

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.cloudgateway_subnet["AzureFirewallSubnet"].id
    public_ip_address_id = azurerm_public_ip.cloudgateway_afw_pip.id
  }
}*/

/*resource "azurerm_monitor_diagnostic_setting" "cloudgateway_diag" {
  provider                   = azurerm.cloud
  name                       = "cloudgatewaydiag"
  target_resource_id         = azurerm_firewall.cloudgateway_afw.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.cloudgateway_oms.id

  enabled_log {
    category_group = "allLogs"
  }

  metric {
    category = "AllMetrics"
  }
}*/

resource "azurerm_virtual_network_gateway" "cloudgateway_vpn" {
  provider            = azurerm.cloud
  name                = "cloudgatewayvpn"
  location            = azurerm_resource_group.cloudgateway_rg.location
  resource_group_name = azurerm_resource_group.cloudgateway_rg.name
  type                = "Vpn"
  vpn_type            = "RouteBased"

  enable_bgp    = true
  active_active = true
  sku           = "VpnGw2AZ"
  generation    = "Generation2"

  ip_configuration {
    name                          = "vnetGatewayConfig1"
    subnet_id                     = azurerm_subnet.cloudgateway_subnet["GatewaySubnet"].id
    public_ip_address_id          = azurerm_public_ip.cloudgateway_vpn_pip1.id
    private_ip_address_allocation = "Dynamic"
  }

  ip_configuration {
    name                          = "vnetGatewayConfig2"
    subnet_id                     = azurerm_subnet.cloudgateway_subnet["GatewaySubnet"].id
    public_ip_address_id          = azurerm_public_ip.cloudgateway_vpn_pip2.id
    private_ip_address_allocation = "Dynamic"
  }

  bgp_settings {
    asn = 65050
  }

  #vpn_client_configuration {
  #  address_space = ["192.168.0.0/24"]
  #  vpn_client_protocols = ["OpenVPN"]
  #  vpn_auth_types = ["AAD"]
  #  aad_tenant = "https://login.microsoftonline.com/70e4ef86-5275-4ae9-a3ff-2610232c90cf/"
  #  aad_audience = "41b23e61-6c1e-4545-b367-cd054e0ed4b4"
  #  aad_issuer = "https://sts.windows.net/70e4ef86-5275-4ae9-a3ff-2610232c90cf/"
  #}
}

resource "azurerm_local_network_gateway" "cloudgateway_on_premise_gateway1" {
  provider            = azurerm.cloud
  name                = "cloudgatewaylng1"
  location            = azurerm_resource_group.cloudgateway_rg.location
  resource_group_name = azurerm_resource_group.cloudgateway_rg.name
  gateway_address     = "172.170.112.42"
  bgp_settings {
    asn                 = 65051
    bgp_peering_address = "10.100.1.254"
  }
}

resource "azurerm_local_network_gateway" "cloudgateway_on_premise_gateway2" {
  provider            = azurerm.cloud
  name                = "cloudgatewaylng2"
  location            = azurerm_resource_group.cloudgateway_rg.location
  resource_group_name = azurerm_resource_group.cloudgateway_rg.name
  gateway_address     = "172.170.112.42"
  bgp_settings {
    asn                 = 65051
    bgp_peering_address = "10.100.1.254"
  }
}

resource "azurerm_virtual_network_gateway_connection" "cloudgateway_cloud-to-onpremise1" {
  provider            = azurerm.cloud
  name                = "${azurerm_virtual_network_gateway.cloudgateway_vpn.name}-to-${azurerm_local_network_gateway.cloudgateway_on_premise_gateway1.name}"
  location            = azurerm_virtual_network_gateway.cloudgateway_vpn.location
  resource_group_name = azurerm_virtual_network_gateway.cloudgateway_vpn.resource_group_name

  type                       = "IPsec"
  enable_bgp                 = true
  virtual_network_gateway_id = azurerm_virtual_network_gateway.cloudgateway_vpn.id
  local_network_gateway_id   = azurerm_local_network_gateway.cloudgateway_on_premise_gateway1.id

  shared_key = random_string.random.result
}

resource "azurerm_virtual_network_gateway_connection" "cloudgateway_cloud-to-onpremise2" {
  provider            = azurerm.cloud
  name                = "${azurerm_virtual_network_gateway.cloudgateway_vpn.name}-to-${azurerm_local_network_gateway.cloudgateway_on_premise_gateway2.name}"
  location            = azurerm_virtual_network_gateway.cloudgateway_vpn.location
  resource_group_name = azurerm_virtual_network_gateway.cloudgateway_vpn.resource_group_name

  type                       = "IPsec"
  enable_bgp                 = true
  virtual_network_gateway_id = azurerm_virtual_network_gateway.cloudgateway_vpn.id
  local_network_gateway_id   = azurerm_local_network_gateway.cloudgateway_on_premise_gateway2.id

  shared_key = random_string.random.result
}



resource "azurerm_network_interface" "cloudworkload_nic" {
  provider            = azurerm.cloud
  name                = "cloudworkloadnic"
  location            = azurerm_resource_group.cloudworkload_rg.location
  resource_group_name = azurerm_resource_group.cloudworkload_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.cloudworkload_subnet["Compute"].id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_windows_virtual_machine" "cloudworkload_vm" {
  provider            = azurerm.cloud
  name                = "cloudworkloadvm"
  location            = azurerm_resource_group.cloudworkload_rg.location
  resource_group_name = azurerm_resource_group.cloudworkload_rg.name
  size                = "Standard_D2s_v3"
  admin_username      = "adminuser"
  admin_password      = "P@$$w0rd1234!"
  network_interface_ids = [
    azurerm_network_interface.cloudworkload_nic.id
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }
}