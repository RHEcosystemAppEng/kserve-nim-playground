# Raw Deployment

```shell
# OPTIONAL: set your own namespace for testing
(cd deployment-types/raw && kustomize edit set namespace kserve-playground-raw)
```

```shell
$ k apply -k deployment-types/raw

namespace/kserve-playground-raw created
servingruntime.serving.kserve.io/kserve-sklearnserver created
inferenceservice.serving.kserve.io/sklearn-iris-raw created
```

```shell
$ k get all -n kserve-playground-raw -o name

pod/sklearn-iris-raw-predictor-7fff956f8b-mf7m2
service/sklearn-iris-raw-metrics
service/sklearn-iris-raw-predictor
deployment.apps/sklearn-iris-raw-predictor
replicaset.apps/sklearn-iris-raw-predictor-7fff956f8b
horizontalpodautoscaler.autoscaling/sklearn-iris-raw-predictor
```

```shell
$ k get deployment -n kserve-playground-raw sklearn-iris-raw-predictor  -o yaml | yq '.metadata.ownerReferences.0'

apiVersion: serving.kserve.io/v1beta1
blockOwnerDeletion: true
controller: true
kind: InferenceService
name: sklearn-iris-raw
uid: 20f09438-638b-445e-ad1f-3ebd7df458f2
```

```shell
$ k wait inferenceservices -n kserve-playground-raw sklearn-iris-raw --for condition=Ready

inferenceservice.serving.kserve.io/sklearn-iris-raw condition met
```

```shell
$ k port-forward -n kserve-playground-raw services/sklearn-iris-raw-predictor 4321:80

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

namespace/kserve-playground-raw deleted
servingruntime.serving.kserve.io/kserve-sklearnserver deleted
inferenceservice.serving.kserve.io/sklearn-iris-raw deleted
```