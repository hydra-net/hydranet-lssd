#!/bin/bash

docker-compose exec -ti bot-0-lnd-btc lncli -rpcserver=localhost:10000  --lnddir=/data --network=mainnet create