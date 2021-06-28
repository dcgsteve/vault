#!/bin/bash

# Params
NIC="eth0"
IP="192.168.1.2"
PREFIX=consul

# Re-create network
docker network rm vault-consul
docker network create \
  --attachable \
  --driver=bridge \
  --subnet=192.168.1.0/24 \
  --gateway=192.168.1.1 vault-consul

# Run initial lead agent
docker run -d \
  --name=${PREFIX}1 -h ${PREFIX}1 \
  --restart=unless-stopped \
  --network vault-consul \
  -e CONSUL_BIND_INTERFACE=${NIC} \
  -v /data/consul/1:/consul/data \
  --ip ${IP} \
  -p 8500:8500 \
  consul

# Run other agents using client mode
for agent in {2..5}; do 
  docker run -d \
    --name=${PREFIX}${agent} -h ${PREFIX}${agent} \
    --restart=unless-stopped \
    --network vault-consul \
    -e CONSUL_BIND_INTERFACE=${NIC} \
    -e 'CONSUL_LOCAL_CONFIG={"leave_on_terminate": true}' \
    -v /data/consul/$agent:/consul/data \
    consul \
    agent -join=${IP}
done
