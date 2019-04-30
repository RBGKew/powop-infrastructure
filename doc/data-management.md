# Data Management

## Admin interface 

POWO data archives can be managed through the powo dashboard at `/admin`

  * [Production](http://plantsoftheworldonline.org/admin)
  * [UAT](http://plantsoftheworld.online/admin)

Log in using the `password.harvester` value from the appropriate `secrets.yaml` file
from the `powo-secrets` repository

### Organisations and resources

When creating a new resource, only Title and URL are required. `Image Prefix` is used when
the image paths in your archive are relative (e.g., need a CDN prefix). This is not used
for Digifolia image archives.

`Skip indexing` can be used to optimise load times. When running a collection of large
jobs, it is much more efficient to skip indexing for the individual resources and do a
full re-index at the end.

Select `Harvest names` when loading the backbone names and `Harvest taxonomy` when
loading the taxonomy. Names must be loaded before taxonomy since all the taxonomy
harvest job does is make links between existing names.

### Jobs and Job Lists

A harvester job configuration is created for each resource. These can be run from the
Jobs tab. There is also a `Re index all taxa` job configuration by default which runs a
full re index. 

Job Lists can be created to run a list of jobs in sequence. By default there is a "Load
everything" list to load all resources and do a full index at the end. When adding new
resources, always remember to add them to this list so they are loaded during each data
refresh.

### Configuration Import/Export

Data configuration can be exported via Settings (gear icon) -> Export. This will export
a json representation of all organisations, resources, jobs, and job lists. 

Data configuration can only be imported into a blank database.

The automated powo rebuild uses this configuration file to load the full data set. It
pulls the configuration from the [powo-data
repository](https://github.com/RBGKew/powo-data). 

To get data changes to persist through a refresh, you must check in the updated data
configuration export to the appropriate file in powo-data.
 
## Troubleshooting


### Logs

When troubleshooting data load errors always start with checking the harvester logs:

  * [production
  logs](https://console.cloud.google.com/logs/viewer?project=powop-1349&interval=P1D&advancedFilter=resource.type%3D%22k8s_container%22%0Aresource.labels.cluster_name%3D%22powo-prod%22%0Aresource.labels.container_name%3D%22harvester%22%0A)
  * [uat logs](https://console.cloud.google.com/logs/viewer?project=powop-1349&interval=P1D&advancedFilter=resource.type%3D%22k8s_container%22%0Aresource.labels.cluster_name%3D%22powo-uat%22%0Aresource.labels.container_name%3D%22harvester%22%0A)

Thins such as DwCA metadata errors, harvester resource file not found errors will show
up here.

The second stop is the annotations table. 
