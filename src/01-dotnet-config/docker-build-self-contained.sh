#!/bin/bash

SCRIPT_DIR=$(dirname "$0")
docker build $@ -t 01-dotnet-config-self-contained:1.0.0 -t 01-dotnet-config-self-contained:latest -f $SCRIPT_DIR/Dockerfile.self-contained $SCRIPT_DIR
