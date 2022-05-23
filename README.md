# POWO Infrastructure

Kubernetes configs and utilities for managing Plants of the World Online on Google Cloud. For the POWO source code see the [powop](https://gitlab.ad.kew.org/development/powop) repository.

There are two main deployed components:

1. The **POWO builder** which orchestrates weekly rebuilds of the POWO site
2. The **POWO site** itself

## Contents

- [Overview](#overview)
- [POWO Site](#powo-site)
- [POWO Builder](#powo-builder)
- Reference
  - [Bootstrapping](#bootstrapping)
  - [Secrets](#secrets)
  - [POWO Builder Install](#powo-builder-install)
  - [POWO Site Install](#powo-site-install)
  - [Data management](./doc/data-management.md)

# POWO Site

The POWO site deployment is the collection of services that makes up POWO (and related sites) - it combines the Helm configuration in `powo/` with the images built by the `powop` repo build process.

The site is redeployed from scratch every week by the POWO builder - Helm release, data, everything! However this build takes time and only occurs once weekly and is more aimed at keeping data up to date than making releases. For making releases there are two more convenient options than waiting for the weekly build: [upgrade](#upgrade) or [build](#trigger-build).

## Upgrade

If you are just making changes to the portal/dashboard and there _no_ data changes you can deploy without rebuilding all the data.

To do this you need to:

1. Build and push Docker images - `mvn clean deploy`
2. Update the image tags (in `powo/prod.yaml` for prod or `powo/uat.yaml` for uat) and commit these changes
3. Push the image tags to Github origin (this is required so that when the builder next runs it uses the same image)
4. Work out required variables:
   - `$RELEASE_CONTEXT` - `powo-dev` for UAT, `powo-prod` for production (or what you have set up in your Kubernetes context to access the relevant cluster)
   - `$RELEASE` - the latest built release, get using `helm ls`
   - `$ENVIRONMENT` - `uat` for UAT, `prod` for production
5. Upgrade the current release with the latest tags

```sh
helm upgrade $RELEASE powo/ --kube-context $RELEASE_CONTEXT -f secrets/$ENVIRONMENT/secrets.yaml -f powo/$ENVIRONMENT.yaml
```

For UAT:
```
helm upgrade RELEASE powo/ -f secrets/uat/secrets.yaml -f powo/uat.yaml
```

For Prod:
```
helm upgrade RELEASE powo/ -f secrets/prod/secrets.yaml -f powo/prod.yaml
```

### Upgrade Errors

Occasionally, upgrading the portal does not work properly. The ingress and portal containers become out of sync, so the CSS and JS assets are not loaded. 
TODO: figure out exactly why this happens.

To fix this, the steps are as follows:

1. Delete the bad containers in the Google Cloud Container Registry
2. Re-create the containers with `mvn clean deploy`
3. Restart the broken pods as follows:
    1. Get the namespace of the broken pods: `kubectl get ns`
    2. Scale the portal and ingress deployments to 0 pods:
        1. `kubectl scale --replicas=0 deployments/portal -n uat-nneom`
        2. `kubectl scale --replicas=0 deployments/ingress -n uat-nneom`
    3. Scale the portal and ingress deployments to 1 pod:
        1. `kubectl scale --replicas=1 deployments/portal -n uat-nneom`
        2. `kubectl scale --replicas=1 deployments/ingress -n uat-nneom`

## Build

If you want to deploy new images and also rebuild the data, you can trigger a build job immediately based on the `CronJob` defined by the POWO builder.

1. Build and push Docker images - `mvn clean deploy`
2. Update the image tags (in `powo/prod.yaml` for prod or `powo/uat.yaml` for uat) and commit these changes
3. Push the image tags to Github origin (this is required so that when the builder next runs it uses the same image
4. Work out required variables:
   - `$RELEASE_CONTEXT` - `powo-dev` for UAT, `powo-prod` for production (or what you have set up in your Kubernetes context to access the relevant cluster)
   - `$NAMESPACE` - `builder-uat` for UAT, `builder-prod` for production

```sh
kubectl create job deploy-manual --from=cronjob/builder --namespace=builder-uat --context $RELEASE_CONTEXT
```

> You may need to change the name from `deploy-manual` if there is an existing one there.

## Automated Build

The automated builds of the POWO site is executed based on the schedule defined in `powo-builder/prod.yaml`/`powo-builder/uat.yaml`

## Managing Automated Builds

You may need to manage the automated builds for example if one has failed or was triggered with incorrect configuration.

### Cancelling a job

To cancel a job we need to:

1. Stop the job and any pods it has created
2. Remove the Helm deployment created as part of the job
3. Remove the namespace created as part of the job.

#### 1 - Cancel the job

1. Get the job name using `kubectl get jobs -n builder-uat` - you will probably be looking for the youngest job
2. Delete the job using `kubectl delete jobs/<job_name> -n builder-uat`

#### 2 - Remove Helm deployment

1. Get the name of the Helm release using `helm ls` - you want the release which was created later
2. Delete the helm release using `helm delete --purge <release_name>`

The release name is also the name of the namespace - you will need it in the following step.

#### 3 - Remove the namespace

1. Get the namespace name based on the previous step, or run `kubectl get ns` and use the youngest namespace
2. Delete the old namespace using `kubectl delete ns <namespace_name>`

This step is required since the builder raises an error if there would be more than 2 namespaces at one time.

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

## POWO Builder Install

The POWO builder allows you to re-build the entire stack, and re-load a set of data,
automatically on a fixed schedule. It does this by running a "builder" script on a cron
schedule that:

- deploys a new release in it's own namespace
- loads a data configuration file
- harvests all data
- swaps DNS from old release to new when new release is complete
- deletes old release

This process allows for automated data upates to happen in the background and not impact
the performance and functioning of the live site.

When deploying on GCP, this will require a service account with the "Kubernetes Engine
Developer", "DNS Administrator", and "Storage Admin" roles. The service account key is
then deployed in a secret to the builder.

As an example, to deploy a builder that will build `dev` environment releases, run:

    $ helm install -f secrets/dev/secrets.yaml -f secrets/deployer/secrets.yaml --namespace builder-dev --name builder-dev powo-builder/

For more details on production operations, please see the [production operations
manual](./doc/production-deployment.md)

To upgrade the builder:

```
helm upgrade builder-uat powo-builder/ -f powo-builder/uat.yaml -f secrets/deployer/secrets.yaml -f secrets/uat/secrets.yaml
```

## POWO Site install

Then you can install a powo installation by running

    $ helm install -f [ path to secrets file ] powo/

Parallel releases can be installed in the same cluster by specifying a `--namespace`

    $ helm install --namespace uat -f [ path to secrets file ] powo/

Any namespace-specific overrides are in values files named the same as the namespace

    $ helm install --namespace uat -f uat.yaml -f [path to uat secrets] powo/

Upgrade

    $ helm upgrade --namespace uat -f uat.yaml -f [path to uat secrets] uat powo/


## Github Remote Setup

If you originally checked out powo from Gitlab, make sure you have a Github remote set up so that the builder can access image updates that you make.

    git remote add github git@github.com:RBGKew/powop-infrastructure.git