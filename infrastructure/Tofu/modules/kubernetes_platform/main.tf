resource "kubernetes_namespace" "applications" {
  metadata {
    name = var.application_namespace

    labels = {
      name        = var.application_namespace
      environment = "dev"
      managed_by  = "opentofu"
    }
  }
}

resource "kubernetes_namespace" "platform" {
  metadata {
    name = "platform"

    labels = {
      name       = "platform"
      managed_by = "opentofu"
    }
  }
}

resource "kubernetes_service_account" "aws_load_balancer_controller" {
  metadata {
    name      = "aws-load-balancer-controller"
    namespace = kubernetes_namespace.platform.metadata[0].name

    annotations = {
      "eks.amazonaws.com/role-arn" = var.alb_controller_role_arn
    }

    labels = {
      "app.kubernetes.io/name"       = "aws-load-balancer-controller"
      "app.kubernetes.io/managed-by" = "opentofu"
    }
  }
}

resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  namespace  = kubernetes_namespace.platform.metadata[0].name
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = var.alb_controller_chart_version

  set {
    name  = "clusterName"
    value = var.cluster_name
  }

  set {
    name  = "region"
    value = var.aws_region
  }

  set {
    name  = "vpcId"
    value = var.vpc_id
  }

  set {
    name  = "image.repository"
    value = "public.ecr.aws/eks/aws-load-balancer-controller"
  }

  set {
    name  = "image.tag"
    value = var.alb_controller_image_tag
  }

  set {
    name  = "serviceAccount.create"
    value = "false"
  }

  set {
    name  = "serviceAccount.name"
    value = kubernetes_service_account.aws_load_balancer_controller.metadata[0].name
  }

  depends_on = [
    kubernetes_service_account.aws_load_balancer_controller
  ]
}