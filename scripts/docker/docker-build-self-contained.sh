#!/bin/bash

SCRIPT_DIR=$(dirname "$0")
APP_DIR=$SCRIPT_DIR/../../src/DotnetContainerOptimization.SampleApp
docker build $@ -t sample-app-self-contained:1.0.0 -t sample-app-self-contained:latest -f $APP_DIR/Dockerfile.self-contained $APP_DIR
