#!/bin/bash

trivy image sample-app:1.0.0 --severity HIGH,CRITICAL
