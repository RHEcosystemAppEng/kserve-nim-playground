# Raw PVC Feature Knative Passthrough

```shell
# OPTIONAL: set your namespace for testing
(cd pocs/persistence-and-caching/raw-pvc && kustomize edit set namespace knim-raw-pvc)
```

```shell
# apply the required resources
$ k apply -k pocs/persistence-and-caching/raw-pvc

namespace/knim-raw-pvc created
secret/ngc-secret created
secret/nvidia-nim-secrets created
persistentvolumeclaim/nim-pvc created
servingruntime.serving.kserve.io/nvidia-nim-llama3-8b-instruct-1.0.0 created
inferenceservice.serving.kserve.io/llama3-8b-instruct-1xgpu created
```

```shell
# wait for the service to be ready; this might take a couple of minutes
$ k wait inferenceservices -n knim-raw-pvc llama3-8b-instruct-1xgpu --for condition=Ready --timeout 300s

inferenceservice.serving.kserve.io/llama3-8b-instruct-1xgpu condition met
```

```shell
# list all components
$ k get all -n knim-raw-pvc -o name

pod/llama3-8b-instruct-1xgpu-predictor-5bd786f77d-bljj2
service/llama3-8b-instruct-1xgpu-predictor
deployment.apps/llama3-8b-instruct-1xgpu-predictor
replicaset.apps/llama3-8b-instruct-1xgpu-predictor-5bd786f77d
horizontalpodautoscaler.autoscaling/llama3-8b-instruct-1xgpu-predictor
```

```shell
# grab the name of the pod created
$ k get pods -n knim-raw-pvc

NAME                                                  READY   STATUS    RESTARTS   AGE
llama3-8b-instruct-1xgpu-predictor-5bd786f77d-bljj2   2/2     Running   0          9m17s
```

```shell
# check the download time; don't forget to use the correct pod name from your environment
$ pod=llama3-8b-instruct-1xgpu-predictor-5bd786f77d-29nbg && \
k logs -n knim-raw-pvc $pod kserve-container | grep 'Model workspace is now ready'

INFO 07-24 20:42:13.878 ngc_injector.py:172] Model workspace is now ready. It took 70.084 seconds
```

**Note: Currently, an OpenShift Route is not created by Kserve in Raw deployment mode. This should
be fixed in time for the integration. For the POC, we create the Route manually.**

```shell
# create an openshift route
$ oc expose service -n knim-raw-pvc llama3-8b-instruct-1xgpu-predictor

route/llama3-8b-instruct-1xgpu-predictor exposed
```

```shell
# test using NIM API to get a list of the existing models and their attributes
$ runtimeurl=$(k get route -n knim-raw-pvc llama3-8b-instruct-1xgpu-predictor -o yaml | yq '.spec.host') && \
curl -sk $runtimeurl/v1/models | jq

{
  "object": "list",
  "data": [
    {
      "id": "meta/llama3-8b-instruct",
      "object": "model",
      ...
      "permission": [
        {
         ...
        }
      ]
    }
  ]
}
```

```shell
# test using NIM API to interact with the underlying model
$ runtimeurl=$(k get route -n knim-raw-pvc llama3-8b-instruct-1xgpu-predictor -o yaml | yq '.spec.host') && \
curl -sk $runtimeurl/v1/chat/completions -H "Content-Type: application/json" -d \
'{
  "model": "meta/llama3-8b-instruct",
  "messages": [{"role":"user","content":"What is Red Hat OpenShift AI?"}],
  "temperature": 0.5,
  "top_p": 1,
  "max_tokens": 1024,
  "stream": false
}' | jq

{
  ...
  "model": "meta/llama3-8b-instruct",
  "choices": [
    {
      "index": 0,
      "message": {
        "role": "assistant",
        "content": "Red Hat OpenShift AI is a cloud-native, containerized platform designed to simplify the deployment, management, and scaling of artificial intelligence (AI) and machine learning (ML) workloads..."
      },
      ...
    }
  ],
  "usage": {
    ...
  }
}
```

```shell
# verify only one replica is scheduled currently (this might take a minute or two to get right)
$ k get hpa -n knim-raw-pvc llama3-8b-instruct-1xgpu-predictor -o yaml | yq '.status' | yq '. |= pick(["currentReplicas", "desiredReplicas"])'

currentReplicas: 1
desiredReplicas: 1
```

**Before continuing further, you should know that for this demo, we configured the HPA for
`scaleMetric=cpu` and `scaleTarget=1` to make it scale up for 1% utilization of the CPU.<br/>
Check [kustomization.yaml](kustomization.yaml).**

```shell
# trigger a scale-up of the pods by sending multiple interaction requests simultaneously
$ runtimeurl=$(k get route -n knim-raw-pvc llama3-8b-instruct-1xgpu-predictor -o yaml | yq '.spec.host') && \
for i in {1..80}; do curl -sk $runtimeurl/v1/chat/completions -H "Content-Type: application/json" -d \
'{
  "model": "meta/llama3-8b-instruct",
  "messages": [{"role":"user","content":"What is Red Hat OpenShift AI?"}],
  "temperature": 0.5,
  "top_p": 1,
  "max_tokens": 1024,
  "stream": false
}' 2>&1 > /dev/null &; done
```

```shell
# wait a minute or so and verify a second replica is requested by the HPA
$ k get hpa -n knim-raw-pvc llama3-8b-instruct-1xgpu-predictor -o yaml | yq '.status' | yq '. |= pick(["currentReplicas", "desiredReplicas"])'

currentReplicas: 1
desiredReplicas: 3
```

```shell
# grab the name of the new pod created based on the age
$ k get pods -n knim-raw-pvc

NAME                                                  READY   STATUS    RESTARTS   AGE
llama3-8b-instruct-1xgpu-predictor-5bd786f77d-2cr4m   0/2     Running   0          9s
llama3-8b-instruct-1xgpu-predictor-5bd786f77d-bljj2   2/2     Running   0          11m
llama3-8b-instruct-1xgpu-predictor-5bd786f77d-mbqqc   2/2     Running   0          39s
```

```shell
# you can verify the hpa once all the pods are alive and ready
$ k get hpa -n knim-raw-pvc llama3-8b-instruct-1xgpu-predictor -o yaml | yq '.status' | yq '. |= pick(["currentReplicas", "desiredReplicas"])'

currentReplicas: 3
desiredReplicas: 3
```

```shell
# check the download time in the SECOND pod; don't forget to use the correct pod name from your environment
$ pod=llama3-8b-instruct-1xgpu-predictor-5bd786f77d-2cr4m && \
k logs -n knim-raw-pvc $pod kserve-container | grep 'Model workspace is now ready'

INFO 07-24 20:53:02.445 ngc_injector.py:172] Model workspace is now ready. It took 2.383 seconds
```
> Note the time it took to prepare the model, only 2.383 seconds.

```shell
# cleanup - this might take a couple of minutes
$ k delete -k pocs/persistence-and-caching/raw-pvc

namespace "knim-raw-pvc" deleted
secret "ngc-secret" deleted
secret "nvidia-nim-secrets" deleted
persistentvolumeclaim "nim-pvc" deleted
servingruntime.serving.kserve.io "nvidia-nim-llama3-8b-instruct-1.0.0" deleted
inferenceservice.serving.kserve.io "llama3-8b-instruct-1xgpu" deleted
```