# POWO Infrastructure

Kubernetes configs and some utilities for managing Plants of the World Online on Google
Container Engine. POWO can be installed in one of two ways. 

1. Install directly
2. Install a "builder" which will deploy and refresh the entire system on a set schedule

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
