#!/usr/bin/bash

set -x

cd ~ 

declare -A pods
pods=(
    ["bind"]="$(kubectl -n kube-system get pods -l component=kube-scheduler -o jsonpath='{.items[0].metadata.name}')"
    ["create"]="$(kubectl -n kube-system get pods -l component=kube-controller-manager -o jsonpath='{.items[0].metadata.name}')"
    ["dec"]="$(kubectl -n knative-serving get pods -l app=autoscaler -o jsonpath='{.items[0].metadata.name}')"
    ["patch"]="$(kubectl -n knative-serving get pods -l app=autoscaler -o jsonpath='{.items[0].metadata.name}')"
    ["decision"]="$(kubectl -n knative-serving get pods -l app=autoscaler -o jsonpath='{.items[0].metadata.name}')"
)

mkdir -p outs && rm ~/outs/*

declare -A sessions
sessions=(
    ["bind"]="kubectl -n kube-system logs --since=30s -f ${pods[bind]} | grep --line-buffered 'Pod Scheduled Successfully' > ~/outs/bind 2>&1"
    ["create"]="kubectl -n kube-system logs --since=30s -f ${pods[create]} | grep --line-buffered 'Controller created pod' > ~/outs/create 2>&1"
    ["dec"]="kubectl -n knative-serving logs --since=30s -f ${pods[dec]} | grep  --line-buffered -E 'For=.* PodCount=.*' > ~/outs/dec 2>&1"
    ["patch"]="kubectl -n knative-serving logs --since=30s -f ${pods[patch]} | grep --line-buffered -E 'Successfully scaled to' > ~/outs/patch 2>&1"
    ["decision"]="kubectl -n knative-serving logs --since=30s -f ${pods[decision]} | grep --line-buffered -E 'Decided in.*' > ~/outs/decision 2>&1"
)

for session in "${!sessions[@]}"; do
    tmux new-session -d -s "$session" "${sessions[$session]}"
    echo "Started tmux session '$session' for pod '${pods[$session]}'"
done

echo "All logs are being stored in the 'outs' directory."
