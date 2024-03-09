/*resource "azurerm_resource_group" "onpremgateway_rg" {
  provider = azurerm.onprem
  name     = "onpremgatewayrg"
  location = "centralus"
}

resource "azurerm_resource_group" "onpremworkload_rg" {
  provider = azurerm.onprem
  name     = "onpremworkloadrg"
  location = "centralus"
}

resource "azurerm_virtual_network" "onpremgateway_vnet" {
  provider            = azurerm.onprem
  name                = "onpremgatewayvnet"
  location            = azurerm_resource_group.onpremgateway_rg.location
  resource_group_name = azurerm_resource_group.onpremgateway_rg.name
  address_space       = ["10.100.0.0/16"]
}

resource "azurerm_virtual_network" "onpremworkload_vnet" {
  provider            = azurerm.onprem
  name                = "onpremworkloadvnet"
  location            = azurerm_resource_group.onpremworkload_rg.location
  resource_group_name = azurerm_resource_group.onpremworkload_rg.name
  address_space       = ["10.200.0.0/16"]
}

resource "azurerm_virtual_network_peering" "onpremgateway_peering" {
  provider                     = azurerm.onprem
  name                         = "${azurerm_virtual_network.onpremgateway_vnet.name}-to-${azurerm_virtual_network.onpremworkload_vnet.name}"
  resource_group_name          = azurerm_virtual_network.onpremgateway_vnet.resource_group_name
  virtual_network_name         = azurerm_virtual_network.onpremgateway_vnet.name
  remote_virtual_network_id    = azurerm_virtual_network.onpremworkload_vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = true
  use_remote_gateways          = false
}

resource "azurerm_virtual_network_peering" "onpremworkload_peering" {
  provider                     = azurerm.onprem
  name                         = "${azurerm_virtual_network.onpremworkload_vnet.name}-to-${azurerm_virtual_network.onpremgateway_vnet.name}"
  resource_group_name          = azurerm_virtual_network.onpremworkload_vnet.resource_group_name
  virtual_network_name         = azurerm_virtual_network.onpremworkload_vnet.name
  remote_virtual_network_id    = azurerm_virtual_network.onpremgateway_vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = true
}

resource "azurerm_subnet" "onpremgateway_subnet" {
  provider = azurerm.onprem
  for_each = toset(local.onpremgateway_subnets)

  name                 = each.value
  resource_group_name  = azurerm_virtual_network.onpremgateway_vnet.resource_group_name
  virtual_network_name = azurerm_virtual_network.onpremgateway_vnet.name
  address_prefixes     = ["10.100.${index(local.onpremgateway_subnets, each.value)}.0/24"]
}

resource "azurerm_subnet" "onpremworkload_subnet" {
  provider = azurerm.onprem
  for_each = toset(local.onpremworkload_subnets)

  name                 = each.value
  resource_group_name  = azurerm_virtual_network.onpremworkload_vnet.resource_group_name
  virtual_network_name = azurerm_virtual_network.onpremworkload_vnet.name
  address_prefixes     = ["10.200.${index(local.onpremworkload_subnets, each.value)}.0/24"]
}

resource "azurerm_network_security_group" "onpremworkload_nsg" {
  provider            = azurerm.onprem
  name                = "onpremworkloadnsg"
  location            = azurerm_resource_group.onpremworkload_rg.location
  resource_group_name = azurerm_resource_group.onpremworkload_rg.name
}

resource "azurerm_route_table" "onpremworkload_rt" {
  provider                      = azurerm.onprem
  name                          = "onpremworkloadrt"
  location                      = azurerm_resource_group.onpremworkload_rg.location
  resource_group_name           = azurerm_resource_group.onpremworkload_rg.name
  disable_bgp_route_propagation = false
}

resource "azurerm_subnet_network_security_group_association" "onpremworkload_nsg_association" {
  provider = azurerm.onprem
  for_each = toset(local.onpremworkload_subnets)

  subnet_id                 = azurerm_subnet.onpremworkload_subnet[each.value].id
  network_security_group_id = azurerm_network_security_group.onpremworkload_nsg.id
}

resource "azurerm_subnet_route_table_association" "onpremworkload_rt_association" {
  provider = azurerm.onprem
  for_each = toset(local.onpremworkload_subnets)

  subnet_id      = azurerm_subnet.onpremworkload_subnet[each.value].id
  route_table_id = azurerm_route_table.onpremworkload_rt.id
}

resource "azurerm_public_ip" "onpremgateway_vpn_pip" {
  provider            = azurerm.onprem
  name                = "onpremgatewayvpnpip"
  location            = azurerm_resource_group.onpremgateway_rg.location
  resource_group_name = azurerm_resource_group.onpremgateway_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"

  zones = [1, 2, 3]
}

resource "azurerm_virtual_network_gateway" "onpremgateway_vpn" {
  provider            = azurerm.onprem
  name                = "onpremgatewayvpn"
  location            = azurerm_resource_group.onpremgateway_rg.location
  resource_group_name = azurerm_resource_group.onpremgateway_rg.name
  type                = "Vpn"
  vpn_type            = "RouteBased"

  enable_bgp    = true
  active_active = false
  sku           = "VpnGw2AZ"
  generation    = "Generation2"

  ip_configuration {
    name                          = "vnetGatewayConfig"
    subnet_id                     = azurerm_subnet.onpremgateway_subnet["GatewaySubnet"].id
    public_ip_address_id          = azurerm_public_ip.onpremgateway_vpn_pip.id
    private_ip_address_allocation = "Dynamic"
  }

  bgp_settings {
    asn = 65051
  }
}

resource "azurerm_local_network_gateway" "onpremgateway_on_premise_gateway" {
  provider            = azurerm.onprem
  name                = "onpremgatewaylng"
  location            = azurerm_resource_group.onpremgateway_rg.location
  resource_group_name = azurerm_resource_group.onpremgateway_rg.name
  gateway_address     = "172.170.56.197"
  bgp_settings {
    asn                 = 65050
    bgp_peering_address = "10.10.1.254"
  }
}

resource "azurerm_virtual_network_gateway_connection" "onpremgateway_onprem-to-onpremise" {
  provider            = azurerm.onprem
  name                = "${azurerm_virtual_network_gateway.onpremgateway_vpn.name}-to-${azurerm_local_network_gateway.onpremgateway_on_premise_gateway.name}"
  location            = azurerm_virtual_network_gateway.onpremgateway_vpn.location
  resource_group_name = azurerm_virtual_network_gateway.onpremgateway_vpn.resource_group_name

  type                       = "IPsec"
  enable_bgp                 = true
  virtual_network_gateway_id = azurerm_virtual_network_gateway.onpremgateway_vpn.id
  local_network_gateway_id   = azurerm_local_network_gateway.onpremgateway_on_premise_gateway.id

  shared_key = random_string.random.result
}



resource "azurerm_public_ip" "onpremworkload_pip" {
  provider            = azurerm.onprem
  name                = "onpremworkloadvmpip"
  location            = azurerm_resource_group.onpremworkload_rg.location
  resource_group_name = azurerm_resource_group.onpremworkload_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_interface" "onpremworkload_nic" {
  provider            = azurerm.onprem
  name                = "onpremworkloadnic"
  location            = azurerm_resource_group.onpremworkload_rg.location
  resource_group_name = azurerm_resource_group.onpremworkload_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.onpremworkload_subnet["Compute"].id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.onpremworkload_pip.id
  }
}

resource "azurerm_windows_virtual_machine" "onpremworkload_vm" {
  provider            = azurerm.onprem
  name                = "onpremworkldvm"
  location            = azurerm_resource_group.onpremworkload_rg.location
  resource_group_name = azurerm_resource_group.onpremworkload_rg.name
  size                = "Standard_D2s_v3"
  admin_username      = "adminuser"
  admin_password      = "P@$$w0rd1234!"
  network_interface_ids = [
    azurerm_network_interface.onpremworkload_nic.id
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
}*/