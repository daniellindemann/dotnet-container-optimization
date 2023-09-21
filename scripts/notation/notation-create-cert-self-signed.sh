#!/bin/bash

echo "--- Generate self-signed key ---"
notation cert generate-test --default dlindemann.dev

echo "--- View generated key ---"
notation key ls

echo "--- Confirm cert in trust store ---" 
notation cert ls
