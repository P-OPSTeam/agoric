#!/bin/bash

# confirm that the node is fully synced
for (( ; ; )); do
  sync_info=`"ag-cosmos-helper" status 2>&1 | jq .SyncInfo`
  echo "$sync_info"
  if test `echo "$sync_info" | jq -r .catching_up` == false; then
    echo "Caught up"
    break
  fi
  sleep 5
done