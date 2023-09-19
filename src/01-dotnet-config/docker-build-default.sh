#!/bin/bash

SCRIPT_DIR=$(dirname "$0")
docker build --no-cache -t 01-dotnet-config:1.0.0 -t 01-dotnet-config:latest -f $SCRIPT_DIR/Dockerfile.default $SCRIPT_DIR
