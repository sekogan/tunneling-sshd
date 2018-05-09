#!/bin/sh

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
    echo "AllowUsers $USER" >> /sshd_config

    if [ ! -z "$AUTHORIZED_KEYS" ]; then
        HOME=/home/$USER
        mkdir $HOME/.ssh
        chmod 0700 $HOME/.ssh
        echo "$AUTHORIZED_KEYS" > $HOME/.ssh/authorized_keys
        chown -R $USER:$USER $HOME/.ssh
    fi

    touch /initialized
fi

[ $1 ] && exec "$@"
