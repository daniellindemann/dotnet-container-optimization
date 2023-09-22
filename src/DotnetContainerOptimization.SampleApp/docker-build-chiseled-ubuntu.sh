#!/bin/bash

SCRIPT_DIR=$(dirname "$0")
docker build $@ -t sample-app-chiseled-ubuntu:1.0.0 -t sample-app-chiseled-ubuntu:latest -f $SCRIPT_DIR/Dockerfile.chiseled-ubuntu $SCRIPT_DIR
