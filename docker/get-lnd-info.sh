#!/bin/bash

docker-compose exec -ti bot-0-lnd-btc lncli -rpcserver=localhost:10000 --macaroonpath=/data/chain/bitcoin/mainnet/admin.macaroon  --lnddir=/data --network=mainnet getinfo

docker-compose exec -ti bot-0-lnd-btc lncli -rpcserver=localhost:10000 --macaroonpath=/data/chain/bitcoin/mainnet/admin.macaroon  --lnddir=/data --network=mainnet listchannels

