# tunneling-sshd

A docker image with OpenSSH server configured for tunneling TCP connections.

Supported environment variables:

- `USER` - a login of a user (optional, default value: `anonymous`).
- `PASSWORD` - a password of that user (optional, default value is randomly generated).
- `AUTHORIZED_KEYS` - keys that should be written to ~/.ssh/authorized_keys (optional, default value: none).
- `AUTHORIZED_KEYS_PATH` - a path to a file that should be copied to ~/.ssh/authorized_keys (optional, default value: none).

## Typical usage

On the remote side:

```bash
docker run -d -p 443:22 -e USER=user -e PASSWORD=1234 sekogan/tunneling-ssh
```

Create a SOCKS proxy on your PC:

```bash
ssh -D 1234 -p 443 -N user@<your server url>
```

Then configure your browser to connect to the `localhost:1234` SOCKS proxy and verify it forwards all connections to the remote side.

## Testing

```bash
vagrant up
vagrant ssh
./test.sh
```