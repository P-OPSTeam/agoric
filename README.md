# Agoric Node installer

## Summary
The agoric node installer will help in installing your agoric node and configure systemd automatically. The script will run until the node is fully synced before returning you the prompt.

## Prerequisites

- ubuntu 20
- decide on your moniker name (ie `POPS-Node`)
- know the GIT_BRANCH you need to use (ie `agoric-upgrade-5`)
- non root user with sudo privilege without password (see below for a snippet for user creation)

## How to use

### download the script

```bash
wget https://raw.githubusercontent.com/P-OPSTeam/agoric/master/install-agoric.sh && chmod +x install-agoric.sh 
wget https://raw.githubusercontent.com/P-OPSTeam/agoric/master/install-agoric.sh && chmod +x is-synced.sh 
```

### run the script

```bash
./install-agoric.sh <branch> <monikername>
```

## Testing

The script has been tested on an Hetzner CPX41 (8vcpu 16GB 240GB RAM) and node was syncing normally but expected to take multiple days to fully synced to the current mainnet agoric blocks at 4468312

## Others

### Install user

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