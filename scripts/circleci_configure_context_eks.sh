#!/bin/sh
set -e

destination=$1
platform_env=$2
deployment_env=$3

# NOTE: for historical reasons, the EKS_TOKEN for `hmcts_complaints_adapter`
# is retrieved from the `fb-monitoring` CircleCI environment variables.
# However the EKS_TOKEN for `platform` or `services` are retrieved from the
# contexts `moj-forms-platform-apps` or `moj-forms-services-apps`.
# And they also have different names, because why make it consistent :facepalm:

if [ "$destination" = 'hmcts_complaints_adapter' ]; then
  # hmcts_complaints_adapter_staging, hmcts_complaints_adapter_production
  string="${destination}_${platform_env}"

  upcase_string=$(echo "$string" | tr a-z A-Z)
  token=$(eval "echo \$EKS_${upcase_string}_TOKEN" | sed 's/ //g' | base64 -d)
else
  # test_dev, test_production, live_dev, live_production
  string="${platform_env}_${deployment_env}"
  string=$(echo "$string" | awk '{ gsub(/_$/, ""); print }')

  upcase_string=$(echo "$string" | tr a-z A-Z)
  token=$(eval "echo \$EKS_TOKEN_${upcase_string}" | sed 's/ //g' | base64 -d)
fi

user="circleci_${string}"
cluster=${EKS_CLUSTER:-$EKS_CLUSTER_NAME}

echo "kubectl configure credentials for user $user"
kubectl config set-credentials "${user}" --token="${token}"

echo "kubectl configure context"
kubectl config set-context "${user}" --cluster="${cluster}" --user="${user}"

echo "kubectl use context"
kubectl config use-context "${user}"
