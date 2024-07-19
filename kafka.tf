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
EOF
  ]

  depends_on = [module.eks, kubernetes_namespace.kafka]
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
