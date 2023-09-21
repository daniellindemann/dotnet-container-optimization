#!/bin/bash

IMAGE_TO_SIGN='localhost:5001/01-dotnet-config:1.0.0'   # it's better practice to use digest

echo "--- Sign image ---"
notation sign --signature-format cose $IMAGE_TO_SIGN

echo "--- Verify signature on image ---"
notation ls $IMAGE_TO_SIGN
