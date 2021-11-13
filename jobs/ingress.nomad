job "ingress" {
  region      = "[[ .nomad.region ]]"
  datacenters = ["[[ .nomad.datacenter ]]"]
  type        = "system"
  priority    = 100

  group "traefik" {
    count = 1

    network {
      port "http" { static = 80 }
      port "https" { static = 443 }
    }

    update {
      max_parallel     = 1
      min_healthy_time = "30s"
      auto_revert      = true
    }

    task "traefik" {
      driver = "docker"

      config {
        image        = "traefik:v2.5"
        network_mode = "host"
        ports        = ["http", "https"]
        volumes = [
          "local/traefik.toml:/etc/traefik/traefik.toml",
        ]
      }

      service {
        tags = [
          "traefik.enable=true",
          "traefik.http.routers.traefik-api.rule=HostRegexp(`traefik{domain:(\\.\\S+)*\\.?}`)",
          "traefik.http.routers.traefik-api.service=api@internal",
        ]

        check {
          name     = "alive"
          type     = "tcp"
          port     = "http"
          interval = "10s"
          timeout  = "2s"
        }
      }

      resources {
        cpu    = 100
        memory = 128
      }

      template {
        data = <<EOF
[global]
  checkNewVersion = false
  sendAnonymousUsage = false

[log]
[ping]

[entryPoints]
  [entryPoints.http]
  address = ":80"
  [entryPoints.https]
  address = ":443"
  [entryPoints.traefik]
  address = ":8080"

[api]
  dashboard = true
  insecure = true

[providers.consulCatalog]
  prefix           = "traefik"
  exposedByDefault = false

  [providers.consulCatalog.endpoint]
    address = "127.0.0.1:8500"
    scheme  = "http"
EOF

        destination = "local/traefik.toml"
      }
    }
  }
}