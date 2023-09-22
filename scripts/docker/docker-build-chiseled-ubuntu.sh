#!/bin/bash

SCRIPT_DIR=$(dirname "$0")
APP_DIR=$SCRIPT_DIR/../../src/DotnetContainerOptimization.SampleApp
docker build $@ -t sample-app-chiseled-ubuntu:1.0.0 -t sample-app-chiseled-ubuntu:latest -f $APP_DIR/Dockerfile.chiseled-ubuntu $APP_DIR
