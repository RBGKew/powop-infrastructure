# Production Operations Manual

Production POWO is deployed via a Kubernetes cron job which re-builds the full system on a schedule. This extra layer of indirection can be somewhat confusing, so this guide aims to demystify the deployment process.

There are three repositories related to POWO:

* powop: [private](git@kppgitlab01.ad.kew.org:development/powop.git), [github](https://github.com/RBGKew/powop)
* powop-infrastructure: [private](git@kppgitlab01.ad.kew.org:development/powop-infrastructure.git), [github](git@github.com:RBGKew/powop-infrastructure.git)
* powo-secrets: [private](git@kppgitlab01.ad.kew.org:secrets/powop-secrets.git)

The components that make up the deployment system are:

* The builder which handles the orchistration of deploying, loading data, and swapping DNS, which lives in the main POWO code repo in ``powop/powo-builder``
* The kubernetes configuration for the builder job which lives in ``powop-infrastructure/powo-builder``
* The kubernetes configuration for deploying POWO which lives in ``powop-infrastructure/powo``
* Deployment credentials and production secrets which live in the private ``powop-secrets`` repo, included in this repo as a submodule ``powop-infrastructure/secrets`` which you can sync if you have access to

### Builder Update

You can skip any of the other steps unless you made builder configuration or code
changes.

4) If you have made changes to the builder scripts (in `powo/powo-builder`), make sure
an updated image is pushed to the image repo (`mvn deploy`) and the `builder.tag`
version is changed in the [builder values file](./powo-builder/values.yaml).

5) If you want to make changes to environment specific builder configuration, edit the
relevant [builder environment overrides](./powo-builder/prod.yaml). The options you can
set are:

    * `cluster`: name of Google Cloud Kubernetes cluster to deploy on
    * `environment`: prefix which all builder-managed releases will have
    * `deleteExisting`: If true, deletes the old release after the new one is ready and
      dns swapped. Otherwise, swap dns but leave the old one in place. Can be useful if
      you want extra saftety for rolling back to the old release if something goes wrong
    * `dns`: list of dns names to manage. Requires dns zone, name, and the name of the
      service with an external IP that this name should point to
    * `schedule`: cron formatted schedule for when the rebuilds should start
    * `strictErrorChecking`: if true, and failed data harvesting jobs will be considered
      build failures and the deploy will halt, leaving the existing release in place

6) Update the builder helm release

    helm upgrade -f secrets/prod/secrets.yaml -f secrets/deployer/secrets.yaml -f powo-builder/prod.yaml builder-prod powo-builder/

## Cluster Updates

Kubernetes clusters should be kept up to date regularly. You can upgrade the cluster
master version at any time without incuring downtime. To update the node pools in a
cluster, they have to restart, so any applications running in the given node pool will
go down and restart.

Edit the cluster in the google web console and add a new node pool. At the moment we are
running 2 nodes with 2vCPUs and 10GB of ram each with 50GB of boot disk.

We can avoid any downtime when upgrading powo node pools by making sure the new release
gets scheduled on the new nodes. 

    kubectl get nodes
    kubectl cordon gke-powo-dev-{each node in old node pool}

Once a node is cordoned, no pods will be scheduled on it, so when the rebuild happens
all pods will be scheduled onto the new nodes and the old node pool can be deleted.

## Troubleshooting

Start with checking if all the pods are starting up:
  
    kubectl get pods --all-namespaces

If any have non-Running statuses such as `Error`, `Pending`, etc, describe the pod to
see if there is anything wrong at the pod level.

    kubectl describe pod --namespace=prod-2hpwr portal-5b74d46cc7-27ssg

If a pod stays as `Pending` for a long time, it might not have the necessary resources
available anywhere to schedule onto a node.

If there are no errors there, check the container logs to see if whatever is running in
the container has any errors.

    kubectl logs --namepace=prod-2hpwr portal-5b74d46cc7-27ssg

To get the external IPs of any service that exposes one, run

    kubectl get services --all-namepaces

You can check what IP a dns name resolves to using `dig`

    $ dig powo.science.kew.org
		...
		ANSWER SECTION:
		powo.science.kew.org.   299     IN      CNAME   plantsoftheworldonline.org.
		plantsoftheworldonline.org. 299 IN      A       104.155.49.20
