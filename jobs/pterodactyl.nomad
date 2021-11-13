job "pterodactyl" {
  region      = "[[ .nomad.region ]]"
  datacenters = ["[[ .nomad.datacenter ]]"]
  type        = "service"

  group "panel" {
    count = 1

    network {
      port "http" {}
    }

    service {
      port = "http"

      tags = [
        "traefik.enable=true",
        "traefik.http.routers.pterodactyl-panel.rule=HostRegexp(`pterodactyl{domain:(\\.\\S+)*\\.?}`)",
        "traefik.http.routers.pterodactyl-panel.service=api@internal",
      ]

      check {
        name     = "alive"
        type     = "tcp"
        port     = "http"
        interval = "10s"
        timeout  = "2s"
      }
    }

    task "web" {
      driver = "docker"

      config {
        image = "ccarney16/pterodactyl-panel:latest"
      }
    }
  }
}