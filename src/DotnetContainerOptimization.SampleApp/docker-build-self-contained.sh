#!/bin/bash

SCRIPT_DIR=$(dirname "$0")
docker build $@ -t sample-app-self-contained:1.0.0 -t sample-app-self-contained:latest -f $SCRIPT_DIR/Dockerfile.self-contained $SCRIPT_DIR
