# PoWOP Infrastructure

Kubernetes configs and some utilities for managing Plants of the World Online on Google
Container Engine

## Usage

Helm is used for managing k8s configurations. See Helm 
[installation instructions](https://github.com/kubernetes/helm/blob/master/docs/install.md)

Once Helm is installed on the kubernetes cluster, you have to bootstrap a few
cluster-wide resources (storageclasses) by running

    $ kubectl create -f bootstrap/storage_classes.yaml

Then you can install a powop installation by running

    $ helm install -f [ path to secrets file ] .

Parallel releases can be installed in the same cluster by specifying a `--namespace`

    $ helm install --namespace uat -f [ path to secrets file ] .

Any namespace-specific overrides are in values files named the same as the namespace

    $ helm install --namespace uat -f uat.yaml -f [path to uat secrets] .

## Secrets

Secrets are kept in a separate, limited access repository. They are included here as a
git submodule in the `secrets` folder. If you have access to the repository, you can
initialize it with:

    $ git submodule init
    $ git submodule update
