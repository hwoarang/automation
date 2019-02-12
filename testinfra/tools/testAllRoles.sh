#!/bin/sh
set -eu

ENVIRONMENT=$1
SSH_CONFIG=$2
POSARGS=${3:-}

for role in "worker" "master" "admin"; do
    fqdns=$(jq -r "[.minions[] | select(.role==\"$role\") | .fqdn ] | join(\",\" )" $ENVIRONMENT)
    if [ -n "$fqdns" ]; then
        for fqdn in ${fqdns//,/ }; do
            status=$(jq -r "[.minions[] | select(.fqdn==\"$fqdn\") | .status ] | join(\",\" )" $ENVIRONMENT)
            pytest --ssh-config=$SSH_CONFIG --connection ssh --sudo -m "($role or common) and $status" --hosts $fqdn --junit-xml ${fqdn}.xml -v $POSARGS
        done
    fi
done
