#!/bin/bash
kubectl exec --stdin --tty --namespace="${1}" "${2}" env -- COLUMNS=$(tput cols) LINES=$(tput lines) TERM=$TERM bash -l
