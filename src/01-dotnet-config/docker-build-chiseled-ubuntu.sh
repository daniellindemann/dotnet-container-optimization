#!/bin/bash

SCRIPT_DIR=$(dirname "$0")
docker build $@ -t 01-dotnet-config-chiseled-ubuntu:1.0.0 -t 01-dotnet-config-chiseled-ubuntu:latest -f $SCRIPT_DIR/Dockerfile.chiseled-ubuntu $SCRIPT_DIR
