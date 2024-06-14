# No caching or Persistence

```shell
# OPTIONAL: set your namespace for testing
(cd persistence-and-caching/no-cache && kustomize edit set namespace kserve-nim-playground-no-cache)
```

```shell
# apply the required resources
$ k apply -k persistence-and-caching/no-cache

namespace/kserve-nim-playground-no-cache created
secret/ngc-secret created
secret/nvidia-nim-secrets created
servingruntime.serving.kserve.io/nvidia-nim-llama3-8b-instruct-1.0.0 created
inferenceservice.serving.kserve.io/llama3-8b-instruct-1xgpu created
```

```shell
# wait for the service to be ready; this might take a couple of minutes
$ k wait inferenceservices -n kserve-nim-playground-no-cache llama3-8b-instruct-1xgpu --for condition=Ready --timeout 200s

inferenceservice.serving.kserve.io/llama3-8b-instruct-1xgpu condition met
```

```shell
# grab the name of the pod created
$ k get pods -n kserve-nim-playground-no-cache

NAME                                                              READY   STATUS    RESTARTS   AGE
llama3-8b-instruct-1xgpu-predictor-00001-deployment-548c9b6wxsm   3/3     Running   0          4m17s
```

```shell
# check the download time; don't forget to use the correct pod name from your environment
$ pod=llama3-8b-instruct-1xgpu-predictor-00001-deployment-548c9b6wxsm && \
k logs -n kserve-nim-playground-no-cache $pod kserve-container | grep 'Model workspace is now ready'

INFO 06-11 21:19:19.301 ngc_injector.py:172] Model workspace is now ready. It took 70.649 seconds
```

```shell
# test using NIM API to get a list of the existing models and their attributes
$ runtimeurl=$(k get inferenceservices -n kserve-nim-playground-no-cache llama3-8b-instruct-1xgpu -o yaml | yq '.status.url') && \
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
$ runtimeurl=$(k get inferenceservices -n kserve-nim-playground-no-cache llama3-8b-instruct-1xgpu -o yaml | yq '.status.url') && \
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
# verify only one replica is scheduled currently
$ k get kpa -n kserve-nim-playground-no-cache llama3-8b-instruct-1xgpu-predictor-00001 -o yaml | yq '.status' | yq '. |= pick(["actualScale", "desiredScale"])'

actualScale: 1
desiredScale: 1
```

```shell
# trigger a scale-up of the pods by sending multiple interaction requests simultaneously
runtimeurl=$(k get inferenceservices -n kserve-nim-playground-no-cache llama3-8b-instruct-1xgpu -o yaml | yq '.status.url') && \
for i in {1..15}; do curl -sk $runtimeurl/v1/chat/completions -H "Content-Type: application/json" -d \
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
# verify a second replica is requested by the KNative
$ k get kpa -n kserve-nim-playground-no-cache llama3-8b-instruct-1xgpu-predictor-00001 -o yaml | yq '.status' | yq '. |= pick(["actualScale", "desiredScale"])'

actualScale: 1
desiredScale: 2
```

```shell
# grab the name of the new pod created based on the age
$ k get pods -n kserve-nim-playground-no-cache

NAME                                                              READY   STATUS    RESTARTS   AGE
llama3-8b-instruct-1xgpu-predictor-00001-deployment-548c9bgwvzp   2/3     Running   0          15s
llama3-8b-instruct-1xgpu-predictor-00001-deployment-548c9b6wxsm   3/3     Running   0          9m37s
```

```shell
# check the download time in the SECOND pod; don't forget to use the correct pod name from your environment
# this might take a couple of minutes for that log line to be found, depending on the download time
$ pod=llama3-8b-instruct-1xgpu-predictor-00001-deployment-548c9bgwvzp && \
k logs -n kserve-nim-playground-no-cache $pod kserve-container | grep 'Model workspace is now ready'

INFO 06-11 21:53:02.842 ngc_injector.py:172] Model workspace is now ready. It took 61.800 seconds
```

> Note the time it took to prepare the model, 61.800 seconds.

```shell
# cleanup - this might take a couple of minutes
$ k delete -k persistence-and-caching/no-cache

namespace "kserve-nim-playground-no-cache" deleted
secret "ngc-secret" deleted
secret "nvidia-nim-secrets" deleted
servingruntime.serving.kserve.io "nvidia-nim-llama3-8b-instruct-1.0.0" deleted
inferenceservice.serving.kserve.io "llama3-8b-instruct-1xgpu" deleted
```
