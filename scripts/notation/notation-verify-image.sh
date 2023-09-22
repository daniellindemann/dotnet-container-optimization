#!/bin/bash

IMAGE_TO_VERIFY='localhost:5001/sample-app:1.0.0'   # it's better practice to use digest

echo "--- Verify image ---"
notation verify $IMAGE_TO_VERIFY
