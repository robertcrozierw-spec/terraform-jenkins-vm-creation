#Output the resource group ID of the resource group holding all the VM components.
output "resource_group_azure_id" {
  description = "The fully qualified Azure Resource ID of the resource group."
  value       = azurerm_resource_group.vm_rg.id
}
