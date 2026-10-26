#Create resource group. Within Terraform the name is BobsWorld and also in Azure
//resource "azurerm_resource_group" "BobsWorld" {
//  name     = "BobsWorld"
//  location = "eastus2"
//
//  tags = {
//    owner = "JenkinsPipeline"
//  }
//}
//resource "azurerm_resource_group" "BobsWorld2" {
//  name     = "BobsWorld2"
//  location = "eastus2"
//
//  tags = {
//    owner = "JenkinsPipeline"
//  }
//}
////This time we defined the name in the variables.tf
//resource "azurerm_resource_group" "rg" {
//  name     = var.resource_group_name
//  location = "eastus2"
//
//  tags = {
//    owner = "JenkinsPipeline"
//  }
//}

##Section adding VM creation 
resource "azurerm_resource_group" "vm_rg" {
  name     = "${var.environment}-resource-group"
  location = "northcentralus"
}

resource "azurerm_virtual_network" "vm_vnet" {
  name                = "${var.environment}-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.vm_rg.location
  resource_group_name = azurerm_resource_group.vm_rg.name
}

resource "azurerm_subnet" "vm_subnet" {
  name                 = "${var.environment}-subnet"
  resource_group_name  = azurerm_resource_group.vm_rg.name
  virtual_network_name = azurerm_virtual_network.vm_vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_linux_virtual_machine" "vm" {
  name                = "${var.environment}-machine"
  resource_group_name = azurerm_resource_group.vm_rg.name
  location            = azurerm_resource_group.vm_rg.location
  size                = "Standard_B2as_v2"
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.vm_nic.id,
  ]

admin_ssh_key {
  username   = "adminuser"
  public_key = file("/opt/tf-keys/adminuser.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}
resource "azurerm_network_interface" "vm_nic" {
  name                = "${var.environment}-nic"
  location            = azurerm_resource_group.vm_rg.location
  resource_group_name = azurerm_resource_group.vm_rg.name

  ip_configuration {
    name                          = "${var.environment}-internal-ip"
    subnet_id                     = azurerm_subnet.vm_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}