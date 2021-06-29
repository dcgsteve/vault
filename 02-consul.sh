#!/bin/bash

# Params
NIC="eth0"
NWORK="vault"
IPPREFIX="192.168.1."
PREFIX=consul

# Note: Single digit here please - if more needed, need to amend script to cater
SRVMAX=3

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
# NB. ACL disabled for initial test - needs enabling later!
for srv in $(eval echo "{1..$SRVMAX}")
do 
  # Create command
  DRUN=" \
    --name consul${srv} \
    -h consul${srv} \
    -e CONSUL_BIND_INTERFACE=${NIC} \
    -v /data/consul/${srv}/data:/consul/data \
    -v /data/consul/${srv}/config:/consul/config \
    -v /data/consul/${srv}/logs:/consul/logs \
    --network ${NWORK} \
    --ip ${IPPREFIX}${srv} \
    "
    #-p 1010${srv}:8500 \

  # Add any relevant options (NB. not currently used)
  OPT=""
  case "$srv" in
    *)
      ;;
  esac

  # Finish run command
  DRUN+=" consul agent --server ${OPT} --ui"

  # Ensure directories are ready
  mkdir -p /data/consul/$srv
  mkdir /data/consul/$srv/data
  mkdir /data/consul/$srv/config
  mkdir /data/consul/$srv/logs

  # Copy latest config
  cp server.json /data/consul/$srv/config/server.json

  # Start server
  #echo DBG docker run -d ${DRUN} 
  docker run -d ${DRUN} 

done