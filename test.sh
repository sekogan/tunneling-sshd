#!/bin/bash
set -Eeuo pipefail

docker_image_name="test_image"
docker_container_name="test_container"
test_string="expected"
test_file="test-file"

# Setup

function cleanup() {
  killall ssh &>/dev/null || true
  docker stop $docker_container_name &>/dev/null || true
  docker rm $docker_container_name &>/dev/null || true
  docker rmi -f $docker_image_name &>/dev/null || true
  [ -f $test_file ] && rm $test_file || true
}

function print_result() {
  echo -e "\n\n--- $1\n\n\n"
}

trap cleanup EXIT
trap "print_result 'FAILED'" ERR

cleanup

echo '~~~ Initializing...'
echo "$test_string" > $test_file
docker build --tag $docker_image_name .

# Tests

echo "--- OpenSSH is installed"
docker run --rm $docker_image_name which sshd

echo "--- /sshd_config is added"
docker run --rm $docker_image_name test -f /sshd_config

echo "--- Host key is generated"
docker run --rm $docker_image_name test -f /etc/ssh/ssh_host_rsa_key

echo "--- authorized_keys is written"
docker run --rm -e USER=user -e AUTHORIZED_KEYS="$test_string" $docker_image_name grep "$test_string" /home/user/.ssh/authorized_keys
docker run --rm -e USER=user -e AUTHORIZED_KEYS_PATH="/test/$test_file" -v "$(pwd):/test" $docker_image_name grep "$test_string" /home/user/.ssh/authorized_keys


echo "--- TCP connections are forwarded"
echo "Starting the container..."
docker run -d -p 15000:22 -e USER=user -e PASSWORD=12345 \
  --name $docker_container_name $docker_image_name
retries=10
while [ $retries -ne 0 ]; do
  (( retries-- ))
  sleep 1
  echo "Starting client side ssh..."
  killall ssh || true
  sshpass -p 12345 ssh -p 15000 -N -D 15001 user@localhost \
    -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null &
  sleep 1
  echo "Testing the connection..."
  curl --socks5-hostname localhost:15001 https://github.com &>/dev/null || continue
  break
done
test $retries -ne 0
killall ssh


echo "--- TCP connections are forwarded after restart"
echo "Restarting the container..."
docker stop $docker_container_name
docker start $docker_container_name
retries=10
while [ $retries -ne 0 ]; do
  (( retries-- ))
  echo "Starting client side ssh..."
  killall ssh || true
  sshpass -p 12345 ssh -p 15000 -N -D 15001 user@localhost \
    -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null &
  sleep 1
  echo "Testing the connection..."
  curl --socks5-hostname localhost:15001 https://github.com &>/dev/null || continue
  break
done
test $retries -ne 0
echo "Cleaning up..."
killall ssh
docker stop $docker_container_name
docker rm $docker_container_name


# All done

print_result 'PASSED'
