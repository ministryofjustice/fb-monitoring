#!/bin/sh
set -e

platform_env=$2
deployment_env=$3

# test_dev, test_production, live_dev, live_production
string="${platform_env}_${deployment_env}"
string=$(echo "$string" | awk '{ gsub(/_$/, ""); print }')

upcase_string=$(echo "$string" | tr a-z A-Z)
token=$(eval "echo \$EKS_TOKEN_${upcase_string}" | sed 's/ //g' | base64 -d)

user="circleci_${string}"
cluster=${EKS_CLUSTER:-$EKS_CLUSTER_NAME}

echo "kubectl configure credentials for user $user"
kubectl config set-credentials "${user}" --token="${token}"

echo "kubectl configure context"
kubectl config set-context "${user}" --cluster="${cluster}" --user="${user}"

echo "kubectl use context"
kubectl config use-context "${user}"
