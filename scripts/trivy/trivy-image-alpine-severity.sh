#!/bin/bash

trivy image 01-dotnet-config-alpine:1.0.0 --severity HIGH,CRITICAL
