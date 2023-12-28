#/bin/bash

HUB_PUB_ID=vector6VA65fXnGMeHyE9CMe3BUpCiAyMg9BS9HV9mxzVHYQkWvWZPES
HDN_TOKEN_ADDRESS="0x3404149e9EE6f17Fb41DB1Ce593ee48FBDcD9506"
USDC_TOKEN_ADDRESS="0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48"
USDT_TOKEN_ADDRESS="0xdAC17F958D2ee523a2206206994597C13D831ec7"
AUSDC_TOKEN_ADDRESS="0xaf88d065e77c8cC2239327C5EDb3A432268e5831"
AUSDT_TOKEN_ADDRESS="0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9"
ETH_TOKEN_ADDRESS="0x0000000000000000000000000000000000000000"
AETH_TOKEN_ADDRESS="0x0000000000000000000000000000000000000000"

HDN_DECIMALS=18
USDC_DECIMALS=6
USDT_DECIMALS=6
AUSDC_DECIMALS=6
AUSDT_DECIMALS=6
ETH_DECIMALS=18
AETH_DECIMALS=18

convert_to_wei() {
    local tokenAddress=$1
    local amount=$2
    
    case $tokenAddress in
        $HDN_TOKEN_ADDRESS)
            echo $(bc <<< "scale=0; $amount * 10^$HDN_DECIMALS")  |cut -d'.' -f1
            ;;
        $USDC_TOKEN_ADDRESS)
            echo $(bc <<< "scale=0; $amount * 10^$USDC_DECIMALS")  |cut -d'.' -f1
            ;;
        $USDT_TOKEN_ADDRESS)
            echo $(bc <<< "scale=0; $amount * 10^$USDT_DECIMALS")  |cut -d'.' -f1
            ;;
        $AUSDC_TOKEN_ADDRESS)
            echo $(bc <<< "scale=0; $amount * 10^$AUSDC_DECIMALS")  |cut -d'.' -f1
            ;;
        $AUSDT_TOKEN_ADDRESS)
            echo $(bc <<< "scale=0; $amount * 10^$AUSDT_DECIMALS")  |cut -d'.' -f1
            ;;
        $ETH_TOKEN_ADDRESS)
            echo $(bc <<< "scale=0; $amount * 10^$ETH_DECIMALS")  |cut -d'.' -f1
            ;;
        $AETH_TOKEN_ADDRESS)
            echo $(bc <<< "scale=0; $amount * 10^$AETH_DECIMALS") |cut -d'.' -f1
            ;;
        *)
            echo "Invalid token address"
            ;;
    esac

    
}

deposit_token() {
    local token_name=$1
    local token_address=$2
    local OWN_PUB_ID=$3
    local channel=$4
    local chain_id=$5

    echo "Depositing $token_name..."
    echo "How much $token_name do you want to deposit? If you have already deposited and want to refresh, enter 0"
    read amount
    AMOUNT_IN_WEI=$(convert_to_wei $token_address $amount)
    echo "Amount in wei: $AMOUNT_IN_WEI"
    echo "type confirm"
    read confirm
    if [ "$confirm" != "confirm" ]; then
        echo "Aborting..."
        exit 1
    fi
    

    if [ "$AMOUNT_IN_WEI" -gt 0 ]; then
        send_deposit_tx "http://localhost:8000" $OWN_PUB_ID $channel $token_address $AMOUNT_IN_WEI $chain_id
        echo "waiting for confirmation"
        sleep 30
    fi

    reconcile "http://localhost:8000" $OWN_PUB_ID $channel $token_address $AMOUNT_IN_WEI $chain_id
}


withdraw_token() {
    local token_name=$1
    local token_address=$2
    local OWN_PUB_ID=$3
    local channel=$4
    local chain_id=$5

    echo "Withdrawing $token_name..."
    echo "How much $token_name do you want to withdraw?"
    read amount
    AMOUNT_IN_WEI=$(convert_to_wei $token_address $amount)
    echo "Amount in wei: $AMOUNT_IN_WEI"
    echo "Enter the address you want to withdraw to:"
    read recipient

    echo "type confirm"
    read confirm
    if [ "$confirm" != "confirm" ]; then
        echo "Aborting..."
        exit 1
    fi
    withdraw "http://localhost:8000" $OWN_PUB_ID $channel $token_address $AMOUNT_IN_WEI $chain_id $recipient

}
ETHEREUM_MAINNET_CHAIN_ID=1
ARBITRUM_MAINNET_CHAIN_ID=42161
SELECTED_CHAIN_ID=0


setup_node() {
    local nodeUrl="$1"
    local counterpartyPublicIdentifier=$2
    local nodePublicIdentifier=$3
    local chainId=$4

    curl -s -X POST "${nodeUrl}/setup" \
         -H "Content-Type: application/json" \
         -d '{
               "counterpartyIdentifier": "'"${counterpartyPublicIdentifier}"'",
               "publicIdentifier": "'"${nodePublicIdentifier}"'",
               "chainId": '"${chainId}"',
               "timeout": "172800"
             }' 
             
}

get_channels() {
    local nodeUrl="$1"
    local nodePublicIdentifier=$2


    echo $(curl  -s -X GET "${nodeUrl}/${nodePublicIdentifier}/channels" \
         -H "Content-Type: application/json" | jq -c '.[]' |tr -d '"')
}

get_channel_details() {
    local nodeUrl="$1"
    local nodePublicIdentifier=$2
    local channelAddress=$3

    echo $(curl  -s -X GET "${nodeUrl}/${nodePublicIdentifier}/channels/${channelAddress}" \
         -H "Content-Type: application/json" | jq -c '.')
}

get_chain_id_for_channel() {
    local nodeUrl="$1"
    local nodePublicIdentifier=$2
    local channelAddress=$3

    CHAN_DETAILS=$(get_channel_details $nodeUrl $nodePublicIdentifier $channelAddress)
    #echo "Channel details: $CHAN_DETAILS"
    echo $(echo $CHAN_DETAILS | jq -r '.networkContext.chainId' |tr -d '"')
}

send_deposit_tx() {
    local nodeUrl="$1"
    local nodePublicIdentifier=$2
    local channelAddress=$3
    local tokenAddress=$4
    local amount=$5
    local chainId=$6


    curl -s  -X POST "${nodeUrl}/send-deposit-tx" \
         -H "Content-Type: application/json" \
         -d '{
               "publicIdentifier": "'"${nodePublicIdentifier}"'",
               "channelAddress": "'"${channelAddress}"'",
               "assetId": "'"${tokenAddress}"'",
               "amount": '"${amount}"',
                "chainId": '"${chainId}"'
             }'  | jq .
}

reconcile() {
    local nodeUrl="$1"
    local nodePublicIdentifier=$2
    local channelAddress=$3
    local tokenAddress=$4
    local amount=$5
    local chainId=$6


    curl -s -X POST "${nodeUrl}/deposit" \
         -H "Content-Type: application/json" \
         -d '{
               "publicIdentifier": "'"${nodePublicIdentifier}"'",
               "channelAddress": "'"${channelAddress}"'",
               "assetId": "'"${tokenAddress}"'",
               "amount": "'"${amount}"'",
               "chainId": '"${chainId}"'
             }' | jq .
}

###############
### Create Event Subscription
# POST {{nodeUrl}}/event/subscribe
# Content-Type: application/json

# {
#   "publicIdentifier": "{{nodePublicIdentifier}}",
#   "events": {
#     "{{eventName}}": "http://localhost:1234"
#   }
# }

create_event_subscription() {
    local nodeUrl="$1"
    local nodePublicIdentifier=$2
    local botName=$3
    local createdCallback="http://$botName:9012/created"
    local resolvedCallback="http://$botName:9012/resolved"

    curl -s  -X POST "${nodeUrl}/event/subscribe" \
         -H "Content-Type: application/json" \
         -d '{
               "publicIdentifier": "'"${nodePublicIdentifier}"'",
               "events": {
                 "CONDITIONAL_TRANSFER_CREATED": "'"${createdCallback}"'",
                  "CONDITIONAL_TRANSFER_RESOLVED": "'"${resolvedCallback}"'"
               }
             }' | jq .


}

### Get Event Subscriptions
#GET {{nodeUrl}}/{{nodePublicIdentifier}}/event

get_events() {
    local nodeUrl="$1"
    local nodePublicIdentifier=$2

    curl -s  -X GET "${nodeUrl}/${nodePublicIdentifier}/event" \
         -H "Content-Type: application/json" | jq .
}


##############
### Create Transfer ETH
# POST {{nodeUrl}}/transfers/create
# Content-Type: application/json

# {
#   "type": "HashlockTransfer",
#   "publicIdentifier": "{{nodePublicIdentifier}}",
#   "channelAddress": "{{channel}}",
#   "amount": "{{ethAmount}}",
#   "assetId": "0x0000000000000000000000000000000000000000",
#   "details": {
#     "lockHash": "{{lockHash}}",
#     "expiry": "0"
#   },
#   "recipient": "{{recipientPublicIdentifier}}",
#   "meta": {
#     "hello": "world",
#     "requireOnline": false
#   },
#   "timeout": "48000"
# }

transfer() {
    local nodeUrl="$1"
    local nodePublicIdentifier=$2
    local channelAddress=$3
    local tokenAddress=$4
    local amount=$5
    local chainId=$6
    local recipient=$7
    local lockHash=$8

    curl -s -X POST "${nodeUrl}/transfers/create" \
         -H "Content-Type: application/json" \
         -d '{
               "type": "HashlockTransfer",
               "publicIdentifier": "'"${nodePublicIdentifier}"'",
               "channelAddress": "'"${channelAddress}"'",
               "amount": '"${amount}"',
               "assetId": "'"${tokenAddress}"'",
               "details": {
                 "lockHash": "'"${lockHash}"'",
                 "expiry": "0"
               },
               "recipient": "'"${recipient}"'",
               "meta": {
                 "requireOnline": false
               },
               "timeout": "48000"
             }' | jq .
 
}


#withdraw payload
# {
#   "publicIdentifier": "{{nodePublicIdentifier}}",
#   "channelAddress": "{{channel}}",
#   "amount": "{{ethAmount}}",
#   "assetId": "0x0000000000000000000000000000000000000000",
#   "recipient": "{{aliceAddress}}",
#   "fee": "0",
#   "meta": {
#     "hello": "world"
#   }
# }
withdraw() {
    local nodeUrl="$1"
    local nodePublicIdentifier=$2
    local channelAddress=$3
    local tokenAddress=$4
    local amount=$5
    local chainId=$6
    local recipient=$7

    curl  -X POST "${nodeUrl}/withdraw" \
         -H "Content-Type: application/json" \
         -d '{
               "publicIdentifier": "'"${nodePublicIdentifier}"'",
               "channelAddress": "'"${channelAddress}"'",
               "assetId": "'"${tokenAddress}"'",
               "amount": '"${amount}"',
                "chainId": '"${chainId}"',
                "recipient": "'"${recipient}"'"
             }' | jq .
}

echo "Welcome to the Vector CLI!"

echo "What do you want to do?"
echo "1: Initialize the vector-node"
echo "2: Setup a new channel"
echo "3: Deposit funds in a channel"
echo "4: Withdraw funds from a channel"
echo "5: Refresh and check the balance of a channel"
echo "6: Setup callback for lssd"
echo "7: Pay for a channel rental"
echo "8: Get callback events"




read choice

case $choice in
    1)
        echo "Initializing the vector-node..."
        curl -X POST http://localhost:8000/node \
            -H "Content-Type: application/json" \
            -d '{"index": 0}' | jq .

        ;;
    2)
        

        echo "Which chain do you want to setup a channel on?"
        echo "1: Ethereum mainnet"
        echo "2: Arbitrum mainnet"
        read chain
        case $chain in
            1)
                echo "Setting up a channel on Ethereum mainnet..."
                SELECTED_CHAIN_ID=$ETHEREUM_MAINNET_CHAIN_ID
                ;;
            2)
                echo "Setting up a channel on Arbitrum mainnet..."
                SELECTED_CHAIN_ID=$ARBITRUM_MAINNET_CHAIN_ID
                ;;

            *)
                echo "Invalid choice. Please enter 1 or 2."
                ;;
        esac
        echo "Enter the hub you want to connect to:"
        echo "1: hydranet mainnet hub"
        read hub
        
        case $hub in
            1)
                echo "Setting up a channel to hydranet mainnet hub $HUB_PUB_ID..."
                OWN_PUB_ID=$(curl -s -X POST http://localhost:8000/node \
                            -H "Content-Type: application/json" \
                            -d '{"index": 0}' | jq .publicIdentifier |tr -d '"')

                echo "Your public identifier is $OWN_PUB_ID"

                setup_node "http://localhost:8000" $HUB_PUB_ID $OWN_PUB_ID $SELECTED_CHAIN_ID
                ;;
            *)
                echo "Invalid choice. Please enter 1."
                ;;
        esac



    
        
        ;;
    3)
        echo "In which channel do you want to deposit?"
        OWN_PUB_ID=$(curl -s -X POST http://localhost:8000/node \
                            -H "Content-Type: application/json" \
                            -d '{"index": 0}' | jq .publicIdentifier |tr -d '"')
        INDEX=1
        CHANNELS=$(get_channels "http://localhost:8000" $OWN_PUB_ID)
        CHANNELS_ARRAY=($CHANNELS) # Convert to an array

        for CHAN in "${CHANNELS_ARRAY[@]}"; do
            CHAIN_ID=$(get_chain_id_for_channel "http://localhost:8000" $OWN_PUB_ID $CHAN)
            echo "$INDEX: Channel $CHAN on chain $CHAIN_ID"
            INDEX=$((INDEX+1))
        done
        read selected_index
        channel=${CHANNELS_ARRAY[$selected_index-1]}
        CHAIN_ID=$(get_chain_id_for_channel "http://localhost:8000" $OWN_PUB_ID $channel)
        echo "Selected channel : $channel"

        echo "Which token do you want to deposit?"
        echo "1: HDN"
        echo "2: USDC"
        echo "3: USDT"
        echo "4: AUSDC"
        echo "5: AUSDT"
        echo "6: ETH"
        echo "7: AETH"
        read token

        case $token 
        in
            1)
                deposit_token "HDN" $HDN_TOKEN_ADDRESS $OWN_PUB_ID $channel $CHAIN_ID
                ;;
            2)
                deposit_token "USDC" $USDC_TOKEN_ADDRESS $OWN_PUB_ID $channel $CHAIN_ID               
                ;;
            3)
                deposit_token "USDT" $USDT_TOKEN_ADDRESS $OWN_PUB_ID $channel $CHAIN_ID
                ;;
            4)
                deposit_token "AUSDC" $AUSDC_TOKEN_ADDRESS $OWN_PUB_ID $channel $CHAIN_ID

                ;;
            5)
                deposit_token "AUSDT" $AUSDT_TOKEN_ADDRESS $OWN_PUB_ID $channel $CHAIN_ID
                ;;
            6)
                deposit_token "ETH" $ETH_TOKEN_ADDRESS $OWN_PUB_ID $channel $CHAIN_ID
                ;;
            7)
                deposit_token "AETH" $AETH_TOKEN_ADDRESS $OWN_PUB_ID $channel $CHAIN_ID
                ;;
            *)
                echo "Invalid choice. Please enter 1, 2, 3, 4, 5, 6 or 7."
                ;;
        esac


        ;;
    4)  
        echo "From which channel do you want to withdraw?"
        OWN_PUB_ID=$(curl -s -X POST http://localhost:8000/node \
                            -H "Content-Type: application/json" \
                            -d '{"index": 0}' | jq .publicIdentifier |tr -d '"')
        INDEX=1
        CHANNELS=$(get_channels "http://localhost:8000" $OWN_PUB_ID)
        CHANNELS_ARRAY=($CHANNELS) # Convert to an array

        for CHAN in "${CHANNELS_ARRAY[@]}"; do
            CHAIN_ID=$(get_chain_id_for_channel "http://localhost:8000" $OWN_PUB_ID $CHAN)
            echo "$INDEX: Channel $CHAN on chain $CHAIN_ID"
            INDEX=$((INDEX+1))
        done
        read selected_index
        channel=${CHANNELS_ARRAY[$selected_index-1]}
        CHAIN_ID=$(get_chain_id_for_channel "http://localhost:8000" $OWN_PUB_ID $channel)
        echo "Selected channel : $channel"
        echo "Which token do you want to withdraw?"
        echo "1: HDN"
        echo "2: USDC"
        echo "3: USDT"
        echo "4: AUSDC"
        echo "5: AUSDT"
        echo "6: ETH"
        echo "7: AETH"
        read token

        case $token
        in
            1)
                withdraw_token "HDN" $HDN_TOKEN_ADDRESS $OWN_PUB_ID $channel $CHAIN_ID
                ;;
            2)
                withdraw_token "USDC" $USDC_TOKEN_ADDRESS $OWN_PUB_ID $channel $CHAIN_ID
                ;;
            3)
                withdraw_token "USDT" $USDT_TOKEN_ADDRESS $OWN_PUB_ID $channel $CHAIN_ID
                ;;
            4)
                withdraw_token "AUSDC" $AUSDC_TOKEN_ADDRESS $OWN_PUB_ID $channel $CHAIN_ID
                ;;
            5)
                withdraw_token "AUSDT" $AUSDT_TOKEN_ADDRESS $OWN_PUB_ID $channel $CHAIN_ID
                ;;
            6)
                withdraw_token "ETH" $ETH_TOKEN_ADDRESS $OWN_PUB_ID $channel $CHAIN_ID
                ;;
            7)
                withdraw_token "AETH" $AETH_TOKEN_ADDRESS $OWN_PUB_ID $channel $CHAIN_ID
                ;;
            *)
                echo "Invalid choice. Please enter 1, 2, 3, 4, 5, 6 or 7."
                ;;
        esac    
        
        ;;
    5)  
        echo "Checking the balance of a channel..."
        OWN_PUB_ID=$(curl -s -X POST http://localhost:8000/node \
                            -H "Content-Type: application/json" \
                            -d '{"index": 0}' | jq .publicIdentifier |tr -d '"')
        CHANNELS=$(get_channels "http://localhost:8000" $OWN_PUB_ID)
        for CHAN in $CHANNELS; do
            echo "Channel $CHAN"
            get_channel_details "http://localhost:8000" $OWN_PUB_ID $CHAN | jq .
        done
        
        ;;
    6)  
        echo "Setup callback for lssd"
        echo "Enter your lssds name as defined in docker-compose.yaml e.g. bot-0-lssd"
        read lssd_name
        OWN_PUB_ID=$(curl -s -X POST http://localhost:8000/node \
                            -H "Content-Type: application/json" \
                            -d '{"index": 0}' | jq .publicIdentifier |tr -d '"')
        create_event_subscription "http://localhost:8000" $OWN_PUB_ID $lssd_name
        ;;
    

    7)
         echo "To pay for a channel rental, you need to obtain the paymenthash using the lsds grpc api."
         echo "Do you have the payment hash? (y/n)"
            read has_payment_hash
            if [ "$has_payment_hash" != "y" ]; then
                echo "Aborting..."
                exit 1
            fi
            echo "Enter the payment hash:"
            read payment_hash
            echo "In which currency do you want to pay?"
            echo "1: HDN"
            echo "2: USDC"
            echo "3: USDT"
            echo "4: AUSDC"
            echo "5: AUSDT"
            echo "6: ETH"
            echo "7: AETH"
            read token



            case $token in
                "1")
                    token_address=$HDN_TOKEN_ADDRESS
                    ;;
                "2")
                    token_address=$USDC_TOKEN_ADDRESS
                    ;;
                "3") 
                    token_address=$USDT_TOKEN_ADDRESS
                    ;;
                "4") 
                    token_address=$AUSDC_TOKEN_ADDRESS
                    ;;
                "5") 
                    token_address=$AUSDT_TOKEN_ADDRESS
                    ;;
                "6") 
                    token_address=$ETH_TOKEN_ADDRESS
                    ;;
                "7") 
                    token_address=$AETH_TOKEN_ADDRESS
                    ;;
                *)
                    echo "Invalid choice. Please enter 1, 2, 3, 4, 5, 6 or 7."
                    ;;
            esac
            
            echo "Enter the amount you want to pay e.g. 0.004:"
            read amount
            
            AMOUNT_IN_WEI=$(convert_to_wei $token_address $amount)
            echo "amount in wei: " $AMOUNT_IN_WEI
            echo "From which channel do you want to send the transfer?"
            OWN_PUB_ID=$(curl -s -X POST http://localhost:8000/node \
                                -H "Content-Type: application/json" \
                                -d '{"index": 0}' | jq .publicIdentifier |tr -d '"')
            INDEX=1
            CHANNELS=$(get_channels "http://localhost:8000" $OWN_PUB_ID)
            CHANNELS_ARRAY=($CHANNELS) # Convert to an array

            for CHAN in "${CHANNELS_ARRAY[@]}"; do
                CHAIN_ID=$(get_chain_id_for_channel "http://localhost:8000" $OWN_PUB_ID $CHAN)
                echo "$INDEX: Channel $CHAN on chain $CHAIN_ID"
                INDEX=$((INDEX+1))
            done
            read selected_index
            channel=${CHANNELS_ARRAY[$selected_index-1]}
            CHAIN_ID=$(get_chain_id_for_channel "http://localhost:8000" $OWN_PUB_ID $channel)
            echo "Selected channel : $channel"

            echo "type confirm"
            read confirm
            if [ "$confirm" != "confirm" ]; then
                echo "Aborting..."
                exit 1
            fi
            transfer "http://localhost:8000" $OWN_PUB_ID $channel $token_address $AMOUNT_IN_WEI $CHAIN_ID $HUB_PUB_ID $payment_hash
            echo "Your nodePublicKey: $OWN_PUB_ID"
            


        ;;
    8)
        echo "Getting callback events"
        OWN_PUB_ID=$(curl -s -X POST http://localhost:8000/node \
                                -H "Content-Type: application/json" \
                                -d '{"index": 0}' | jq .publicIdentifier |tr -d '"')
        echo "Your nodePublicKey: $OWN_PUB_ID"                   
        get_events "http://localhost:8000" $OWN_PUB_ID
        ;;
    *)
        echo "Invalid choice."
        ;;
esac

