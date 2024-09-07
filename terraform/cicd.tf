# Запускаю GitLab Agent в k8s
resource "null_resource" "diplom-test-app-gitlab-agent" {
  provisioner "local-exec" {
    command = "helm repo add gitlab https://charts.gitlab.io && helm repo update && helm upgrade --install diplom-test-app gitlab/gitlab-agent --namespace gitlab-agent-diplom-test-app --create-namespace --set config.token=glagent-z4DxBjsLGm_PCKYxFY_xKsmsdWPWQzBn3WRMUVYihoCC9LXzLg --set config.kasAddress=wss://kas.gitlab.com"
  }
  depends_on = [
    null_resource.grafana_service
  ]
}



 
