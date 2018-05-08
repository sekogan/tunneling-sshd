#!/bin/bash
set -Eeuo pipefail

docker_image_name="docker_image"

# Setup

function cleanup() {
  echo '~~~ Cleaning Docker'
  docker rmi -f $docker_image_name
}

function print_result() {
  echo -e "\n\n--- $1\n\n\n"
}

trap cleanup EXIT
trap "print_result 'FAILED'" ERR

echo '~~~ Building Docker test image'

docker build --tag $docker_image_name .

# Tests

echo "--- OpenSSH is installed"
docker run --rm $docker_image_name which sshd

echo "--- /sshd_config is added"
docker run --rm $docker_image_name test -f /sshd_config

echo "--- Host key is generated"
docker run --rm $docker_image_name test -f /etc/ssh/ssh_host_rsa_key

# All done

print_result 'PASSED'
