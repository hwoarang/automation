#!/bin/bash

set -euo pipefail

OPENRC=$1
CHANNEL=$2

IMAGE_FILENAME=$(readlink ../downloads/openstack-${CHANNEL})
IMAGE_BUILD=$(echo $IMAGE_FILENAME | sed -n 's/.*\(Build.*\).qcow2/\1/p')
IMAGE_VERSION=$(echo $IMAGE_FILENAME | sed -n 's/.*CaaS-Platform-\(.*\)-\(for\|CaaSP\).*-OpenStack-Cloud.*/\1/p')
IMAGE_NAME="CaaSP-${CHANNEL}-${IMAGE_VERSION}-${IMAGE_BUILD}"

[[ -e $OPENRC ]] && source $OPENRC
echo "[+] Checking if we already have this image: $IMAGE_NAME"

if [[ $(openstack image list -c ID -f value --property caasp-version="${IMAGE_VERSION}" --property caasp-channel="${CHANNEL}" --property caasp-build="${IMAGE_BUILD}") != "" ]]; then
    echo "[+] Deleting previous SUSE CaaSP qcow2 VM image for {version=$IMAGE_VERSION, channel=$CHANNEL}"
    for images in $(openstack image list -c ID -f value --property caasp-version="${IMAGE_VERSION}" --property caasp-channel="${CHANNEL}"); do
        openstack image delete $images
    done
    echo "[+] Uploading SUSE CaaSP qcow2 VM image: $IMAGE_NAME"
    openstack image create $IMAGE_NAME --private --disk-format qcow2 --container-format bare --min-disk 40 --file $IMAGE_FILENAME \
        --property caasp-version="$IMAGE_VERSION" \
        --property caasp-build="$IMAGE_BUILD" \
        --property caasp-channel="$CHANNEL"
else
   echo "[+] Skipping upload, we already have this image"
fi
