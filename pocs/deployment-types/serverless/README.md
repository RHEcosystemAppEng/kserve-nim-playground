# Serverless Deployment

```shell
# OPTIONAL: set your own namespace for testing
(cd deployment-types/serverless && kustomize edit set namespace kserve-playground-serverless)
```

```shell
$ k apply -k deployment-types/serverless

namespace/kserve-playground-serverless created
servingruntime.serving.kserve.io/kserve-sklearnserver created
inferenceservice.serving.kserve.io/sklearn-iris-serverless created
```

```shell
$ k get all -n kserve-playground-serverless -o name

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
$ k get deployment -n kserve-playground-serverless sklearn-iris-serverless-predictor-00001-deployment  -o yaml | yq '.metadata.ownerReferences.0'

apiVersion: serving.knative.dev/v1
blockOwnerDeletion: true
controller: true
kind: Revision
name: sklearn-iris-serverless-predictor-00001
uid: 4492d7b0-a05f-4620-9cc5-c27ac66563a6
```

```shell
$ k wait inferenceservices -n kserve-playground-serverless sklearn-iris-serverless --for condition=Ready

inferenceservice.serving.kserve.io/sklearn-iris-serverless condition met
```

```shell
$ modelurl=$(k get inferenceservices -n kserve-playground-serverless sklearn-iris-serverless --no-headers | awk '{ print $2 }') && \
curl -sk $modelurl/v2/models/sklearn-iris-serverless/ready | jq

{
  "name": "sklearn-iris-serverless",
  "ready": true
}
```

```shell
# cleanup, might take a couple of minutes
$ k delete -k deployment-types/serverless

namespace/kserve-playground-serverless deleted
servingruntime.serving.kserve.io/kserve-sklearnserver deleted
inferenceservice.serving.kserve.io/sklearn-iris-serverless deleted
```
