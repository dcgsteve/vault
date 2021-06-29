#!/bin/bash

# Params
NIC="eth0"
IPPREFIX="192.168.1."
PREFIX=consul
SRVMAX=3

# Re-create network
docker network rm vault-consul
docker network create \
  --attachable \
  --driver=bridge \
  --subnet=${IPPREFIX}0/24 \
  --gateway=${IPPREFIX}254 vault-consul

# Build server list
SRVLST=""
for srv in $(eval echo "{1..$SRVMAX}")
do 
  SRVLST+="\"$IPPREFIX${srv}\""
  if [ $srv != ${SRVMAX} ]; then
    SRVLST+=", "
  fi
done

# Write out fresh server JSON
cat <<EOF > server.json
{
  "datacenter": "dcvault",
  "client_addr": "0.0.0.0",
  "leave_on_terminate": true, 
  "server": true, 
  "ui": true,
  "bootstrap_expect": ${SRVMAX},
  "acl_enforce_version_8": false, 
  "retry_join": [ ${SRVLST} ]
}
EOF

# Run Consul servers
# NB. ACL disabled for initial test - needs enabling later
#
for srv in $(eval echo "{1..$SRVMAX}")
do
  # Copy latest config
  mkdir -p /data/consul/${srv}/config
  cp server.json /data/consul/${srv}/config/server.json
  # Set up basic run command
  DRUN="--name=consul${srv} -h consul${srv} --restart=unless-stopped --network vault-consul -e CONSUL_BIND_INTERFACE=${NIC} -v /data/consul/${srv}/data:/consul/data -v /data/consul/${srv}/config:/consul/config -v /data/consul/${srv}/logs:/consul/logs --ip ${IPPREFIX}${srv}"
  # Add options
  OPT=""
  case "$srv" in
    1)
      DRUN+=" -p 8500:8500"
      ;;
    *)
      ;;
  esac
  # Finish command
  DRUN+=" consul agent --server ${OPT}"
    # Start server
  echo Starting server ${srv} ...
  docker run -d ${DRUN}
done
