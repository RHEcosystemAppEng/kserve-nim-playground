# Compare KServe Deployment Types

- [Serverless](#serverless)
- [Raw](#raw)

## Serverless

```shell
# set your own namespace for testing
(cd deployment-types/serverless && kustomize edit set namespace tomer-playground-serverless)
```

```shell
$ k apply -k deployment-types/serverless

namespace/tomer-playground-serverless created
servingruntime.serving.kserve.io/kserve-sklearnserver created
inferenceservice.serving.kserve.io/sklearn-iris-serverless created
```

```shell
$ k get all -n tomer-playground-serverless -o name

pod/sklearn-iris-serverless-predictor-00001-deployment-b4f977d4b9sp
service/sklearn-iris-serverless-predictor-00001
service/sklearn-iris-serverless-predictor-00001-private
deployment.apps/sklearn-iris-serverless-predictor-00001-deployment
replicaset.apps/sklearn-iris-serverless-predictor-00001-deployment-b4f977d77
revision.serving.knative.dev/sklearn-iris-serverless-predictor-00001
route.serving.knative.dev/sklearn-iris-serverless-predictor
service.serving.knative.dev/sklearn-iris-serverless-predictor
configuration.serving.knative.dev/sklearn-iris-serverless-predictor

```

```shell
$ k get deployment -n tomer-playground-serverless sklearn-iris-serverless-predictor-00001-deployment  -o yaml | yq '.metadata.ownerReferences.0'

apiVersion: serving.knative.dev/v1
blockOwnerDeletion: true
controller: true
kind: Revision
name: sklearn-iris-serverless-predictor-00001
uid: 4492d7b0-a05f-4620-9cc5-c27ac66563a6
```

```shell
$ k wait inferenceservices -n tomer-playground-serverless sklearn-iris-serverless --for condition=Ready

inferenceservice.serving.kserve.io/sklearn-iris-serverless condition met
```

```shell
$ modelurl=$(k get inferenceservices -n tomer-playground-serverless sklearn-iris-serverless --no-headers | awk '{ print $2 }') && \
curl -sk $modelurl/v2/models/sklearn-iris-serverless/ready | jq

{
  "name": "sklearn-iris-serverless",
  "ready": true
}
```

```shell
# cleanup
$ k delete -k deployment-types/serverless

namespace/tomer-playground-serverless deleted
servingruntime.serving.kserve.io/kserve-sklearnserver deleted
inferenceservice.serving.kserve.io/sklearn-iris-serverless deleted
```

## Raw

```shell
# set your own namespace for testing
(cd deployment-types/raw && kustomize edit set namespace tomer-playground-raw)
```

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
$ k wait inferenceservices -n tomer-playground-raw sklearn-iris-raw --for condition=Ready

inferenceservice.serving.kserve.io/sklearn-iris-raw condition met
```


```shell
$ k port-forward -n tomer-playground-raw services/sklearn-iris-raw-predictor 4321:80

# from a different terminal
$ curl -sk http://localhost:4321/v2/models/sklearn-iris-raw/ready | jq

{
  "name": "sklearn-iris-raw",
  "ready": true
}
```

```shell
# cleanup
$ k delete -k deployment-types/raw

namespace/tomer-playground-raw deleted
servingruntime.serving.kserve.io/kserve-sklearnserver deleted
inferenceservice.serving.kserve.io/sklearn-iris-raw deleted
```