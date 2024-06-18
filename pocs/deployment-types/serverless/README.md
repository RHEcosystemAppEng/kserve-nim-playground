# Serverless Deployment

```shell
# OPTIONAL: set your own namespace for testing
(cd pocs/deployment-types/serverless && kustomize edit set namespace kserve-play-serverless)
```

```shell
$ k apply -k pocs/deployment-types/serverless

namespace/kserve-play-serverless created
servingruntime.serving.kserve.io/kserve-sklearnserver created
inferenceservice.serving.kserve.io/sklearn-iris-serverless created
```

```shell
$ k get all -n kserve-play-serverless -o name

pod/sklearn-iris-serverless-predictor-00001-deployment-556697f99fhm
service/sklearn-iris-serverless-metrics
service/sklearn-iris-serverless-predictor-00001
service/sklearn-iris-serverless-predictor-00001-private
deployment.apps/sklearn-iris-serverless-predictor-00001-deployment
replicaset.apps/sklearn-iris-serverless-predictor-00001-deployment-556697f75
service.serving.knative.dev/sklearn-iris-serverless-predictor
route.serving.knative.dev/sklearn-iris-serverless-predictor
revision.serving.knative.dev/sklearn-iris-serverless-predictor-00001
configuration.serving.knative.dev/sklearn-iris-serverless-predictor
```

```shell
$ k get deployment -n kserve-play-serverless sklearn-iris-serverless-predictor-00001-deployment  -o yaml | yq '.metadata.ownerReferences.0'

apiVersion: serving.knative.dev/v1
blockOwnerDeletion: true
controller: true
kind: Revision
name: sklearn-iris-serverless-predictor-00001
uid: 13da2ae0-5c60-4a2f-b82b-fae26a820875
```

```shell
$ k wait inferenceservices -n kserve-play-serverless sklearn-iris-serverless --for condition=Ready --timeout 200s

inferenceservice.serving.kserve.io/sklearn-iris-serverless condition met
```

```shell
$ modelurl=$(k get inferenceservices -n kserve-play-serverless sklearn-iris-serverless --no-headers | awk '{ print $2 }') && \
curl -sk $modelurl/v2/models/sklearn-iris-serverless/ready | jq

{
  "name": "sklearn-iris-serverless",
  "ready": true
}
```

```shell
# cleanup, might take a couple of minutes
$ k delete -k pocs/deployment-types/serverless

namespace/kserve-play-serverless deleted
servingruntime.serving.kserve.io/kserve-sklearnserver deleted
inferenceservice.serving.kserve.io/sklearn-iris-serverless deleted
```
