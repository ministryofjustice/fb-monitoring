Form Builder Monitoring Tools
===

This repository houses:

- Grafana Dashboard
- Alerting rules using AlertManager

Alerting is currently configured across three destinations:

- Platform
- Services

## Deploying Changes to Alerts

There is a [CircleCI](https://circleci.com/gh/ministryofjustice/fb-monitoring) job which takes care of this.

At the moment it is best to manually check the output of the deploys to each environment as it is possible for the build to show green when in fact there was an error returned from the kubectl command.

If you have permission to access the cluster it is also possibly to apply changes from a local machine:

`ruby scripts/deploy_alerting.rb <destination> <platform_env> <deployment_env>`

E.g

`ruby scripts/deploy_alerting.rb platform test dev`


## Troubleshooting

### invalid: metadata.resourceVersion

Potential error message:

```
The prometheusrules "fb-alerting-platform-test-dev" is invalid: metadata.resourceVersion: Invalid value: 0x0: must be specified for an update
```

The kubectl command is unable to retrieve the necessary resource version information from the target destination. The easiest way to fix this is to remove the prometheusrule:

`kubectl delete prometheusrule fb-alerting-platform-test-dev -n formbuilder-platform-test-dev`

You can run this from your local machine if you have permission to access the cluster.

It is possible you will need to do this for all the destinations, platform envs and deployment envs. Check the output from the [CircleCI](https://circleci.com/gh/ministryofjustice/fb-monitoring) job to ascertain whether this is necessary.
