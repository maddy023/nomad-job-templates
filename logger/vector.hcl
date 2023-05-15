job "vector" {
  datacenters = ["dc1"]
  type = "system"

  group "vector" {
    count = 1
    network {
      port "api" {
        to = 8686
      }
    }

    task "vector" {
      driver = "docker"
      config {
        image = "timberio/vector:0.25.X-alpine"
        ports = ["api"]
        volumes = [
          "/etc/nomad/:/etc/nomad/",
          "/var/run/docker.sock:/var/run/docker.sock"
        ]
      }
      # Vector won't start unless the sinks(backends) configured are healthy
      env {
        VECTOR_CONFIG = "local/vector.toml"
        VECTOR_REQUIRE_HEALTHY = "true"
      }
      resources {
        cpu    = 100 # 500 MHz
        memory = 100 # 256MB
      }
      template {
        destination = "local/vector.toml"
        change_mode   = "signal"
        change_signal = "SIGHUP"
        # overriding the delimiters to [[ ]] to avoid conflicts with Vector's native templating, which also uses {{ }}
        left_delimiter = "[["
        right_delimiter = "]]"
        data=<<EOH
          #data_dir = "/tmp/alloc/data"
          [sources.logs]
            type = "docker_logs"
            include_images = [<image_name>]

          [transforms.parse_json]
            type = "remap"
            inputs = ["logs"]
            source = '''
              . = parse_json!(.message)  
            '''
          [sinks.loki]
            type = "loki"
            inputs = ["parse_json"]
            endpoint = ""
            encoding.codec = "json"
            healthcheck.enabled = false
            auth.strategy = "basic"
            auth.user = "admin"
            auth.password = "<password>"
            labels.image = "{{ .image }}"
        EOH

      }

      service {
        check {
          port     = "api"
          type     = "http"
          path     = "/health"
          interval = "30s"
          timeout  = "5s"
        }
      }
      kill_timeout = "30s"
    }
  }
}