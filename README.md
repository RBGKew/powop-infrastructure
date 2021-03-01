# POWO Infrastructure

Kubernetes configs and utilities for managing Plants of the World Online on Google Cloud.

There are two main deployed components:

1. The builder which orchestrates weekly rebuilds of the POWO site
2. The POWO site itself

POWO can be installed in one of two ways. 

1. Install directly
2. Install a "builder" which will deploy and refresh the entire system on a set schedule

## Contents

- [Overview](#overview)
- POWO Site
- POWO Builder
- For reference
  - [Bootstrapping](#bootstrapping)
  - [Secrets](#secrets)



## 1. Direct Install

Then you can install a powo installation by running

    $ helm install -f [ path to secrets file ] powo/

Parallel releases can be installed in the same cluster by specifying a `--namespace`

    $ helm install --namespace uat -f [ path to secrets file ] powo/

Any namespace-specific overrides are in values files named the same as the namespace

    $ helm install --namespace uat -f uat.yaml -f [path to uat secrets] powo/

Upgrade

    $ helm upgrade --namespace uat -f uat.yaml -f [path to uat secrets] uat powo/

## 2. Builder Install

The POWO builder allows you to re-build the entire stack, and re-load a set of data,
automatically on a fixed schedule. It does this by running a "builder" script on a cron
schedule that:

  * deploys a new release in it's own namespace
  * loads a data configuration file
  * harvests all data
  * swaps DNS from old release to new when new release is complete
  * deletes old release

This process allows for automated data upates to happen in the background and not impact
the performance and functioning of the live site.

When deploying on GCP, this will require a service account with the "Kubernetes Engine
Developer", "DNS Administrator", and "Storage Admin" roles. The service account key is
then deployed in a secret to the builder.

As an example, to deploy a builder that will build `dev` environment releases, run:

    $ helm install -f secrets/dev/secrets.yaml -f secrets/deployer/secrets.yaml --namespace builder-dev --name builder-dev powo-builder/

For more details on production operations, please see the [production operations
manual](./doc/production-deployment.md)

## 3. Direct update

Rebuilding the site can take a long time. If you are just making frontend changes it is possible to deploy these without rebuilding all the data.

To do this you need to:

1. Build the image
```sh
# from the root of the powop project
mvn clean deploy
```
2. Update the image tags (in `powo/prod.yaml` for prod or `powo/values.yaml` for uat) and commit these changes
3. Push the image tags to Github origin (this is required so that when the builder next runs it uses the same image)
4. Get the current release `$RELEASE` and the relevant Kubernetes context (`powo-dev` for UAT, `powo-prod` for production) `$RELEASE_CONTEXT`
```sh
helm ls 
# the namespace will be something like `uat-x7xns` or `prod-f4cir`
```
5. Work out required variables:
    - `$RELEASE_CONTEXT` - `powo-dev` for UAT, `powo-prod` for production (or what you have set up in your Kubernetes context to access the relevant cluster)
    - `$ENVIRONMENT` - `uat` for UAT, `prod` for production
6. Update the current release with the latest tags (based on )
```sh
helm upgrade $RELEASE powo/ --kube-context $RELEASE_CONTEXT -f secrets/$ENVIRONMENT/secrets.yaml -f powo/$ENVIRONMENT.yaml
```

## Data management

[Read documentation](./doc/data-management.md) or

[![Open in Cloud Shell](http://gstatic.com/cloudssh/images/open-btn.svg)](https://console.cloud.google.com/cloudshell/editor?shellonly=true&cloudshell_git_repo=https%3A%2F%2Fgithub.com%2FRBGKew%2Fpowop-infrastructure&cloudshell_tutorial=doc%2Fdata-management.md)



Deploy to UAT
---
 
* Update ‘powo-infrastructure/powo/values.yaml’ with your new portal image tag from google cloud container registry.
* Push the change to Github and Gitlab.
* Make sure google cloud context is `powo-dev`

`kubectl create job deploy-manual --from=cronjob/builder --namespace=builder-uat`

### Cancelling a job

To cancel a job we need to:

1. Stop the job and any pods it has created
2. Remove the Helm deployment created as part of the job
3. Remove the namespace created as part of the job.

**Cancel the job**

1. Get the job name using `kubectl get jobs -n builder-uat` - you will probably be looking for the youngest job
2. Delete the job using `kubectl delete jobs/<job_name> -n builder-uat`

**Remove Helm deployment**

1. Get the name of the Helm release using `helm ls` - you want the release which was created later
2. Delete the helm release using `helm delete --purge <release_name>`

The release name is also the name of the namespace - you will need it in the following step.

**Remove the namespace**

1. Get the namespace name based on the previous step, or run `kubectl get ns` and use the youngest namespace 
2. Delete the old namespace using `kubectl delete ns <namespace_name>`

This step is required since the builder raises an error if there would be more than 3 namespaces at one time.
 
Deploy to live
---
 
* Run deploy in root

* Update ‘powo-infrastructure/powo/prod.yaml’ with your new portal image tag from google cloud container registry.

* Push the change to Github and Gitlab.

* Switch your Google Cloud context to point to ‘powo-prod’ rather than ‘powo-dev’

* Run the same build command as you’ve been doing for UAT but change the namespace to ‘builder-prod’ e.g.

kubectl create job deploy-manual-live --from=cronjob/builder --namespace=builder-prod
 
 
 
# Reference

Reference documentation for one-time setup etc.

## Bootstrapping

Both methods use Helm to deploy the necessary components to your cluster. See Helm 
[installation instructions](https://github.com/kubernetes/helm/blob/master/docs/install.md)
to get set up.

Once Helm is installed on your machine and the kubernetes cluster, you have to bootstrap
a few cluster-wide resources by running the `bootstrap.sh` script. This initialises
storage classes and rbac roles needed for installation.

## Secrets

Secrets are kept in a separate, limited access repository. They are included here as a
git submodule in the `secrets` folder. If you have access to the repository, you can
initialize it with:

    $ git submodule init
    $ git submodule update