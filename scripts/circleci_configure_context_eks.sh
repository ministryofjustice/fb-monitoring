#!/bin/sh

platform_env=$2
deployment_env=$3

# test_dev, test_production, live_dev, live_production
string="${platform_env}_${deployment_env}"
string=$(echo $string | awk '{ gsub(/_$/, ""); print }')

upcase_string=$(echo $string | tr a-z A-Z)
token=$(eval echo "\$EKS_TOKEN_${upcase_string}" | base64 -d)

echo "kubectl configure credentials"
kubectl config set-credentials "circleci_${string}" --token="${token}"

echo "kubectl configure context"
kubectl config set-context "circleci_${string}" --cluster="$EKS_CLUSTER_NAME" --user="circleci_${string}"

echo "kubectl use circleci context"
kubectl config use-context "circleci_${string}"
