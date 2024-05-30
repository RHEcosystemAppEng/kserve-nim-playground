# Compare KServe Deployment Types

- [Knative](#knative)
- [Raw](#raw)

## KNative

```shell
$ k apply -k deployment-types/knative

namespace/tomer-playground-knative created
servingruntime.serving.kserve.io/kserve-sklearnserver created
inferenceservice.serving.kserve.io/sklearn-iris-knative created
```

```shell
$ k get all -n tomer-playground-knative -o name

pod/sklearn-iris-knative-predictor-00001-deployment-7c5664cc85x4gkb
service/sklearn-iris-knative
service/sklearn-iris-knative-metrics
service/sklearn-iris-knative-predictor
service/sklearn-iris-knative-predictor-00001
service/sklearn-iris-knative-predictor-00001-private
deployment.apps/sklearn-iris-knative-predictor-00001-deployment
replicaset.apps/sklearn-iris-knative-predictor-00001-deployment-7c5664cc85
service.serving.knative.dev/sklearn-iris-knative-predictor
route.serving.knative.dev/sklearn-iris-knative-predictor
configuration.serving.knative.dev/sklearn-iris-knative-predictor
revision.serving.knative.dev/sklearn-iris-knative-predictor-00001
```

```shell
$ k get deployment -n tomer-playground-knative sklearn-iris-knative-predictor-00001-deployment  -o yaml | yq '.metadata.ownerReferences.0'

apiVersion: serving.knative.dev/v1
blockOwnerDeletion: true
controller: true
kind: Revision
name: sklearn-iris-knative-predictor-00001
uid: 6c17378b-e0c6-4e8b-8afb-f0c37b23bd14
```

```shell
$ modelurl=$(k get inferenceservices -n tomer-playground-knative sklearn-iris-knative --no-headers | awk '{ print $2 }') && \
curl -sk $modelurl/v2/models/sklearn-iris-knative/ready | jq

{
  "name": "sklearn-iris-knative",
  "ready": true
}
```

## Raw

```shell
$ k apply -k deployment-types/raw

namespace/tomer-playground-raw created
servingruntime.serving.kserve.io/kserve-sklearnserver created
inferenceservice.serving.kserve.io/sklearn-iris-raw created
```

```shell
$ k get all -n tomer-playground-raw -o name

pod/sklearn-iris-raw-predictor-7fff956f8b-mf7m2
service/sklearn-iris-raw-metrics
service/sklearn-iris-raw-predictor
deployment.apps/sklearn-iris-raw-predictor
replicaset.apps/sklearn-iris-raw-predictor-7fff956f8b
horizontalpodautoscaler.autoscaling/sklearn-iris-raw-predictor
```

```shell
$ k get deployment -n tomer-playground-raw sklearn-iris-raw-predictor  -o yaml | yq '.metadata.ownerReferences.0'

apiVersion: serving.kserve.io/v1beta1
blockOwnerDeletion: true
controller: true
kind: InferenceService
name: sklearn-iris-raw
uid: 20f09438-638b-445e-ad1f-3ebd7df458f2
```

```shell
# from a different terminal
$ k port-forward -n tomer-playground-raw services/sklearn-iris-raw-predictor 4321:80

# from current terminal
$ curl -sk http://localhost/v2/models/sklearn-iris-raw/ready | jq

{
  "name": "sklearn-iris-raw",
  "ready": true
}
```