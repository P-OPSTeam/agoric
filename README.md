# Agoric Node installer

## Summary
The agoric node installer will help in installing your agoric node and configure systemd automatically. The script will run until the node is fully synced before returning you the prompt.

## Prerequisites

- ubuntu 20
- decide on your moniker name (ie `POPS-Node`)
- know the GIT_BRANCH you need to use (ie `@agoric/sdk@2.15.1`)
- non root user with sudo privilege without password (see below for a snippet for user creation)

## How to use

### download the script

```bash
wget https://raw.githubusercontent.com/pops-one/agoric/master/install-agoric.sh && chmod +x install-agoric.sh
```

### run the script

```bash
./install-agoric.sh @agoric/sdk@2.15.1 POPS-Node
```

## Testing

the script has been tested on an Hetzner CPX21 (3vcpu 4GB 80GB RAM) and took almost 1h30 min to fully synced until blocks 53200. It is noted that during the package upgrade, sshd is being updated and a manual intervention at the beginning was required

## Others

### Install a users

snipper below is supposed to be run with sudo or root user privilege

```bash
USER=pops
useradd -s /bin/bash -d /home/${USER}/ -m -G sudo ${USER}
echo "${USER}     ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
```

if you have your own ssh key to be used
```bash
cat<<-EOF > /home/${USER}/.ssh/authorized_keys
ssh-ed25519 AAAAC3NzaC1lZDENTE5AAABIEAaDXj9KD9QD4brV9CwR0ZaWz1wfwDInAp31VOwq42H1 your.sshkey.here
EOF
chown ${USER}:${USER} /home/${USER}/.ssh
chown ${USER}:${USER} /home/${USER}/.ssh/authorized_keys
```