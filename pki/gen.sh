#!/usr/bin/env bash

function new_ca {
  openssl genpkey -algorithm RSA -out cakey.pem -pkeyopt rsa_keygen_bits:4096

  openssl req -nodes -x509 -sha256 \
    -key cakey.pem \
    -out cacert.pem \
    -days 356 \
    -subj "${PREFIX}$1"  \
    -addext "basicConstraints=critical,CA:TRUE" \
    -addext "keyUsage=critical,keyCertSign,cRLSign"
}

function generate {
  openssl genpkey -algorithm RSA -out "${1}key.pem" -pkeyopt rsa_keygen_bits:4096

  openssl req -new -nodes -x509 \
    -CAkey cakey.pem \
    -CA cacert.pem \
    -key "${1}key.pem" \
    -out "${1}cert.pem" \
    -days 356 \
    -subj "${PREFIX}$2" \
    -addext "subjectAltName       = DNS:localhost,DNS:$2" \
    -addext "basicConstraints     = CA:FALSE" \
    -addext "keyUsage             = digitalSignature, keyEncipherment" \
    -addext "extendedKeyUsage     = serverAuth" \
    -addext "subjectKeyIdentifier = hash"

    #-addext "keyUsage=critical,digitalSignature" \
    #-addext "extendedKeyUsage=clientAuth"
}

function gen {
   generate "$1-"  "$1.${DOMAIN}"
}

DOMAIN="mac.wales"
PREFIX="/C=UK/ST=Wales/O=Mac/CN="

# new_ca "cluster.mac.wales"

generate "client"  "client.mac.wales"

gen "dwt" 
gen "smol" 
gen "wee" 
gen "dev" 

tar cvf pki.tar README install.sh *.pem
