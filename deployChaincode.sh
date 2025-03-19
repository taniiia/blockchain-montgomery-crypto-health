export CORE_PEER_TLS_ENABLED=true
export ORDERER_CA=${PWD}/artifacts/channel/crypto-config/ordererOrganizations/pesuhospital.com/orderers/orderer.pesuhospital.com/msp/tlscacerts/tlsca.pesuhospital.com-cert.pem
export PEER0_BLR_CA=${PWD}/artifacts/channel/crypto-config/peerOrganizations/blr.pesuhospital.com/peers/peer0.blr.pesuhospital.com/tls/ca.crt
export PEER0_KPM_CA=${PWD}/artifacts/channel/crypto-config/peerOrganizations/kpm.pesuhospital.com/peers/peer0.kpm.pesuhospital.com/tls/ca.crt
export FABRIC_CFG_PATH=${PWD}/artifacts/channel/config/

export PRIVATE_DATA_CONFIG=${PWD}/artifacts/private-data/collections_config.json

export CHANNEL_NAME=mychannel

setGlobalsForOrderer() {
    export CORE_PEER_LOCALMSPID="OrdererMSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/artifacts/channel/crypto-config/ordererOrganizations/pesuhospital.com/orderers/orderer.pesuhospital.com/msp/tlscacerts/tlsca.pesuhospital.com-cert.pem
    export CORE_PEER_MSPCONFIGPATH=${PWD}/artifacts/channel/crypto-config/ordererOrganizations/pesuhospital.com/users/Admin@pesuhospital.com/msp

}

setGlobalsForPeer0BLR() {
    export CORE_PEER_LOCALMSPID="PESUHospitalBLRMSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_BLR_CA
    export CORE_PEER_MSPCONFIGPATH=${PWD}/artifacts/channel/crypto-config/peerOrganizations/blr.pesuhospital.com/users/Admin@blr.pesuhospital.com/msp
    # export CORE_PEER_MSPCONFIGPATH=${PWD}/artifacts/channel/crypto-config/peerOrganizations/blr.pesuhospital.com/peers/peer0.blr.pesuhospital.com/msp
    export CORE_PEER_ADDRESS=localhost:7051
}

setGlobalsForPeer1BLR() {
    export CORE_PEER_LOCALMSPID="PESUHospitalBLRMSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_BLR_CA
    export CORE_PEER_MSPCONFIGPATH=${PWD}/artifacts/channel/crypto-config/peerOrganizations/blr.pesuhospital.com/users/Admin@blr.pesuhospital.com/msp
    export CORE_PEER_ADDRESS=localhost:8051

}

setGlobalsForPeer0KPM() {
    export CORE_PEER_LOCALMSPID="PESUHospitalKPMMSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_KPM_CA
    export CORE_PEER_MSPCONFIGPATH=${PWD}/artifacts/channel/crypto-config/peerOrganizations/kpm.pesuhospital.com/users/Admin@kpm.pesuhospital.com/msp
    export CORE_PEER_ADDRESS=localhost:9051

}

setGlobalsForPeer1KPM() {
    export CORE_PEER_LOCALMSPID="PESUHospitalKPMMSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_KPM_CA
    export CORE_PEER_MSPCONFIGPATH=${PWD}/artifacts/channel/crypto-config/peerOrganizations/kpm.pesuhospital.com/users/Admin@kpm.pesuhospital.com/msp
    export CORE_PEER_ADDRESS=localhost:10051

}

presetup() {
    echo Vendoring Go dependencies ...
    pushd ./artifacts/src/github.com/fabcar/go
    GO111MODULE=on go mod vendor
    popd
    echo Finished vendoring Go dependencies
}
#presetup

CHANNEL_NAME="mychannel"
CC_RUNTIME_LANGUAGE="golang"
VERSION="1"
CC_SRC_PATH="./artifacts/src/github.com/fabcar/go"
CC_NAME="fabcar"

packageChaincode() {
    rm -rf ${CC_NAME}.tar.gz
    #setGlobalsForPeer0BLR
    peer lifecycle chaincode package ${CC_NAME}.tar.gz \
        --path ${CC_SRC_PATH} --lang ${CC_RUNTIME_LANGUAGE} \
        --label ${CC_NAME}_${VERSION}
    echo "===================== Chaincode is packaged on peer0.blr ===================== "
}
#packageChaincode

installChaincode() {
    setGlobalsForPeer0BLR
    peer lifecycle chaincode install ${CC_NAME}.tar.gz
    echo "===================== Chaincode is installed on peer0.blr ===================== "

    setGlobalsForPeer1BLR
    peer lifecycle chaincode install ${CC_NAME}.tar.gz
    echo "===================== Chaincode is installed on peer1.blr ===================== "

    setGlobalsForPeer0KPM
    peer lifecycle chaincode install ${CC_NAME}.tar.gz
    echo "===================== Chaincode is installed on peer0.kpm ===================== "

    setGlobalsForPeer1KPM
    peer lifecycle chaincode install ${CC_NAME}.tar.gz
    echo "===================== Chaincode is installed on peer1.kpm ===================== "
}

#installChaincode

queryInstalled() {
    setGlobalsForPeer0BLR
    peer lifecycle chaincode queryinstalled >&log.txt
    cat log.txt
    PACKAGE_ID=$(sed -n "/${CC_NAME}_${VERSION}/{s/^Package ID: //; s/, Label:.*$//; p;}" log.txt)
    echo PackageID is ${PACKAGE_ID}
    echo "===================== Query installed successful on peer0.blr on channel ===================== "
}

#queryInstalled

# --collections-config ./artifacts/private-data/collections_config.json \
#         --signature-policy "OR('PESUHospitalBLRMSP.member','PESUHospitalKPMMSP.member')" \
# --collections-config $PRIVATE_DATA_CONFIG \

approveForMyBLR() {
    setGlobalsForPeer0BLR
    # set -x
    peer lifecycle chaincode approveformyorg -o localhost:7050 \
        --ordererTLSHostnameOverride orderer.pesuhospital.com --tls \
        --collections-config $PRIVATE_DATA_CONFIG \
        --cafile $ORDERER_CA --channelID $CHANNEL_NAME --name ${CC_NAME} --version ${VERSION} \
        --init-required --package-id ${PACKAGE_ID} \
        --sequence ${VERSION}
    # set +x

    echo "===================== chaincode approved from blr ===================== "

}

#approveForMyBLR

getBlock() {
    setGlobalsForPeer0BLR
    # peer channel fetch 10 -c mychannel -o localhost:7050 \
    #     --ordererTLSHostnameOverride orderer.pesuhospital.com --tls \
    #     --cafile $ORDERER_CA

    peer channel getinfo  -c mychannel -o localhost:7050 \
        --ordererTLSHostnameOverride orderer.pesuhospital.com --tls \
        --cafile $ORDERER_CA
}

# getBlock

# approveForMyBLR

# --signature-policy "OR ('PESUHospitalBLRMSP.member')"
# --peerAddresses localhost:7051 --tlsRootCertFiles $PEER0_BLR_CA --peerAddresses localhost:9051 --tlsRootCertFiles $PEER0_KPM_CA
# --peerAddresses peer0.blr.pesuhospital.com:7051 --tlsRootCertFiles $PEER0_BLR_CA --peerAddresses peer0.kpm.pesuhospital.com:9051 --tlsRootCertFiles $PEER0_KPM_CA
#--channel-config-policy Channel/Application/Admins
# --signature-policy "OR ('PESUHospitalBLRMSP.peer','PESUHospitalKPMMSP.peer')"

checkCommitReadyness() {
    setGlobalsForPeer0BLR
    peer lifecycle chaincode checkcommitreadiness \
        --collections-config $PRIVATE_DATA_CONFIG \
        --channelID $CHANNEL_NAME --name ${CC_NAME} --version ${VERSION} \
        --sequence ${VERSION} --output json --init-required
    echo "===================== checking commit readyness from blr ===================== "
}

##checkCommitReadyness

# --collections-config ./artifacts/private-data/collections_config.json \
# --signature-policy "OR('PESUHospitalBLRMSP.member','PESUHospitalKPMMSP.member')" \
approveForMyKPM() {
    setGlobalsForPeer0KPM

    peer lifecycle chaincode approveformyorg -o localhost:7050 \
        --ordererTLSHostnameOverride orderer.pesuhospital.com --tls $CORE_PEER_TLS_ENABLED \
        --cafile $ORDERER_CA --channelID $CHANNEL_NAME --name ${CC_NAME} \
        --collections-config $PRIVATE_DATA_CONFIG \
        --version ${VERSION} --init-required --package-id ${PACKAGE_ID} \
        --sequence ${VERSION}

    echo "===================== chaincode approved from kpm ===================== "
}

#approveForMyKPM

checkCommitReadyness() {

    setGlobalsForPeer0BLR
    peer lifecycle chaincode checkcommitreadiness --channelID $CHANNEL_NAME \
        --peerAddresses localhost:7051 --tlsRootCertFiles $PEER0_BLR_CA \
        --collections-config $PRIVATE_DATA_CONFIG \
        --name ${CC_NAME} --version ${VERSION} --sequence ${VERSION} --output json --init-required
    echo "===================== checking commit readyness from blr===================== "
}

#checkCommitReadyness

commitChaincodeDefinition() {
    setGlobalsForPeer0BLR
    peer lifecycle chaincode commit -o localhost:7050 --ordererTLSHostnameOverride orderer.pesuhospital.com \
        --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA \
        --channelID $CHANNEL_NAME --name ${CC_NAME} \
        --collections-config $PRIVATE_DATA_CONFIG \
        --peerAddresses localhost:7051 --tlsRootCertFiles $PEER0_BLR_CA \
        --peerAddresses localhost:9051 --tlsRootCertFiles $PEER0_KPM_CA \
        --version ${VERSION} --sequence ${VERSION} --init-required

}

#commitChaincodeDefinition

queryCommitted() {
    setGlobalsForPeer0BLR
    peer lifecycle chaincode querycommitted --channelID $CHANNEL_NAME --name ${CC_NAME}

}

#queryCommitted

chaincodeInvokeInit() {
    setGlobalsForPeer0BLR
    peer chaincode invoke -o localhost:7050 \
        --ordererTLSHostnameOverride orderer.pesuhospital.com \
        --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA \
        -C $CHANNEL_NAME -n ${CC_NAME} \
        --peerAddresses localhost:7051 --tlsRootCertFiles $PEER0_BLR_CA \
        --peerAddresses localhost:9051 --tlsRootCertFiles $PEER0_KPM_CA \
        --isInit -c '{"Args":[]}'
}

#chaincodeInvokeInit

chaincodeInvoke() {
    # setGlobalsForPeer0BLR
    # peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.pesuhospital.com \
    # --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n ${CC_NAME} \
    # --peerAddresses localhost:7051 --tlsRootCertFiles $PEER0_BLR_CA \
    # --peerAddresses localhost:9051 --tlsRootCertFiles $PEER0_KPM_CA  \
    # -c '{"function":"initLedger","Args":[]}'

    setGlobalsForPeer0BLR

    ## Create Car
    # peer chaincode invoke -o localhost:7050 \
    #     --ordererTLSHostnameOverride orderer.pesuhospital.com \
    #     --tls $CORE_PEER_TLS_ENABLED \
    #     --cafile $ORDERER_CA \
    #     -C $CHANNEL_NAME -n ${CC_NAME}  \
    #     --peerAddresses localhost:7051 \
    #     --tlsRootCertFiles $PEER0_BLR_CA \
    #     --peerAddresses localhost:9051 --tlsRootCertFiles $PEER0_KPM_CA   \
    #     -c '{"function": "createCar","Args":["Car-ABCDEEE", "Audi", "R8", "Red", "Pavan"]}'

    ## Init ledger
    peer chaincode invoke -o localhost:7050 \
        --ordererTLSHostnameOverride orderer.pesuhospital.com \
        --tls $CORE_PEER_TLS_ENABLED \
        --cafile $ORDERER_CA \
        -C $CHANNEL_NAME -n ${CC_NAME} \
        --peerAddresses localhost:7051 --tlsRootCertFiles $PEER0_BLR_CA \
        --peerAddresses localhost:9051 --tlsRootCertFiles $PEER0_KPM_CA \
        -c '{"function": "initLedger","Args":[]}'

    ## Add private data
    # export CAR=$(echo -n "{\"key\":\"1111\", \"make\":\"Tesla\",\"model\":\"Tesla A1\",\"color\":\"White\",\"owner\":\"pavan\",\"price\":\"10000\"}" | base64 | tr -d \\n)
    # peer chaincode invoke -o localhost:7050 \
    #     --ordererTLSHostnameOverride orderer.pesuhospital.com \
    #     --tls $CORE_PEER_TLS_ENABLED \
    #     --cafile $ORDERER_CA \
    #     -C $CHANNEL_NAME -n ${CC_NAME} \
    #     --peerAddresses localhost:7051 --tlsRootCertFiles $PEER0_BLR_CA \
    #     --peerAddresses localhost:9051 --tlsRootCertFiles $PEER0_KPM_CA \
    #     -c '{"function": "createPrivateCar", "Args":[]}' \
    #     --transient "{\"car\":\"$CAR\"}"
}

#chaincodeInvoke

chaincodeQuery() {
    setGlobalsForPeer0KPM

    # Query all cars
    # peer chaincode query -C $CHANNEL_NAME -n ${CC_NAME} -c '{"Args":["queryAllCars"]}'

    # Query Car by Id
    peer chaincode query -C $CHANNEL_NAME -n ${CC_NAME} -c '{"function": "queryCar","Args":["CAR0"]}'
    #'{"Args":["GetSampleData","Key1"]}'

    # Query Private Car by Id
    # peer chaincode query -C $CHANNEL_NAME -n ${CC_NAME} -c '{"function": "readPrivateCar","Args":["1111"]}'
    # peer chaincode query -C $CHANNEL_NAME -n ${CC_NAME} -c '{"function": "readCarPrivateDetails","Args":["1111"]}'
}
#chaincodeQuery

# Run this function if you add any new dependency in chaincode
# presetup

# packageChaincode
# installChaincode
# queryInstalled
# approveForMyBLR
# checkCommitReadyness
# approveForMyKPM
# checkCommitReadyness
# commitChaincodeDefinition
# queryCommitted
# chaincodeInvokeInit
# sleep 5
# chaincodeInvoke
# sleep 3
# chaincodeQuery
