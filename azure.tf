# =============================================================================
# AZURE INFRASTRUCTURE
# =============================================================================

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = "rg-yoobee-${var.environment}"
  location = "Australia East"

  tags = {
    Project     = "Yoobee-Migration"
    Environment = var.environment
  }
}

# Azure DNS Zone
resource "azurerm_dns_zone" "main" {
  name                = var.domain_name
  resource_group_name = azurerm_resource_group.main.name

  tags = {
    Project     = "Yoobee-Migration"
    Environment = var.environment
  }
}

# DNS CNAME record pointing to AWS ALB
resource "azurerm_dns_cname_record" "www" {
  name                = "www"
  zone_name           = azurerm_dns_zone.main.name
  resource_group_name = azurerm_resource_group.main.name
  ttl                 = 300
  record              = aws_lb.main.dns_name

  tags = {
    Project     = "Yoobee-Migration"
    Environment = var.environment
  }
}