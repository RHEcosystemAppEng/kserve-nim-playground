# Persistence and Caching

## Prerequisites

Before proceeding, grab your _NGC Token Key_ and _HF Token_, and create the following two secret
data files (git-ignored):

> The files are saved in the _no-cache_ scenario folder but are used by all scenarios in this context.

```shell
# the following will be used in an opaque secret mounted into the runtime
echo "HF_TOKEN=secrethftokengoeshere
NGC_API_KEY=ngcapikeygoeshere" > persistence-and-caching/no-cache/ngc.env
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
}" > persistence-and-caching/no-cache/ngcdockerconfig.json
```

## No caching or Persistence

In this scenario, Nvidia is in charge of downloading the required models; however, the target volume
is not persistent, and the download process will occur for every Pod created and will be reflected
in scaling time.

```shell
# set your namespace for testing
(cd persistence-and-caching/no-cache && kustomize edit set namespace tomer-playground-no-cache)
```

```shell
# apply the required resources
$ k apply -k persistence-and-caching/no-cache

namespace/tomer-playground-no-cache created
secret/ngc-secret created
secret/nvidia-nim-secrets created
servingruntime.serving.kserve.io/nvidia-nim-llama3-8b-instruct-1.0.0 created
inferenceservice.serving.kserve.io/llama3-8b-instruct-1xgpu created
```

```shell
# wait for the service to be ready; this might take a couple of minutes
$ k wait inferenceservices -n tomer-playground-no-cache llama3-8b-instruct-1xgpu --for condition=Ready --timeout 200s

inferenceservice.serving.kserve.io/llama3-8b-instruct-1xgpu condition met
```

```shell
# check the download time; don't forget to use the correct pod name from your environment
$ pod=llama3-8b-instruct-1xgpu-predictor-00001-deployment-548c9b6wxsm && \
k logs -n tomer-playground-no-cache $pod kserve-container | grep 'Model workspace is now ready'

INFO 06-11 21:19:19.301 ngc_injector.py:172] Model workspace is now ready. It took 70.649 seconds
```

```shell
# test using NIM API to get a list of the existing models and their attributes
$ runtimeurl=$(k get inferenceservices -n tomer-playground-no-cache llama3-8b-instruct-1xgpu -o yaml | yq '.status.url') && \
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
$ runtimeurl=$(k get inferenceservices -n tomer-playground-no-cache llama3-8b-instruct-1xgpu -o yaml | yq '.status.url') && \
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
$ k get kpa -n tomer-playground-no-cache llama3-8b-instruct-1xgpu-predictor-00001 -o yaml | yq '.status' | yq '. |= pick(["actualScale", "desiredScale"])'

actualScale: 1
desiredScale: 1
```

```shell
# trigger a scale-up of the pods by sending multiple interaction requests simultaneously
runtimeurl=$(k get inferenceservices -n tomer-playground-no-cache llama3-8b-instruct-1xgpu -o yaml | yq '.status.url') && \
for i in {1..15}; do curl -sk $runtimeurl/v1/chat/completions -H "Content-Type: application/json" -d \
'{
  "model": "meta/llama3-8b-instruct",
  "messages": [{"role":"user","content":"What is Red Hat OpenShift AI?"}],
  "temperature": 0.5,
  "top_p": 1,
  "max_tokens": 1024,
  "stream": false
}' 2&>1 > /dev/null &; done
```

```shell
# verify a second replica is requested by the KNative
$ k get kpa -n tomer-playground-no-cache llama3-8b-instruct-1xgpu-predictor-00001 -o yaml | yq '.status' | yq '. |= pick(["actualScale", "desiredScale"])'

actualScale: 1
desiredScale: 2
```

> Note the time it took to download the model, even though it was already downloaded for the previous Pod.

```shell
# check the download time in the SECOND pod; don't forget to use the correct pod name from your environment
$ pod=llama3-8b-instruct-1xgpu-predictor-00001-deployment-548c9bgwvzp && \
k logs -n tomer-playground-no-cache $pod kserve-container | grep 'Model workspace is now ready'

INFO 06-11 21:53:02.842 ngc_injector.py:172] Model workspace is now ready. It took 61.800 seconds
```

```shell
# cleanup
$ k delete -k persistence-and-caching/no-cache

namespace "tomer-playground-no-cache" deleted
secret "ngc-secret" deleted
secret "nvidia-nim-secrets" deleted
servingruntime.serving.kserve.io "nvidia-nim-llama3-8b-instruct-1.0.0" deleted
inferenceservice.serving.kserve.io "llama3-8b-instruct-1xgpu" deleted
```