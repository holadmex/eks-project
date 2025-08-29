# Prometheus and Grafana using kube-prometheus-stack
resource "helm_release" "kube_prometheus_stack" {
  namespace        = "monitoring"
  create_namespace = true
  name             = "kube-prometheus-stack"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  version          = "54.0.0"
  timeout          = 600
  wait             = true

  values = [
    yamlencode({
      prometheus = {
        prometheusSpec = {
          retention = "30d"
          storageSpec = {
            volumeClaimTemplate = {
              spec = {
                storageClassName = "gp2"
                accessModes      = ["ReadWriteOnce"]
                resources = {
                  requests = {
                    storage = "50Gi"
                  }
                }
              }
            }
          }
        }
      }
      grafana = {
        persistence = {
          enabled          = true
          storageClassName = "gp2"
          size             = "10Gi"
        }
        adminPassword = "admin123"
        service = {
          type = "LoadBalancer"
        }
      }
      alertmanager = {
        alertmanagerSpec = {
          storage = {
            volumeClaimTemplate = {
              spec = {
                storageClassName = "gp2"
                accessModes      = ["ReadWriteOnce"]
                resources = {
                  requests = {
                    storage = "10Gi"
                  }
                }
              }
            }
          }
        }
      }
    })
  ]

  depends_on = [aws_eks_node_group.eks_nodes_1]
}

# # EFK Stack (Elasticsearch, Fluentd, Kibana)
# resource "helm_release" "elasticsearch" {
#   namespace        = "logging"
#   create_namespace = true
#   name             = "elasticsearch"
#   repository       = "https://helm.elastic.co"
#   chart            = "elasticsearch"
#   version          = "8.5.1"
#   timeout          = 600
#   wait             = true

#   values = [
#     yamlencode({
#       replicas           = 1
#       minimumMasterNodes = 1
#       esConfig = {
#         "elasticsearch.yml" = "xpack.security.enabled: false\n"
#       }
#       resources = {
#         requests = {
#           cpu    = "100m"
#           memory = "512Mi"
#         }
#         limits = {
#           cpu    = "1000m"
#           memory = "2Gi"
#         }
#       }
#       volumeClaimTemplate = {
#         accessModes      = ["ReadWriteOnce"]
#         storageClassName = "gp2"
#         resources = {
#           requests = {
#             storage = "30Gi"
#           }
#         }
#       }
#     })
#   ]

#   depends_on = [aws_eks_node_group.eks_nodes_1]
# }

# resource "helm_release" "kibana" {
#   namespace  = "logging"
#   name       = "kibana"
#   repository = "https://helm.elastic.co"
#   chart      = "kibana"
#   version    = "8.5.1"
#   timeout    = 600
#   wait       = true

#   values = [
#     yamlencode({
#       elasticsearchHosts = "http://elasticsearch-master:9200"
#       service = {
#         type = "LoadBalancer"
#       }
#     })
#   ]

#   depends_on = [helm_release.elasticsearch]
# }

# resource "helm_release" "filebeat" {
#   namespace  = "logging"
#   name       = "filebeat"
#   repository = "https://helm.elastic.co"
#   chart      = "filebeat"
#   version    = "8.5.1"
#   timeout    = 600
#   wait       = true

#   values = [
#     yamlencode({
#       filebeatConfig = {
#         "filebeat.yml" = <<EOF
# filebeat.inputs:
# - type: container
#   paths:
#     - /var/log/containers/*.log
#   processors:
#     - add_kubernetes_metadata:
#         host: $${NODE_NAME}
#         matchers:
#         - logs_path:
#             logs_path: "/var/log/containers/"

# output.elasticsearch:
#   host: '$${NODE_NAME}'
#   hosts: '["http://elasticsearch-master:9200"]'
# EOF
#       }
#       daemonset = {
#         enabled = true
#       }
#     })
#   ]

#   depends_on = [helm_release.elasticsearch]
# }