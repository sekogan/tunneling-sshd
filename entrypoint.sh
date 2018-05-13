#!/bin/sh

set -e

apk update
apk upgrade

if [ ! -f /initialized ]; then

    /usr/bin/ssh-keygen -A

    if [ -z "$USER" ]; then
        USER="anonymous"
    fi
    if [ -z "$PASSWORD" ]; then
        PASSWORD="$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c16)"
    fi
    adduser -D -s /bin/false $USER
    echo "$USER:$PASSWORD" | chpasswd
    unset PASSWORD
    echo "AllowUsers $USER" >> /sshd_config

    HOME=/home/$USER
    mkdir -p $HOME/.ssh
    if [ ! -z "$AUTHORIZED_KEYS" ]; then
        echo "$AUTHORIZED_KEYS" > $HOME/.ssh/authorized_keys
        unset AUTHORIZED_KEYS
    elif [ ! -z "$AUTHORIZED_KEYS_PATH" ]; then
        cp "$AUTHORIZED_KEYS_PATH" $HOME/.ssh/authorized_keys
        unset AUTHORIZED_KEYS_PATH
    fi
    chmod 0700 $HOME/.ssh
    chown -R $USER:$USER $HOME/.ssh

    touch /initialized
fi

[ $1 ] && exec "$@"
