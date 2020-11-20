#!/bin/bash

echo "-------------"
echo "Stopping Bitcoind if it is already running"
echo "-------------"

#stop bitcoind if it running
bitcoin-cli stop >/dev/null 2>&1

echo "-------------"
echo "Updating Bitcoind configuration"
echo "-------------"

cat <<- EOM > ~/.bitcoin/bitcoin.conf
## Generated - `date`
## bitcoin.conf configuration file. Lines beginning with # are comments.
##
daemon=1
regtest=1

listen=0

addresstype=legacy
changetype=legacy

# JSON-RPC options (for controlling a running Bitcoin/bitcoind process)
rpcuser=coinvault
rpcpassword=my_hen_lays_two_eggs_a_day
rpcport=8332

# server=1 tells Bitcoin-Qt and bitcoind to accept JSON-RPC commands
server=1
#prune=5500
txindex=1
EOM

# set -x #echo on

echo "-------------"
echo "Refreshing & Restarting Bitcoind"
echo "-------------"

#start afresh
rm -R ~/.bitcoin/regtest
bitcoind
echo "Waiting for 5 secs for Bitcoin Demon to Initialize..."
sleep 5

#####################################

#source Keys.sh

#Depositor - Keys
DepositorPriv="cUrRAGYGV9Lj7yk7qFMZxxVeFTFqgt6BuJheb4EgVMafHef8f9p9"
DepositorPub="023320c921fb86d276cf996c97a3f3893e5da2c03926acd1d5160d0ccdb582f416"

DepositorAdrs=$(./bx ec-to-address -v 111 $DepositorPub)

#DepositorToken - Keys
DepositorTokenPriv="cTXijGDBz6jDD2tKarpt982e4VnF7Jm1uJg5oKsVSpzcL8y3ut63"
DepositorTokenPub="032aa651b6e0064cf4ddc0230e5cf37496d32e7970e9221f0d16d7afefd2be2451"

DepositorTokenAdrs=$(./bx ec-to-address -v 111 $DepositorTokenPub)

#Vault - Keys
VaultPriv="cS71P5KPZbgGYhkXfTomFNYxq2NRccQb8Zkw3XEQkMVnQdSvAYQn"
VaultPub="03cb7ef39e4bf4e487f73dd8c0ac6f0ef112a6ac7b3fa09546007121605bfa7c7b"

VaultAdrs=$(./bx ec-to-address -v 111 $VaultPub)

#VaultToken - Keys
VaultTokenPriv="cSU3xYnsJuojZiuaoJs6tBP8dA5MUL67kwwPvh2hwgQVuByGUJ7u"
VaultTokenPub="0380f1bd8cfc7560dc0a0da73d121d7ff7e9c63464321d3fb6758c400dcbc021a2"

VaultTokenAdrs=$(./bx ec-to-address -v 111 $VaultTokenPub)

######################################################

echo "-------------"
echo "Generating blocks to bootstrap Bitcoin RegTest Blockchain"
echo "-------------"

bitcoin-cli generatetoaddress 101 "$DepositorAdrs" >/dev/null 2>&1
bitcoin-cli importaddress "$DepositorAdrs"

utxo_txid_1=$(bitcoin-cli listunspent | jq -r '.[0] | .txid')
utxo_vout_1=$(bitcoin-cli listunspent | jq -r '.[0] | .vout')

# Create Deposit Transaction

DepositTxRedeemScript="0072537a532103cb7ef39e4bf4e487f73dd8c0ac6f0ef112a6ac7b3fa09546007121605bfa7c7b21032aa651b6e0064cf4ddc0230e5cf37496d32e7970e9221f0d16d7afefd2be245121023320c921fb86d276cf996c97a3f3893e5da2c03926acd1d5160d0ccdb582f41653ae"

DepositTxOutputAddress=$(./bx script-decode $DepositTxRedeemScript | ./bx script-to-address -v 196)


# bitcoin-cli decodescript $DepositTxRedeemScript
# {
#   "asm": "0 OP_2SWAP 3 OP_ROLL 3 03cb7ef39e4bf4e487f73dd8c0ac6f0ef112a6ac7b3fa09546007121605bfa7c7b 032aa651b6e0064cf4ddc0230e5cf37496d32e7970e9221f0d16d7afefd2be2451 023320c921fb86d276cf996c97a3f3893e5da2c03926acd1d5160d0ccdb582f416 3 OP_CHECKMULTISIG",
#   "type": "nonstandard",
#   "p2sh": "2MzCj5bQ67x3vsy5GZnHeE5oezZnzvK62GT", (P2SH Address)
#   "segwit": {
#     "asm": "0 77ed8a9258123317cfe7c30a8990b4c7ef4fe011e26c1dbe5838466dd4633c08",
#     "hex": "002077ed8a9258123317cfe7c30a8990b4c7ef4fe011e26c1dbe5838466dd4633c08",
#     "reqSigs": 1,
#     "type": "witness_v0_scripthash",
#     "addresses": [
#       "bcrt1qwlkc4yjczge30nl8cv9gny95clh5lcq3ufkpm0jc8prxm4rr8syqw6ctdw"
#     ],
#     "p2sh-segwit": "2N5WCSHb1jzz1DWY7bSc6oW4Q918R6teLvc"
#   }
# }


read -r -d '' DepositTxInputs <<-EOM
    [
        {
            "txid": "$utxo_txid_1",
            "vout": $utxo_vout_1
        }
    ]
EOM

read -r -d '' DepositTxOutputs <<-EOM
    [
        {
            "$DepositTxOutputAddress": 49.999
        }
    ]
EOM

echo "-------------"
echo "Creating Unsigned Deposit Tx"
echo "-------------"

DepositTx=$(bitcoin-cli createrawtransaction "$DepositTxInputs" "$DepositTxOutputs")

bitcoin-cli decoderawtransaction "$DepositTx"

echo "-------------"
echo "Signing the Deposit Tx"
echo "-------------"

DepositTxSigned=$(bitcoin-cli signrawtransactionwithkey "$DepositTx"  "[\"$DepositorPriv\"]" | jq -r '.hex')

bitcoin-cli decoderawtransaction "$DepositTxSigned"

DepositTxID=$(bitcoin-cli decoderawtransaction "$DepositTxSigned" | jq -r '.txid')
DepositTxScriptPubKey=$(bitcoin-cli decoderawtransaction "$DepositTxSigned" | jq '.vout[0] | .scriptPubKey.hex')

###################################

# Create Provisional Tx

ProvTxRedeemScript="210380f1bd8cfc7560dc0a0da73d121d7ff7e9c63464321d3fb6758c400dcbc021a22103cb7ef39e4bf4e487f73dd8c0ac6f0ef112a6ac7b3fa09546007121605bfa7c7b21032aa651b6e0064cf4ddc0230e5cf37496d32e7970e9221f0d16d7afefd2be245121023320c921fb86d276cf996c97a3f3893e5da2c03926acd1d5160d0ccdb582f416547958876377537a7500567a567a567a53577a577a577a53ae675479578763537a75537a7500567a567a567a53567a577a577a53ae67547956876377777777ad028813b275516754795587636d7777ad02b80bb27551675479548763777b757b7500547a547a527152af02c409b275516754795387636d7b7500547a547a527152af02d007b27551675479528763757b757b7500547a547a52547a557a52af02dc05b2755167547a637b757b7500547a547a527152af02e803b2755167777700547a547a527152af02f401b275516868686868686868"

ProvTxOutputAddress=$(./bx script-decode $ProvTxRedeemScript | ./bx script-to-address -v 196)

# bitcoin-cli decodescript $ProvTxRedeemScript
# {
#   "asm": "0380f1bd8cfc7560dc0a0da73d121d7ff7e9c63464321d3fb6758c400dcbc021a2 03cb7ef39e4bf4e487f73dd8c0ac6f0ef112a6ac7b3fa09546007121605bfa7c7b 032aa651b6e0064cf4ddc0230e5cf37496d32e7970e9221f0d16d7afefd2be2451 023320c921fb86d276cf996c97a3f3893e5da2c03926acd1d5160d0ccdb582f416 4 OP_PICK 8 OP_EQUAL OP_IF OP_NIP 3 OP_ROLL OP_DROP 0 6 OP_ROLL 6 OP_ROLL 6 OP_ROLL 3 7 OP_ROLL 7 OP_ROLL 7 OP_ROLL 3 OP_CHECKMULTISIG OP_ELSE 4 OP_PICK 7 OP_EQUAL OP_IF 3 OP_ROLL OP_DROP 3 OP_ROLL OP_DROP 0 6 OP_ROLL 6 OP_ROLL 6 OP_ROLL 3 6 OP_ROLL 7 OP_ROLL 7 OP_ROLL 3 OP_CHECKMULTISIG OP_ELSE 4 OP_PICK 6 OP_EQUAL OP_IF OP_NIP OP_NIP OP_NIP OP_NIP OP_CHECKSIGVERIFY 5000 OP_CHECKSEQUENCEVERIFY OP_DROP 1 OP_ELSE 4 OP_PICK 5 OP_EQUAL OP_IF OP_2DROP OP_NIP OP_NIP OP_CHECKSIGVERIFY 3000 OP_CHECKSEQUENCEVERIFY OP_DROP 1 OP_ELSE 4 OP_PICK 4 OP_EQUAL OP_IF OP_NIP OP_ROT OP_DROP OP_ROT OP_DROP 0 4 OP_ROLL 4 OP_ROLL 2 OP_2ROT 2 OP_CHECKMULTISIGVERIFY 2500 OP_CHECKSEQUENCEVERIFY OP_DROP 1 OP_ELSE 4 OP_PICK 3 OP_EQUAL OP_IF OP_2DROP OP_ROT OP_DROP 0 4 OP_ROLL 4 OP_ROLL 2 OP_2ROT 2 OP_CHECKMULTISIGVERIFY 2000 OP_CHECKSEQUENCEVERIFY OP_DROP 1 OP_ELSE 4 OP_PICK 2 OP_EQUAL OP_IF OP_DROP OP_ROT OP_DROP OP_ROT OP_DROP 0 4 OP_ROLL 4 OP_ROLL 2 4 OP_ROLL 5 OP_ROLL 2 OP_CHECKMULTISIGVERIFY 1500 OP_CHECKSEQUENCEVERIFY OP_DROP 1 OP_ELSE 4 OP_ROLL OP_IF OP_ROT OP_DROP OP_ROT OP_DROP 0 4 OP_ROLL 4 OP_ROLL 2 OP_2ROT 2 OP_CHECKMULTISIGVERIFY 1000 OP_CHECKSEQUENCEVERIFY OP_DROP 1 OP_ELSE OP_NIP OP_NIP 0 4 OP_ROLL 4 OP_ROLL 2 OP_2ROT 2 OP_CHECKMULTISIGVERIFY 500 OP_CHECKSEQUENCEVERIFY OP_DROP 1 OP_ENDIF OP_ENDIF OP_ENDIF OP_ENDIF OP_ENDIF OP_ENDIF OP_ENDIF OP_ENDIF",
#   "type": "nonstandard",
#   "p2sh": "2NAWyps8eLcXxz5kdJVD6vrbbWxsDnyRurz",
#   "segwit": {
#     "asm": "0 338e8649a4908dc7ef883216d5fd7d963bab00dc988947e7ea13aff895989828",
#     "hex": "0020338e8649a4908dc7ef883216d5fd7d963bab00dc988947e7ea13aff895989828",
#     "reqSigs": 1,
#     "type": "witness_v0_scripthash",
#     "addresses": [
#       "bcrt1qxw8gvjdyjzxu0mugxgtdtltajca6kqxunzy50el2zwhl39vcnq5qdazzch"
#     ],
#     "p2sh-segwit": "2MtBFk78tB3awCMREc2KBy93WAUT9ZxGc2Y"
#   }
# }

read -r -d '' ProvTxInputs <<-EOM
    [
        {
            "txid": "$DepositTxID",
            "vout": 0
        }
    ]
EOM

read -r -d '' ProvTxOutputs <<-EOM
    [
        {
            "$ProvTxOutputAddress": 49.998
        }
    ]
EOM

echo "-------------"
echo "Creating Unsigned Provisional Tx"
echo "-------------"

ProvTx=$(bitcoin-cli createrawtransaction "$ProvTxInputs" "$ProvTxOutputs")

bitcoin-cli decoderawtransaction "$ProvTx"

echo "-------------"
echo "Simulating the transfer of Unsigned Provisional Tx copy"
echo "to Vault!"
echo "-------------"

echo "[D] --> Unsigned Provisional Tx --> [V]"

echo "-------------"
echo "Simulating the Signing of Provisional Tx copy by Vault"
echo "and transferring the Partially Signed Prov Tx to Depository"
echo "-------------"

echo "[V] --> Partially Signed Provisional Tx --> [D]"


DepositTxRedeemScriptAsm=$(./bx script-decode $DepositTxRedeemScript)

VaultSignatureProv=$(./bx input-sign -c bx.cfg $(./bx wif-to-ec $VaultPriv) "$DepositTxRedeemScriptAsm" $ProvTx)

echo "-------------"
echo "Vault Signature for Provisional Tx:"
echo $VaultSignatureProv
echo "-------------"

echo "-------------"
echo "Simulating the Signing of Prov Tx by Depositor"
echo "and transferring the Partially Signed Prov Tx to Vault"
echo "-------------"

echo "[D] --> Partially Signed Provisional Tx --> [V]"

echo "-------------"
echo "Depositor signs the Provisional Tx"
echo "with his Private Key and Hardware Token"
echo "-------------"

DepositorTokenSignatureProv=$(./bx input-sign -c bx.cfg $(./bx wif-to-ec $DepositorTokenPriv) "$DepositTxRedeemScriptAsm" $ProvTx)

echo "-------------"
echo "DepositorToken generated Signature for Provisional Tx:"
echo $DepositorTokenSignatureProv
echo "-------------"

DepositorSignatureProv=$(./bx input-sign -c bx.cfg $(./bx wif-to-ec $DepositorPriv) "$DepositTxRedeemScriptAsm" $ProvTx)

echo "-------------"
echo "Depositor Private Key generated Signature for Provisional Tx:"
echo $DepositorSignatureProv
echo "-------------"

#######################################
#
# Deositor will broadcast DepositTx
# after receiving the
# Partially Signed Prov. Tx with
# Vault's signature already added to it
#
#######################################

echo "-------------"
echo "Depositor signs & broadcasts the Deposit Tx"
echo "after receiving the Partially signed Provisional Tx"
echo "-------------"

#Broadcast DepositTx
bitcoin-cli sendrawtransaction "$DepositTxSigned" >/dev/null 2>&1

echo "-------------"
echo "Generating Block to confirm the Deposit Tx"
echo "-------------"

#Confirm the transaction in a block
bitcoin-cli generatetoaddress 1 "$DepositorAdrs" >/dev/null 2>&1

DepositTxBlock=$(bitcoin-cli getbestblockhash)

echo "-------------"
echo "Deposit Tx Block: $DepositTxBlock"
echo "-------------"

echo "-------------"
echo "Confirmed Deposit Tx"
echo "-------------"

bitcoin-cli getrawtransaction "$DepositTxID" true "$DepositTxBlock"

echo "-------------"
echo "***CoinVault Setup Complete!***"
echo "-------------"

#######################################
#
# Now the Deositor is intiating Recovery
# as the Vault has gone rogue and is
# not responding
#
#######################################

echo "-------------"
echo "Simulating the recovery process by Depositor"
echo "as the Vault has gone rogue and is not responding!"
echo "-------------"

echo "-------------"
echo "Depositor signs the Partially Signed"
echo "Provisional Tx with his Private Key and Hardware Token"
echo "-------------"

DepositorTokenSignatureProv=$(./bx input-sign -c bx.cfg $(./bx wif-to-ec $DepositorTokenPriv) "$DepositTxRedeemScriptAsm" $ProvTx)

echo "-------------"
echo "DepositorToken generated Signature for Provisional Tx:"
echo $DepositorTokenSignatureProv
echo "-------------"

DepositorSignatureProv=$(./bx input-sign -c bx.cfg $(./bx wif-to-ec $DepositorPriv) "$DepositTxRedeemScriptAsm" $ProvTx)

echo "-------------"
echo "Depositor Private Key Generated Signature for Provisional Tx:"
echo $DepositorSignatureProv
echo "-------------"

ProvTxSigned=$(./bx input-set -c bx.cfg "[$VaultSignatureProv] [$DepositorTokenSignatureProv] [$DepositorSignatureProv] [$DepositTxRedeemScript]" $ProvTx)

echo "-------------"
echo "Provisional Tx Signed:"
echo $ProvTxSigned
echo "-------------"

bitcoin-cli decoderawtransaction "$ProvTxSigned"

ProvTxID=$(bitcoin-cli decoderawtransaction "$ProvTxSigned" | jq -r '.txid')
ProvTxScriptPubKey=$(bitcoin-cli decoderawtransaction "$ProvTxSigned" | jq '.vout[0] | .scriptPubKey.hex')

#######################################
#
# Deositor will broadcast ProvTx
# to intiative recovery
#
#######################################

echo "-------------"
echo "Vaildate Fully Signed Provisional Tx"
echo "-------------"

#Test ProvTx
bitcoin-cli testmempoolaccept "[ \"$ProvTxSigned\" ]"

echo "-------------"
echo "Broadcast Fully Signed Provisional Tx"
echo "-------------"

#Broadcast ProvTx
bitcoin-cli sendrawtransaction "$ProvTxSigned" >/dev/null 2>&1

echo "-------------"
echo "Generating Block to confirm Provisional Tx"
echo "-------------"

#Confirm the transaction in a block
bitcoin-cli generatetoaddress 1 "$DepositorAdrs" >/dev/null 2>&1

ProvTxBlock=$(bitcoin-cli getbestblockhash)

echo "-------------"
echo "Provisional Tx Block: $ProvTxBlock"
echo "-------------"

echo "-------------"
echo "Confirmed Provisional Tx"
echo "-------------"

bitcoin-cli getrawtransaction "$ProvTxID" true "$ProvTxBlock"

#########################################
#
# Depository will create a Recovery Tx
# to complete recovery
# 
#########################################

echo "-------------"
echo "Simulating Recovery by depository Using" # [Customize This in accordance with Option]
echo "***Option 1*** of Provisonal Tx"
echo "(Corresponds to Option 2 in Figures)"
echo "-------------"

# [Customize This in accordance with Option]
read -r -d '' RecovTxInputs <<-EOM
    [
        {
            "txid": "$ProvTxID",
            "vout": 0,
            "sequence": 1000
        }
    ]
EOM

read -r -d '' RecovTxOutputs <<-EOM
    [
        {
            "$DepositorAdrs": 49.997
        }
    ]
EOM

echo "-------------"
echo "Creating Recovery Tx"
echo "-------------"

RecovTx=$(bitcoin-cli createrawtransaction "$RecovTxInputs" "$RecovTxOutputs")

echo "-------------"
echo "Unsigned Recovery Tx"
echo "-------------"

bitcoin-cli decoderawtransaction "$RecovTx"

ProvTxRedeemScriptAsm=$(./bx script-decode $ProvTxRedeemScript)

DepositorTokenSignatureRecov=$(./bx input-sign -c bx.cfg $(./bx wif-to-ec $DepositorTokenPriv) "$ProvTxRedeemScriptAsm" $RecovTx)

echo "-------------"
echo "DepositorToken generated Signature for Recovery Tx:"
echo $DepositorTokenSignatureRecov
echo "-------------"

DepositorSignatureRecov=$(./bx input-sign -c bx.cfg $(./bx wif-to-ec $DepositorPriv) "$ProvTxRedeemScriptAsm" $RecovTx)

echo "-------------"
echo "Depositor Private Key generated Signature for Recovery Tx:"
echo $DepositorSignatureRecov
echo "-------------"

# [Customize This in accordance with Option]
RecovTxSigned=$(./bx input-set -c bx.cfg "[$DepositorTokenSignatureRecov] [$DepositorSignatureRecov] 1 [$ProvTxRedeemScript]" $RecovTx)

echo "-------------"
echo "Signed Recovery Tx:"
echo $RecovTxSigned
echo "-------------"

bitcoin-cli decoderawtransaction "$RecovTxSigned"

RecovTxID=$(bitcoin-cli decoderawtransaction "$RecovTxSigned" | jq -r '.txid')
RecovTxScriptPubKey=$(bitcoin-cli decoderawtransaction "$RecovTxSigned" | jq '.vout[0] | .scriptPubKey.hex')

#######################################
#
# Depositor will broadcast RecovTx
# to intiative recovery
#
#######################################

echo "-------------"
echo "Creating Blocks to satisfy Timelocks"
echo "-------------"

#Create blocks to unlock the timelock [Customize This in accordance with Option]
bitcoin-cli generatetoaddress 5000 "$DepositorAdrs" >/dev/null 2>&1

echo "-------------"
echo "Vaildating Recovery Tx"
echo "-------------"

#Test ProvTx
bitcoin-cli testmempoolaccept "[ \"$RecovTxSigned\" ]"

echo "-------------"
echo "Broadcasting Recovery Tx"
echo "-------------"

#Broadcast ProvTx
bitcoin-cli sendrawtransaction "$RecovTxSigned" >/dev/null 2>&1

echo "-------------"
echo "Generating Block to confirm Recovery Tx"
echo "-------------"

#Confirm the transaction in a block
bitcoin-cli generatetoaddress 1 "$DepositorAdrs" >/dev/null 2>&1

RecovTxBlock=$(bitcoin-cli getbestblockhash)

echo "-------------"
echo "Recovery Tx Block ID: $RecovTxBlock"
echo "-------------"

echo "-------------"
echo "Confirmed Recovery Tx"
echo "-------------"

bitcoin-cli getrawtransaction "$RecovTxID" true "$RecovTxBlock"

echo "-------------"
echo "***Recovery Complete!***"
echo "-------------"

##############################

echo "-------------"
echo "Stopping Bitcoind"
echo "-------------"

#stop bitcoind
bitcoin-cli stop