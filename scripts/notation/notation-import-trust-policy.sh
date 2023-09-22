#!/bin/bash

IMAGE_TO_SIGN='localhost:5001/sample-app:1.0.0'   # it's better practice to use digest

SCRIPT_DIR=$(dirname "$0")
CERT_CA="dlindemann.dev"

echo "--- Create policy ---"
cat <<EOF > $SCRIPT_DIR/trustpolicy.json
{
    "version": "1.0",
    "trustPolicies": [
        {
            "name": "dlindemnn-dev-images",
            "registryScopes": [ "*" ],
            "signatureVerification": {
                "level" : "strict"
            },
            "trustStores": [ "ca:$CERT_CA" ],
            "trustedIdentities": [
                "*"
            ]
        }
    ]
}
EOF
echo "File $SCRIPT_DIR/trustpolicy.json created"

echo "--- Import policy ---"
notation policy import $SCRIPT_DIR/trustpolicy.json

echo "--- Show policy ---"
notation policy show
