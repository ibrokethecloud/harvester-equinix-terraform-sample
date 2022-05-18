## Harvester on Equinix

Simple example using the Terraform Equinix provider to create a multi-node Harvester cluster.

The user needs to provide two environment variables

`METAL_AUTH_TOKEN` API token to access your Equinix account. Create an account
if you don't already have one at https://metal.equinix.com . 

`TF_VAR_project_name` Terraform variable to identify the project in your Equinix Metal account.
For more info about how projects are organized on Metal, see https://metal.equinix.com/developers/docs/accounts/projects/ .

By default the module will create a 3 node Harvester cluster.

The Harvester console can be accessed using an Elastic IP created by the sample.
For more reading on Elastic IP at Metal, see https://metal.equinix.com/developers/docs/networking/elastic-ips/ .

A random token and password will be generated for your example.
