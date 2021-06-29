#!/bin/bash

# Params
NWORK="vault"
IPPREFIX="192.168.1."

# Remove
docker network rm ${NWORK}

# Re-create Docker network (as Swarm overlay)
docker network create \
  --attachable \
  --driver=bridge \
  --subnet=${IPPREFIX}0/24 \
  --gateway=${IPPREFIX}254 \
  ${NWORK}
