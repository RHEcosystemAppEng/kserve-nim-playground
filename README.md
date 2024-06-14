# NIM KServe Playground

This repository hosts example projects used for exploring [KServe][kserve] and [Nvidia NIM][nim]
with the goal of integrating [Nvidia NIM][nim] into [Red Hat OpenShift AI][aoi].

- The [pocs](pocs) folder hosts the various POC scenarios designed with [Kustomize][kustomize].
- The [builds](builds) folder hosts built manifests from the above-mentioned _pocs_ for accessibility.

> All POC executions require [Red Hat OpenShift AI][aoi].

## POCs

### Deployment Types

[Kserve][kserve] supports three types of deployment. We explored two of them. Serverless, and Raw.

#### Serverless Deployment

_Serverless Deployment_, the default deployment type for [Kserve][kserve], it leverages
[Knative][knative].

|                  |                                                  |
|------------------|--------------------------------------------------|
| Model Used       | _kserve-sklearnserver_                           |
| POC Instructions | [Click here](pocs/deployment-types/serverless)   |
| Built Manifests  | [Click here](builds/deployment-types/serverless) |

**Key Takeaways**

- The _storageUri_ specification from the _InferenceService_ is used for triggering _Kserve_'s
  _Storage Initializer Container_ for downloading the model prior to runtime.

#### Raw Deployment

With _Raw Deployment_, [Kserve][kserve] leverages _Kubernetes_ core resources.

|                  |                                           |
|------------------|-------------------------------------------|
| Model Used       | _kserve-sklearnserver_                    |
| POC Instructions | [Click here](pocs/deployment-types/raw)   |
| Built Manifests  | [Click here](builds/deployment-types/raw) |

**Key Takeaways**

- The _storageUri_ specification from the _InferenceService_ is used for triggering _Kserve_'s
  _Storage Initializer Container_ for downloading the model prior to runtime.
- Annotating the _InferenceService_ with `serving.kserve.io/deploymentMode: RawDeployment` triggers
  a _Raw Deployment_.

### Persistence and Caching

<details>
<summary><strong>Prerequisites!</strong></summary>

Before proceeding, grab your _NGC API Key_ and create the following two secret data files (git-ignored):

> The files are saved in the _no-cache_ POC folder but are used by all scenarios in this context.

```shell
# the following will be used in an opaque secret mounted into the runtime
echo "NGC_API_KEY=ngcapikeygoeshere" > pocs/persistence-and-caching/no-cache/ngc.env
```

```shell
# the following will be used as the pull image secret for the underlying runtime deployment
echo "{
  \"auths\": {
    \"nvcr.io\": {
      \"username\": \"\$oauthtoken\",
      \"password\": \"ngcapikeygoeshere\"
    }
  }
}" > pocs/persistence-and-caching/no-cache/ngcdockerconfig.json
```

</details>

#### No caching or Persistence

In this scenario, [Nvidia NIM][nim] is in charge of downloading the required models; however, the
target volume is not persistent, and the download process will occur for every Pod created and will
be reflected in scaling time.

|                  |                                                       |
|------------------|-------------------------------------------------------|
| Model Used       | _nvidia-nim-llama3-8b-instruct_                       |
| POC Instructions | [Click here](pocs/persistence-and-caching/no-cache)   |
| Built Manifests  | [Click here](builds/persistence-and-caching/no-cache) |

**Key Takeaways**

- The _storageUri_ specification from the _InferenceService_ is NOT required.
- We set the _NIM_CACHE_PATH_ environment variable is set to _/mnt/models_ ([empty-dir][emptydir]).

#### Knative PVC Feature

In this scenario, [Nvidia NIM][nim] is in charge of downloading the required models; the download
target is a PVC. Using writable PVCs with [Knative][knative] requires manual enablement of the
[PCV support feature][knative-pvc]. Look for the _ConfigMap_ named _config-features_ in the
_knative-serving_ namespace and enable the following flags:

```yaml
kubernetes.podspec-persistent-volume-claim: "enabled"
kubernetes.podspec-persistent-volume-write: "enabled"
```

|                  |                                                          |
|------------------|----------------------------------------------------------|
| Model Used       | _nvidia-nim-llama3-8b-instruct_                          |
| POC Instructions | [Click here](pocs/persistence-and-caching/knative-pvc)   |
| Built Manifests  | [Click here](builds/persistence-and-caching/knative-pvc) |

**Key Takeaways**

- The _storageUri_ specification from the _InferenceService_ is NOT required.
- We added a _PVC_ setting the storage class to OpenShift's default _gp3-csi_.
- We added a _Volume_ to the _ServingRuntime_ connected to the above-mentioned _PVC_.
- We added a _VolumeMount_ to the _ServingRuntime_ mounting the above-mentioned _Volume_ to
  _/mnt/nim/models_.
- We set the _NIM_CACHE_PATH_ environment variable is set to above-mentioned _/mnt/nim/models_.

[aoi]: https://www.redhat.com/en/technologies/cloud-computing/openshift/openshift-ai
[emptydir]: https://kubernetes.io/docs/concepts/storage/volumes/#emptydir
[knative]: https://knative.dev/docs/
[knative-pvc]: https://knative.dev/docs/serving/configuration/feature-flags/#kubernetes-persistentvolumeclaim-pvc
[kserve]: https://kserve.github.io/website/latest/
[kustomize]: https://kustomize.io/
[nim]: https://www.nvidia.com/en-us/ai/
