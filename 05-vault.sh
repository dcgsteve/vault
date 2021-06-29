#!/bin/bash

# Params
SRVMAX=1
CONSULLB="http://192.168.1.1:8500"

# Write fresh Vault config
cat <<EOF > vault.hcl
// Enable UI
ui = true
api_addr = "http://0.0.0.0:8200"
 
// Consul storage
storage "consul" {
  address = "192.168.1.1:8500"
  path = "vault/"
  scheme = "http"
  redirect_addr = "http://127.0.0.1:8200"
  VAULT_ADDR = "http://127.0.0.1:8200"
}
 
// TCP Listener
listener "tcp" {
  address = "0.0.0.0:8200"
  tls_disable = "true"
}
EOF

# Run Vault servers
#
for srv in $(eval echo "{1..$SRVMAX}")
do
  # Copy latest config
  mkdir -p /data/vault/${srv}/config
  cp vault.hcl /data/vault/${srv}/config/vault.hcl

  # Set up basic run command
  DRUN="\
    --name=vault${srv} \
    -h vault${srv} \
    --restart=unless-stopped \
    --network vault-consul \
    --cap-add IPC_LOCK \
    -v /data/vault/${srv}/config:/vault/config \
  "
  # Finish run command
  #DRUN+=" vault server --config /vault/config/vault.hcl"
  DRUN+=" vault server"

    # Start server
  echo DBG - ${DRUN}
  docker run -d ${DRUN} 

done

