#!/bin/sh

alert=$1
platform_env=$2
deployment_env=$3

string="${alert}_${platform_env}_${deployment_env}"
string=$(echo $string | awk '{ gsub(/_$/, ""); print }')

upcase_string=$(echo $string | tr a-z A-Z)
token=$(eval echo "\$EKS_${upcase_string}_TOKEN" | base64 -d)

echo "kubectl configure credentials"
kubectl config set-credentials "circleci_${string}" --token="${token}"

echo "kubectl configure context"
kubectl config set-context "circleci_${string}" --cluster="$EKS_CLUSTER" --user="circleci_${string}"

echo "kubectl use circleci context"
kubectl config use-context "circleci_${string}"
