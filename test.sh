#!/bin/bash
set -Eeuo pipefail

docker_image_name="test_image"
docker_container_name="test_container"

# Setup

function cleanup() {
  echo '~~~ Cleanup'
  killall ssh 2>/dev/null || true
  docker stop $docker_container_name 2>/dev/null || true
  docker rmi -f $docker_image_name 2>/dev/null || true
}

function print_result() {
  echo -e "\n\n--- $1\n\n\n"
}

trap cleanup EXIT
trap "print_result 'FAILED'" ERR

cleanup

echo '~~~ Building Docker test image'
docker build --tag $docker_image_name .

# Tests

echo "--- OpenSSH is installed"
docker run --rm $docker_image_name which sshd

echo "--- /sshd_config is added"
docker run --rm $docker_image_name test -f /sshd_config

echo "--- Host key is generated"
docker run --rm $docker_image_name test -f /etc/ssh/ssh_host_rsa_key

echo "--- TCP connections are forwarded"
echo "Starting the container..."
docker run -d --rm -p 15000:22 -e USER=user -e PASSWORD=12345 \
  --name $docker_container_name $docker_image_name
sleep 2
echo "Starting client side ssh..."
sshpass -p 12345 ssh -p 15000 -N -D 15001 user@localhost \
  -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null &
sleep 1
echo "Testing the connection..."
curl --socks5-hostname localhost:15001 https://github.com >/dev/null


# All done

print_result 'PASSED'
