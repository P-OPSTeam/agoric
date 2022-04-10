#!/bin/bash

# this script has been developped by the pops team pops.one
# it's used to install the agoric node on an ubuntu 18.04 on a newly build VPS

# usage
# ./install-agoric.sh GIT_BRANCH MONIKER
# ie ./install-agoric.sh agoric-upgrade-5 pops-moniker

GIT_BRANCH=$1
MONIKER=$2

if [[ -z "$GIT_BRANCH" || -z "$MONIKER" ]]; then
  echo "
  usage
  # ./install-agoric.sh GIT_BRANCH MONIKER
  # ie ./install-agoric.sh agoric-upgrade-5 pops-moniker
  "
  exit 1
fi

# Update Ubuntu
sudo apt update
sudo apt upgrade -y

# make sure all tools used are installed
sudo apt install curl git sed jq -y

# Install build tools
sudo apt install build-essential -y

# Install correct Go version
sudo rm -rf /usr/local/go
curl https://dl.google.com/go/go1.17.7.linux-amd64.tar.gz | sudo tar -C /usr/local -xzf -

# Update environment variables to include go
cat <<'EOF' >>$HOME/.profile
export GOROOT=/usr/local/go
export GOPATH=$HOME/go
export GO111MODULE=on
export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin
EOF
# shellcheck source=/dev/null
source "$HOME/.profile"

# install agoric
git clone https://github.com/Agoric/ag0 -b "${GIT_BRANCH}"
cd ag0 || exit 1
make install
mv /root/go/bin/ag0 /usr/local/bin/agd

# find the non sudoer user
if [ "$SUDO_USER" ]; then USER=$SUDO_USER; else USER=$(whoami); fi

# network configuration
# First, get the network config for the current network.
curl https://main.agoric.net/network-config > chain.json
# Set chain name to the correct value
chainName=$(jq -r .chainName < chain.json)
# Confirm value: should be something like agoric-N.
echo "$chainName"

agd init --chain-id ${chainName} ${MONIKER}

# Download the genesis file
curl https://main.agoric.net/genesis.json > $HOME/.agoric/config/genesis.json 
# Reset the state of your validator.
$HOME/go/bin/agd unsafe-reset-all

# fix configuration file
# Set peers variable to the correct value
peers=$(jq '.peers | join(",")' < chain.json)
# Set seeds variable to the correct value.
seeds=$(jq '.seeds | join(",")' < chain.json)


# Fix `Error: failed to parse log level`
sed -i.bak 's/^log_level/# log_level/' $HOME/.agoric/config/config.toml
# Replace the seeds and persistent_peers values
sed -i.bak -e "s/^seeds *=.*/seeds = $seeds/; s/^persistent_peers *=.*/persistent_peers = $peers/" $HOME/.agoric/config/config.toml

# create unit file
sudo tee <<EOF >/dev/null /etc/systemd/system/agd.service
[Unit]
Description=Agoric Cosmos daemon
After=network-online.target
[Service]
User=$USER
ExecStart=/usr/local/bin/agd start --log_level=warn
Restart=on-failure
RestartSec=3
LimitNOFILE=4096
[Install]
WantedBy=multi-user.target
EOF

# Check the contents of the file, especially User, Environment and ExecStart lines
# cat /etc/systemd/system/.agoric.service

# start node and sync
sudo systemctl enable agd
sudo systemctl daemon-reload
sudo systemctl start agd

echo "pausing 60s for the service to be fully started"
sleep 60

# confirm that the node is fully synced
for (( ; ; )); do
  sync_info=$(/usr/local/bin/agd status 2>&1 | jq .SyncInfo)
  echo "$sync_info"
  if test "$(echo "$sync_info" | jq -r .catching_up)" == false; then
    echo "Caught up"
    break
  fi
  sleep 5
done

# exit message
echo "congrats your node has been fully installed and synced"
echo "you can now proceed with the validator creation"

# remind to source .profile
echo "please source the profile file: "
echo "source \$HOME/.profile"