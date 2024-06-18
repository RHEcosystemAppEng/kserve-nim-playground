# Raw Deployment

```shell
# OPTIONAL: set your own namespace for testing
(cd pocs/deployment-types/raw && kustomize edit set namespace kserve-play-raw)
```

```shell
$ k apply -k pocs/deployment-types/raw

namespace/kserve-play-raw created
servingruntime.serving.kserve.io/kserve-sklearnserver created
inferenceservice.serving.kserve.io/sklearn-iris-raw created
```

```shell
$ k get all -n kserve-play-raw -o name

pod/sklearn-iris-raw-predictor-75587fd559-s52vn
service/sklearn-iris-raw-predictor
deployment.apps/sklearn-iris-raw-predictor
replicaset.apps/sklearn-iris-raw-predictor-75587fd559
horizontalpodautoscaler.autoscaling/sklearn-iris-raw-predictor
```

```shell
$ k get deployment -n kserve-play-raw sklearn-iris-raw-predictor  -o yaml | yq '.metadata.ownerReferences.0'

apiVersion: serving.kserve.io/v1beta1
blockOwnerDeletion: true
controller: true
kind: InferenceService
name: sklearn-iris-raw
uid: 2431c293-7b64-4d65-be26-15bcde9bad5c
```

```shell
$ k wait inferenceservices -n kserve-play-raw sklearn-iris-raw --for condition=Ready --timeout 200s

inferenceservice.serving.kserve.io/sklearn-iris-raw condition met
```

```shell
$ k port-forward -n kserve-play-raw services/sklearn-iris-raw-predictor 4321:80

# from a different terminal
$ curl -sk http://localhost:4321/v2/models/sklearn-iris-raw/ready | jq

{
  "name": "sklearn-iris-raw",
  "ready": true
}
```

```shell
# cleanup
$ k delete -k pocs/deployment-types/raw

namespace "kserve-play-raw" deleted
servingruntime.serving.kserve.io "kserve-sklearnserver" deleted
inferenceservice.serving.kserve.io "sklearn-iris-raw" deleted
```