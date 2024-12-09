
# Using Existing Resource Group
data "azurerm_resource_group" "rg" {
  name     = "rg-aztraining-cat-uk"
  //location = "Uk South"
}

# Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-vpn-demo"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]
}

# Subnet for the Virtual Network
resource "azurerm_subnet" "subnet" {
  name                 = "default"
  resource_group_name  = data.azurerm_resource_group.rg.name
  virtual_network_name = data.azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# VPN Gateway Subnet
resource "azurerm_subnet" "vpn_gateway_subnet" {
  name                      = "GatewaySubnet"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.vnet.name
  address_prefixes          = ["10.0.255.0/27"]
}

# VPN Gateway
resource "azurerm_virtual_network_gateway" "vpn_gateway" {
  name                    = "vpn-gateway"
  location                = azurerm_resource_group.rg.location
  resource_group_name     = azurerm_resource_group.rg.name
  type                    = "Vpn"
  vpn_type                = "RouteBased"
  active_active           = false
  enable_bgp              = false
  sku                     = "VpnGw1"
  gateway_default_site    = false

  ip_configuration {
    name                          = "vpn-gateway-ip-config"
    public_ip_address_id          = azurerm_public_ip.vpn_gateway_public_ip.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.vpn_gateway_subnet.id
  }
}

# Public IP for VPN Gateway
resource "azurerm_public_ip" "vpn_gateway_public_ip" {
  name                         = "vpn-gateway-ip"
  location                     = azurerm_resource_group.rg.location
  resource_group_name          = azurerm_resource_group.rg.name
  allocation_method            = "Static"
  sku                          = "Standard"
}

# P2S VPN Configuration (using Azure Certificate Authentication)
resource "azurerm_virtual_network_gateway_vpn_client_configuration" "p2s_config" {
  virtual_network_gateway_id = azurerm_virtual_network_gateway.vpn_gateway.id

  vpn_client_protocols = ["IkeV2"]

  azure_certificate_authority {
    certificate = file("path/to/your/ca_certificate.cer")
  }

  vpn_client_configuration {
    vpn_client_certificate {
      certificate = file("path/to/your/client_certificate.pfx")
      password    = "your-password"
    }
  }
}

# Output the VPN Client Configuration File URL
output "vpn_client_configuration_url" {
  value = azurerm_virtual_network_gateway_vpn_client_configuration.p2s_config.vpn_client_configuration_url
}
