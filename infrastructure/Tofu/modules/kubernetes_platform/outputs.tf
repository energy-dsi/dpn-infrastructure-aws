output "application_namespace" {
  value = kubernetes_namespace.applications.metadata[0].name
}

output "platform_namespace" {
  value = kubernetes_namespace.platform.metadata[0].name
}