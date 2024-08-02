resource "helm_release" "kafka" {
  name       = "kafka"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "kafka"
  namespace  = kubernetes_namespace.kafka.metadata[0].name

  values = [
    <<EOF
listeners:
  client:
    protocol: PLAINTEXT
  controller:
    protocol: PLAINTEXT
  interbroker:
    protocol: PLAINTEXT  
provisioning:
  enabled: true
  replicationFactor: 3
  numPartitions: 3  
  topics:
    - name: cve
      replicationFactor: 3
      partitions: 3 
controller:
  persistence:
    size: 1Gi
  initContainerResources:
    requests:
      memory: "50Mi"
      cpu: "50m"
    limits:
      memory: "100Mi"
      cpu: "100m"
  resources:
    requests:
      memory: "500Mi"
      cpu: "100m"
    limits:
      memory: "850Mi"
      cpu: "1"
metrics:
  jmx:
    enabled: true   
EOF
  ]

  depends_on = [module.eks, kubernetes_namespace.kafka, helm_release.kafka_exporter]
}


# resource "helm_release" "postgres" {
#   name       = "postgres"
#   repository = "https://charts.bitnami.com/bitnami"
#   chart      = "postgresql"
#   namespace  = kubernetes_namespace.webapp_cve_consumer.metadata[0].name

#   values = [
#     <<EOF
#       postgresql:
#         auth:
#           postgresPassword: "postgres123"
#           username: "vamsi"
#           password: "postgres"
#           database: "cve"
#           service:
#         service:
#           ports:
#             postgresql: "5432"   
#       resourcesPreset: "medium"    
# EOF
#   ]

#   depends_on = [module.eks, kubernetes_namespace.webapp_cve_consumer]
# }


resource "helm_release" "postgres" {
  name       = "postgres"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "postgresql"
  namespace  = kubernetes_namespace.webapp_cve_consumer.metadata[0].name

  values = [
    <<EOF
global:    
  postgresql:
    auth:
      postgresPassword: "postgres123"
      username: "vamsi"
      password: "postgres"
      database: "cve"
    service:
      ports:
        postgresql: "5432"
primary:        
  resourcesPreset: "medium"
  networkPolicy:  
    enabled: false
metrics:  
  enabled: true  
EOF
  ]

  depends_on = [module.eks, kubernetes_namespace.webapp_cve_consumer]
}

resource "helm_release" "cluster_autoscaler" {
  name = "cluster-autoscaler"
  # repository = "https://kubernetes.github.io/autoscaler"
  chart     = "https://x-access-token:${var.github_token}@github.com/cyse7125-su24-team04/helm-eks-autoscaler/archive/refs/tags/v${var.autoscaler_version}.tar.gz"
  namespace = kubernetes_namespace.cluster_autoscaler.metadata[0].name
  # version   = "9.37.0" # Use the desired version

  set {
    name  = "secrets.dockerConfigJson"
    value = "ICB7ImF1dGhzIjogeyJodHRwczovL2luZGV4LmRvY2tlci5pby92MS8iOiB7InVzZXJuYW1lIjogInZhbXNpZGhhcnAiLCAicGFzc3dvcmQiOiAiZGNrcl9wYXRfdW1uWXdHeE9SUjZUT2JONG9oYmprMndFYkpZIiwgImVtYWlsIjogInBhbml0aGkudkBub3J0aGVhc3Rlcm4uZWR1IiwgImF1dGgiOiAiZG1GdGMybGthR0Z5Y0Rwa1kydHlYM0JoZEY5MWJXNVpkMGQ0VDFKU05sUlBZazQwYjJoaWFtc3lkMFZpU2xrPSJ9fX0K"
  }
  set {
    name  = "autoDiscovery.clusterName"
    value = module.eks.cluster_name
  }
  set {
    name  = "autoDiscovery.enabled"
    value = "true"
  }
  set {
    name  = "awsRegion"
    value = var.region
  }
  set {
    name  = "rbac.serviceAccount.create"
    value = "true"
  }

  set {
    name  = "rbac.serviceAccount.name"
    value = "cluster-autoscaler"
  }
  set {
    name  = "rbac.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.cluster_autoscaler_role.arn
  }


  depends_on = [module.eks, kubernetes_namespace.cluster_autoscaler]
}

resource "helm_release" "fluent_bit" {
  name       = "cloudwatch"
  chart      = "https://x-access-token:${var.github_token}@github.com/cyse7125-su24-team04/helm-cloudewatch/archive/refs/tags/v${var.fluent_bit_version}.tar.gz"
  namespace  = kubernetes_namespace.cloud_watch.metadata[0].name
  depends_on = [module.eks, kubernetes_namespace.cloud_watch]

}

resource "helm_release" "prometheus" {
  name       = "grafana-prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name

  values = [
    <<EOF
prometheus:
  prometheusSpec:    
    additionalScrapeConfigs:
      - job_name: 'postgresql'
        static_configs:
          - targets: 
            - 'postgres-postgresql-metrics.webapp-cve-consumer.svc.cluster.local:9187'
      - job_name: 'kafka'
        static_configs:
          - targets: 
            - 'kafka-jmx-metrics.kafka.svc.cluster.local:5556' 
EOF
  ]
}

resource "helm_release" "kafka_exporter" {
  name       = "kafka-exporter"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus-kafka-exporter"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name

  values = [
    <<EOF
kafkaServer:
  - kafka.kafka.svc.cluster.local:9092
prometheus:
  serviceMonitor:
    enabled: true
    namespace: monitoring
    additionalLabels:
      release: grafana-prometheus  
EOF
  ]

}

resource "helm_release" "istio-base" {
  name       = "istio-base"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "base"
  namespace  = kubernetes_namespace.istio.metadata[0].name
  depends_on = [kubernetes_namespace.istio]
}

resource "helm_release" "istiod" {
  name       = "istiod"
  chart      = "./istiod"
  namespace  = kubernetes_namespace.istio.metadata[0].name
  depends_on = [helm_release.istio-base, kubernetes_namespace.istio]

}

resource "helm_release" "istio-gateway" {
  name       = "istio-gateway"
  chart      = "./gateway"
  namespace  = kubernetes_namespace.istio.metadata[0].name
  depends_on = [helm_release.istiod]

}

resource "helm_release" "external-dns" {
  depends_on = [kubernetes_namespace.external_dns]
  name       = "external-dns"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "external-dns"
  namespace  = kubernetes_namespace.external_dns.metadata[0].name
  set {
    name  = "domainFilters[0]"
    value = "dev.csye6225cloud.me"
  }

  set {
    name  = "txtOwnerId"
    value = "Z03666913JAM947E1XPH4"
  }
}
