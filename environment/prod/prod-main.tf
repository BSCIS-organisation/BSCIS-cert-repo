module "module_rg" {
    source = "../../modules/azurerm_resource_group"
    rg_config = var.prod-rg
}

module "module_stg" {
    source = "../../modules/azurerm_storage_account"
    stg_config = var.prod-stg

    depends_on = [ module.module_rg ]
    
}   


module "module_vnet" {
    source = "../../modules/azurerm_virtual_network"
    vnet_config = var.prod-vnet

    depends_on = [ module.module_rg ]
    
}   


module "module_subnet" {
    source = "../../modules/azurerm_subnet"
    subnet_config = var.prod-subnet

    depends_on = [ module.module_rg , module.module_vnet ]
    
}   
