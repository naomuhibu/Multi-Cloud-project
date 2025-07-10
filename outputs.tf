output "alb_dns_name" {
  description = "The DNS name of the AWS Application Load Balancer"
  value       = aws_lb.main.dns_name
}

output "azure_dns_zone_name_servers" {
  description = "The name servers for the Azure DNS Zone"
  value       = azurerm_dns_zone.main.name_servers
}

output "wordpress_public_url" {
  description = "The public URL for the WordPress application"
  value       = "https://www.${var.domain_name}"
}