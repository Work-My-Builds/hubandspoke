/**resource "azurerm_firewall_policy_rule_collection_group" "cloudgateway_afwprcg" {
  provider           = azurerm.cloud
  name               = "FirewallPolicyRule"
  firewall_policy_id = azurerm_firewall_policy.cloudgateway_afwp.id
  priority           = 100
  #application_rule_collection {
  #  name     = "app_rule_collection1"
  #  priority = 500
  #  action   = "Deny"
  #  rule {
  #    name = "app_rule_collection1_rule1"
  #    protocols {
  #      type = "Http"
  #      port = 80
  #    }
  #    protocols {
  #      type = "Https"
  #      port = 443
  #    }
  #    source_addresses  = ["10.0.0.1"]
  #    destination_fqdns = ["*.microsoft.com"]
  #  }
  #}

  network_rule_collection {
    name     = "cloudgatewaynetworkrc"
    priority = 100
    action   = "Allow"
    rule {
      name                  = "Cloud-To-Onprem"
      protocols             = ["TCP", "UDP"]
      source_addresses      = ["10.10.0.0/16", "10.11.0.0/16"]
      destination_addresses = ["10.100.0.0/16", "10.200.0.0/16"]
      destination_ports     = ["*"]
      description           = "Allow Cloud network to connect to Onprem network"
    }

    rule {
      name                  = "Onprem-To-Cloud"
      protocols             = ["TCP", "UDP"]
      source_addresses      = ["10.100.0.0/16", "10.200.0.0/16"]
      destination_addresses = ["10.10.0.0/16", "10.11.0.0/16"]
      destination_ports     = ["*"]
      description           = "Allow Onprem network to connect to Cloud network"
    }

    rule {
      name                  = "Cloud-To-NTP"
      protocols             = ["UDP"]
      source_addresses      = ["*"]
      destination_addresses = ["168.61.215.74"]
      destination_ports     = ["*"]
      description           = "Allow Cloud network to connect to Azure NTP server"
    }
  }

  nat_rule_collection {
    name     = "cloudgatewaynatrc"
    priority = 200
    action   = "Dnat"
    rule {
      name                = "Connect-To-VM"
      protocols           = ["TCP", "UDP"]
      source_addresses    = ["208.184.162.145"]
      destination_address = "172.173.115.134"
      destination_ports   = ["3389"]
      translated_address  = "10.11.0.4"
      translated_port     = "3389"
    }
  }
}**/