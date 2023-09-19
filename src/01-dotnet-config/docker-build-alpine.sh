#!/bin/bash

SCRIPT_DIR=$(dirname "$0")
docker build --no-cache -t 01-dotnet-config-alpine:1.0.0 -t 01-dotnet-config-alpine:latest -f $SCRIPT_DIR/Dockerfile.alpine $SCRIPT_DIR
