resource "azurerm_resource_group" "rgs" {
  for_each = var.rg_config

  name     = each.value.name
  location = each.value.location
}