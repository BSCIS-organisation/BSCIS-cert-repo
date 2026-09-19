module "module_rg" {
    source = "../../modules/azurerm_resource_group"
    rg_config = var.dev-rg
}

module "module_stg" {
    source = "../../modules/azurerm_storage_account"
    stg_config = var.dev-stg

    depends_on = [ module.module_rg ]
}   


module "module_vnet" {
    source = "../../modules/azurerm_virtual_network"
    vnet_config = var.dev-vnet

    depends_on = [ module.module_rg ]
    
}   


module "module_subnet" {
    source = "../../modules/azurerm_subnet"
    subnet_config = var.dev-subnet

    depends_on = [ module.module_rg , module.module_vnet ]
    
}   
