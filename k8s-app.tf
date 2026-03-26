


resource "kubernetes_namespace" "app" {
            requests = {
              cpu    = "1000m"
              memory = "4Gi"
            }
            limits = {
              cpu    = "2000m"
              memory = "8Gi"
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "chat_ui" {
  metadata {
    name      = "llama3-ui-svc"
    namespace = kubernetes_namespace.app.metadata[0].name
  }

  spec {
    selector = {
      app = "llama3-ui"
    }

    port {
      port        = 80
      target_port = 7860
    }

    type = "ClusterIP"
  }
}

resource "kubernetes_ingress_v1" "chat_ui" {
  metadata {
    name      = "llama3-ui-ingress"
    namespace = kubernetes_namespace.app.metadata[0].name
    annotations = {
      "alb.ingress.kubernetes.io/scheme"      = "internet-facing"
      "alb.ingress.kubernetes.io/target-type" = "ip"
      "alb.ingress.kubernetes.io/healthcheck-path" = "/"
    }
  }

  spec {
    ingress_class_name = "alb"

    rule {
      host = var.app_hostname

      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = kubernetes_service.chat_ui.metadata[0].name
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }
}
