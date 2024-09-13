```shell
ngc registry model download-version --dest pocs/disconnected-environments/models  nim/meta/llama3-8b-instruct:hf

ngc registry model download-version  --dest pocs/disconnected-environments/models nvidia/llama/mistral-7b-int4-chat:1.2
```

```shell
k apply -k pocs/disconnected-environments/manifests/
```


```shell
# wait for the service to be ready; this might take a couple of minutes
$ k wait inferenceservices -n nim-raw-modelcar llama3-8b-instruct-1xgpu --for condition=Ready --timeout 300s

inferenceservice.serving.kserve.io/llama3-8b-instruct-1xgpu condition met
```

```shell
# list all components
$ k get all -n nim-raw-modelcar -o name

pod/llama3-8b-instruct-1xgpu-predictor-5bd786f77d-bljj2
service/llama3-8b-instruct-1xgpu-predictor
deployment.apps/llama3-8b-instruct-1xgpu-predictor
replicaset.apps/llama3-8b-instruct-1xgpu-predictor-5bd786f77d
horizontalpodautoscaler.autoscaling/llama3-8b-instruct-1xgpu-predictor
```

```shell
# grab the name of the pod created
$ k get pods -n nim-raw-modelcar

NAME                                                 READY   STATUS    RESTARTS   AGE
llama3-8b-instruct-1xgpu-predictor-95f68b6b7-m6rdw   2/2     Running   0          2m37s
```

```shell
# no workspace preparation required
$ pod=llama3-8b-instruct-1xgpu-predictor-554cff7d5d-9n5wr  && \
k logs -n nim-raw-modelcar $pod kserve-container | grep 'Model workspace is now ready'
```

**Note: Currently, an OpenShift Route is not created by Kserve in Raw deployment mode. This should
be fixed in time for the integration. For the POC, we create the Route manually.**

```shell
# create an openshift route
$ oc expose service -n nim-raw-modelcar llama3-8b-instruct-1xgpu-predictor

route/llama3-8b-instruct-1xgpu-predictor exposed
```

```shell
# test using NIM API to get a list of the existing models and their attributes
$ runtimeurl=$(k get route -n nim-raw-modelcar llama3-8b-instruct-1xgpu-predictor -o yaml | yq '.spec.host') && \
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
$ runtimeurl=$(k get route -n nim-raw-modelcar llama3-8b-instruct-1xgpu-predictor -o yaml | yq '.spec.host') && \
curl -sk $runtimeurl/v1/chat/completions -H "Content-Type: application/json" -d \
'{
  "model": "/mnt/models",
  "messages": [{"role":"user","content":"What is Red Hat OpenShift AI?"}],
  "temperature": 0.5,
  "top_p": 1,
  "max_tokens": 1024,
  "stream": false
}' | jq

{
  ...
  "model": "/mnt/models",
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
$ k get hpa -n nim-raw-modelcar llama3-8b-instruct-1xgpu-predictor -o yaml | yq '.status' | yq '. |= pick(["currentReplicas", "desiredReplicas"])'

currentReplicas: 1
desiredReplicas: 1
```
