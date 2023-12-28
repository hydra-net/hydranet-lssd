#!/bin/bash

/bin/lnd_btc --tlscertpath=/data/tls.cert --tlskeypath=/data/tls.key  --tlsextradomain=bot-0-lnd-btc  --rpclisten=0.0.0.0:10000 --listen=0.0.0.0:11000 --restlisten=0.0.0.0:12000 --datadir=/data --logdir=/data --nobootstrap --bitcoin.active --bitcoin.mainnet \
--bitcoin.defaultchanconfs=6 --bitcoin.node=neutrino --debuglevel=debug --autopilot.conftarget=1  --maxpendingchannels=50 --chan-enable-timeout=1m \
--maxlogfiles=100 --backupfilepath=/data/channel.backup --bitcoin.timelockdelta=18 --bitcoin.defaultremotedelay=3 --historicalsyncinterval=5m --gossip.channel-update-interval=1m --gossip.max-channel-update-burst=100 --feeurl=https://nodes.lightning.computer/fees/v1/btc-fee-estimates.json  \
--alias=bot-0 --numgraphsyncpeers=0  --gossip.pinned-syncers=03c23b7f5b9fa984705678b96821f4d15133ced6ef58c0521e4dcca434e0d5a50a
