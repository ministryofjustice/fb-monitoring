#!/bin/sh
set -e

destination=$1
platform_env=$2
deployment_env=$3

# test_dev, test_production, live_dev, live_production
string="${platform_env}_${deployment_env}"
string=$(echo "$string" | awk '{ gsub(/_$/, ""); print }')

upcase_string=$(echo "$string" | tr a-z A-Z)
token=$(eval "echo \$EKS_TOKEN_${upcase_string}" | base64 -d)

user="circleci_${string}"
namespace="formbuilder-${destination}-${platform_env}-${deployment_env}"

echo "kubectl configure credentials for user $user"
kubectl config set-credentials "${user}" --token="${token}"

echo "kubectl configure context for namespace $namespace"
kubectl config set-context "${user}" --cluster="$EKS_CLUSTER_NAME" --user="${user}" --namespace="${namespace}"

echo "kubectl use context"
kubectl config use-context "${user}"
