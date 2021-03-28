#!/bin/bash

# this script has been developped by the pops team pops.one
# it's used to install the agoric node on an ubuntu 18.04 on a newly build VPS

# usage
# sudo install-agoric.sh GIT_BRANCH MONIKER
# ie sudo install-agoric.sh @agoric/sdk@2.15.1 Test-moniker

GIT_BRANCH=$1
MONIKER=$2

apt update
apt install -y curl git jq

# install nodejs
# Download the nodesource PPA for Node.js
curl https://deb.nodesource.com/setup_12.x | bash

# Download the Yarn repository configuration
# See instructions on https://legacy.yarnpkg.com/en/docs/install/
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list

# Update Ubuntu
apt update
apt upgrade -y

# Install Node.js, Yarn, and build tools
# Install jq for formatting of JSON data
apt install nodejs=12.* yarn build-essential jq -y


# Install correct Go version
curl https://dl.google.com/go/go1.15.7.linux-amd64.tar.gz | tar -C/usr/local -zxvf -

# Update environment variables to include go
cat <<'EOF' >>$HOME/.profile
export GOROOT=/usr/local/go
export GOPATH=$HOME/go
export GO111MODULE=on
export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin
EOF
source $HOME/.profile

# install agoric
git clone https://github.com/Agoric/agoric-sdk -b ${GIT_BRANCH}
cd agoric-sdk

# Install and build Agoric Javascript packages
yarn install
yarn build

# Install and build Agoric Cosmos SDK support
cd packages/cosmic-swingset && make


# network configuration
curl https://testnet.agoric.net/network-config > chain.json
chainName=`jq -r .chainName < chain.json`
# Confirm value: should be something like agorictest-N.
echo $chainName

ag-chain-cosmos init --chain-id $chainName ${MONIKER}

# fix configuration file
# Set peers variable to the correct value
peers=$(jq '.peers | join(",")' < chain.json)
# Set seeds variable to the correct value.
seeds=$(jq '.seeds | join(",")' < chain.json)


# Fix `Error: failed to parse log level`
sed -i.bak 's/^log_level/# log_level/' $HOME/.ag-chain-cosmos/config/config.toml
# Replace the seeds and persistent_peers values
sed -i.bak -e "s/^seeds *=.*/seeds = $seeds/; s/^persistent_peers *=.*/persistent_peers = $peers/" $HOME/.ag-chain-cosmos/config/config.toml
# Fix `Error: failed to parse log level`
sed -i.bak 's/^log_level/# log_level/' $HOME/.ag-chain-cosmos/config/config.toml
# Replace the seeds and persistent_peers values
sed -i.bak -e "s/^seeds *=.*/seeds = $seeds/; s/^persistent_peers *=.*/persistent_peers = $peers/" $HOME/.ag-chain-cosmos/config/config.toml

# create unit file
if [ $SUDO_USER ]; then USER=$SUDO_USER; else USER=`whoami`; fi

tee <<EOF >/dev/null /etc/systemd/system/ag-chain-cosmos.service
[Unit]
Description=Agoric Cosmos daemon
After=network-online.target

[Service]
User=$USER
ExecStart=$HOME/go/bin/ag-chain-cosmos start --log_level=warn
Restart=on-failure
RestartSec=3
LimitNOFILE=4096

[Install]
WantedBy=multi-user.target
EOF

# Check the contents of the file, especially User, Environment and ExecStart lines
# cat /etc/systemd/system/ag-chain-cosmos.service

# start node and sync
systemctl enable ag-chain-cosmos
systemctl daemon-reload
systemctl start ag-chain-cosmos

# confirm that the node is fully synced
for (( ; ; )); do
  sync_info=`sudo -u $USER "$HOME/go/bin/ag-cosmos-helper" status 2>&1 | jq .SyncInfo`
  echo "$sync_info"
  if test `echo "$sync_info" | jq -r .catching_up` == false; then
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