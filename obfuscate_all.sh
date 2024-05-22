#!/bin/bash

for file in routes/*/sh/*.sh; do
  if [[ "$file" != *.obfuscated.sh ]]; then
    tmp=$(basename "$file" .sh)
    bash-obfuscate "$file" -o "routes/exec/sh/${tmp}.obfuscated.sh"
  fi
done
