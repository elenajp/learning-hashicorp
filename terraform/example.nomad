job "http-server" {
  datacenter = ["dc1"]

  group "http-server" {
    count = 3

    network {
      port "http" {
        # Here you can expose the port 80 like the -p 80:80 that you with docker run
        # Have a look at https://www.nomadproject.io/docs/job-specification/network
        static = 8080
      }
    }


    task "http-server" {
      driver = "docker"
      config {
        image = "nginx"
        ports = ["http"]
      }
    }
  }
}