#cloud-config

write_files:
  - path: /etc/consul/consul.json
    content: |
      {
        "acl_enforce_version_8": false,
        "client_addr": "0.0.0.0",
        "advertise_addr": "{{ GetInterfaceIP \"ens5\" }}",
        "data_dir": "/srv/consul",
        "leave_on_terminate": true,
        "recursors": [
          "127.0.0.1"
        ],
        "retry_join": [
          "provider=aws tag_key=ConsulCluster tag_value=${consul_cluster} addr_type=private_v4\n"
        ],
        "acl_datacenter": "${datacenter}",
        "datacenter": "${datacenter}",
        "encrypt": "${encryption_key}",
        "service": {
          "checks": [],
          "id": "consul-client",
          "name": "consul-client",
          "port": 8500,
          "tags": [],
          "token": null
        }
      }

  - path: /etc/nomad/nomad.json
    content: |
      {
        "bind_addr": "0.0.0.0",
        "data_dir": "/srv/nomad/data",
        "leave_on_terminate": true,
        "client": { 
          "enabled": true
        },
        "datacenter": "${nomad_datacenter}",
        "region": "${nomad_region}",
        "consul": {
          "token": "${consul_token}",
          "address": "http://localhost:8500"
        } 
      }

runcmd:
  # Start Consul
  - systemctl start consul
  - systemctl start nomad
