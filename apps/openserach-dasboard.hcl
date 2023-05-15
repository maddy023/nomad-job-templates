job "opensearch-dashboard" {
  datacenters = ["dc1"]
  group "opensearch-dashboard-group" {
    count = 1
    network {
      port "http" {
        to = 5601
      }
    }
    task "opensearch-dashboard-task" {
      driver = "docker"
      config {
        image = "opensearchproject/opensearch-dashboards:2.3.0"
        ports = ["http"]
        # DO NOT CHANGE
        ulimit {
            memlock = "-1"
            nofile  = "65536"
            nproc   = "8192"
          }
      }
      env {
        OPENSEARCH_HOSTS = "https://domain.co"
        OPENSEARCH_USERNAME = "**"
        OPENSEARCH_PASSWORD = "**
      }
      resources {
        cpu    = 1000
        memory = 800
      }
      service {
        name = "opensearch-dashboard"
        port = "http"
      }
    }
  }
}