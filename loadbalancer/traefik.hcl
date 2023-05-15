job "traefik" {
  datacenters = ["dc1"]
  type        = "system"
  group "traefik" {
    count = 1

    network {
      port "http" {
        static = 8080
      }
      port "https" {
        static = 443
      }
    }

    service {
      name = "traefik"
      tags = [
          "traefik.http.routers.http-catchall.rule=hostregexp(`{host:[a-z-.]+}`)",
          "traefik.http.routers.http-catchall.entrypoints=web",
          "traefik.http.routers.http-catchall.middlewares=redirect-to-https",
          "traefik.http.middlewares.redirect-to-https.redirectscheme.scheme=https"
        ]
      check {
        name     = "alive"
        type     = "tcp"
        port     = "http"
        interval = "10s"
        timeout  = "2s"
      }
    }

    volume "traefik-volume" {
      type            = "host"
      source          = "traefik-volume"
      read_only = false
    }


    task "traefik" {
      driver = "docker"

      volume_mount {
        volume      = "traefik-volume"
        destination = "/data"
      }

      config {
        image        = "traefik:v2.9.8"
        network_mode = "host"


        volumes = [
          "local/traefik.toml:/etc/traefik/traefik.toml",
        ]
      }

      template {
        data = <<EOF
[entryPoints.web]
  address = ":80"

  [entryPoints.web.http]
    [entryPoints.web.http.redirections]
      [entryPoints.web.http.redirections.entryPoint]
        to = "websecure"
        scheme = "https"
        permanent = true

[entryPoints.websecure]
  address = ":443"

[certificatesResolvers.myresolver.acme]
  email = "<mailid>"
  storage = "data/acme.json"
  [certificatesResolvers.myresolver.acme.tlsChallenge]
  #
  [certificatesResolvers.myresolver.acme.dnsChallenge]
    resolvers = ["1.1.1.1:53", "8.8.8.8:53"]

[api]
    dashboard = false
    insecure  = false

# Enable Consul Catalog configuration backend.
[providers.consulCatalog]
    prefix           = "traefik"
    exposedByDefault = false

    [providers.consulCatalog.endpoint]
        address = "127.0.0.1:8500"
        scheme  = "http"
        datacenter = "dc1"
[log]
  level = "DEBUG"
EOF
        destination = "local/traefik.toml"
      }

      resources {
        cpu    = 300
        memory = 300
      }
    }
  }
}