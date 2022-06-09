# terraform-controller-modules

Experiment using a terraform module stored in a git repo.

Tested with GKE K8S version: v1.23.5-gke.1501
Terraform controller images versions: oamdev/terraform-controller:0.7.0 / oamdev/docker-terraform:1.1.2
Kubevela version: v1.4.1


## Pros and Cons

Pros:

* Easy to use, just regular terraform modules. Modules are not specific to the controller.
* Terraform modules stored a git repo or by defining inline HCL.
* Terraform init, apply and output shown in the output (and logs)
* Inputs become properties in the app manifest. 
* Possible to pass environment vars to terraform.
* Controller is looping to apply the state continuously.
* Output can be stored as a secret in K8S and used in next service to retrieve credentials
* Possible to define SA for the terraform provider by namespace, each team can use the same terraform module but with a different account.
* Operators can use the terraform controller directly to define the resources in K8S, not need to use apps.
* The same git repository can store different modules, each own in a different path. The repository can include examples, docs, ...

Cons:

* `vela show <component>` does not show the input parameters, only output. When app manifest is defined, users need to know which properties are available/predefined.
* Output is logged, so secrets or sensitive data can be leaked (it can be avoid with sensitive = true)
* Update the git repo with the modules does not trigger the changes. App needs to be redeployed
* When app is redeployed changes can be because of app changes or because of terraform changes in git repo (done by operator).
* TF state backups need to be improved, only possible by a hack.
* Private repositories currently not supported, issue is open (should not be difficult to implement)
* Fixing a broken app -because errors in terraform modules- needs to be done with workflow commands or killing the pod


## K8S/Kubevela setup

1. Secret:
```
echo "gcpCredentialsJSON: '${GOOGLE_CREDENTIALS}'" > gcp-credentials.conf
echo "gcpProject: ${GOOGLE_PROJECT}" >> gcp-credentials.conf
kubectl create secret generic gcp-account-creds-project-test -n katee-engineering-enablement --from-file=credentials=gcp-credentials.conf
rm -f gcp-credentials.conf
```

2. Define provider settings pointing to the secret: `kubectl -n katee-engineering-enablement apply -f provider.yaml`

3. Create Kubevela component to deploy apps `kubectl -n katee-engineering-enablement apply -f cloudrun.yaml`

4. Check if component is there: `vela components --label vendor=sn`

5. Show component: `vela show test-cloudrun-ee`:
```
### Properties
+----------------------------+-------------------------------------------------------------------+-----------------------------------------------------------+----------+---------+
|            NAME            |                            DESCRIPTION                            |                           TYPE                            | REQUIRED | DEFAULT |
+----------------------------+-------------------------------------------------------------------+-----------------------------------------------------------+----------+---------+
| writeConnectionSecretToRef | The secret which the cloud resource connection will be written to | [writeConnectionSecretToRef](#writeConnectionSecretToRef) | false    |         |
+----------------------------+-------------------------------------------------------------------+-----------------------------------------------------------+----------+---------+


#### writeConnectionSecretToRef
+-----------+-----------------------------------------------------------------------------+--------+----------+---------+
|   NAME    |                                 DESCRIPTION                                 |  TYPE  | REQUIRED | DEFAULT |
+-----------+-----------------------------------------------------------------------------+--------+----------+---------+
| name      | The secret name which the cloud resource connection will be written to      | string | true     |         |
| namespace | The secret namespace which the cloud resource connection will be written to | string | false    |         |
+-----------+-----------------------------------------------------------------------------+--------+----------+---------+
```


### Notes

* The service account (SA) used by the provider can be created in a "main"/"host" project and bound in the destination `$GOOGLE_PROJECT` (where the Terraform resources will be created) with the needed roles/permissions. For this example the account was bound as owner of the `$GOOGLE_PROJECT`. The json key can be loaded in a environment variable like `GOOGLE_CREDENTIALS=$(cat account-key.json)`. Google API's may need to be enabled in order to manage GCP resources in `$GOOGLE_PROJECT`,


* The `ComponentDefinition` definition key `spec.schematic.terraform` can point to a specific provider reference:
```
      providerRef:
        name: gcp-project-test
        namespace: katee-engineering-enablement
```

* Also different labels can be defined in metatada (in the example `vendor`), these labels can be used to filter components with the cli.


* The provider reference can be used by differents `ComponentDefintion` components by metadata `name` and `namespace` keys. The spec includes the GCP project used by the terraform provider and the service account (as a secret, see creation process above):

```
apiVersion: terraform.core.oam.dev/v1beta1
kind: Provider
metadata:
  namespace: katee-engineering-enablement
  name: gcp-project-test
  labels:
    "config.oam.dev/catalog": "sn"
    "config.oam.dev/type": "terraform-provider"
    "config.oam.dev/provider": "terraform-gcp"
spec:
  provider: gcp
  region: europe-west4
  credentials:
    source: Secret
    secretRef:
      namespace: katee-engineering-enablement
      name: gcp-account-creds-project-test
      key: credentials
```

* K8S operators can use the terraform controller directly, by creating a `Configuration` definition pointing to the git repository/path and pointing to the proper provider reference (multiple providers are possible):
```
apiVersion: terraform.core.oam.dev/v1beta1
kind: Configuration
metadata:
  name: cloudrun
spec:
  remote: https://github.com/jriguera/terraform-controller-modules.git
  path: cloudrun
  variable:
     project: "project-id"
     service_name: "jose-test"
     image_name: "gcr.io/cloudrun/hello"
  providerRef:
    name: gcp-project-test
    namespace: katee-engineering-enablement
  writeConnectionSecretToRef:
    name: cloudrun-direct
    namespace: katee-engineering-enablement
```


## Deploy app


Create a manifest `app.yml` (change `project-id`):
```
apiVersion: core.oam.dev/v1beta1
kind: Application
metadata:
  name: my-cloud-run-test
spec:
  components:
    - name: cloud-run-app
      type: test-cloudrun-ee
      properties:
        project: "project-id"
        service_name: "jose-test"
        image_name: "gcr.io/cloudrun/hello"
        env:
           HELLO: "hola"
           BYE: "adios"
        writeConnectionSecretToRef:
          name: cloudrun-url
```

1. Deploy Application: `vela up -f app.yml`

2. Check the app and its status: `vela ls` and `vela status my-cloud-run-test`:
```
About:

  Name:      	my-cloud-run-test             
  Namespace: 	katee-engineering-enablement  
  Created at:	2022-06-03 10:33:03 +0200 CEST
  Status:    	running                       

Workflow:

  mode: DAG
  finished: true
  Suspend: true
  Terminated: false
  Steps
  - id:hn4wmei93j
    name:cloud-run-app
    type:apply-component
    phase:succeeded 
    message:

Services:

  - Name: cloud-run-app  
    Cluster: local  Namespace: katee-engineering-enablement
    Type: test-cloudrun-ee
    Healthy Cloud resources are deployed and ready to use
    No trait applied
```

3. Check outputs (secrets): `kubectl describe secret  cloudrun-url -n katee-engineering-enablement`:
```
Name:         cloudrun-url
Namespace:    katee-engineering-enablement
Labels:       terraform.core.oam.dev/created-by=terraform-controller
              terraform.core.oam.dev/owned-by=cloud-run-app
              terraform.core.oam.dev/owned-namespace=katee-engineering-enablement
Annotations:  <none>

Type:  Opaque

Data
====
sa_name:         63 bytes
sa_private_key:  3132 bytes
service_url:     41 bytes
```


