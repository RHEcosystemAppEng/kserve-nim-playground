#!/bin/bash

# Copyright (c) 2023 Red Hat, Inc.

###########################################################################
###### Script for downloading NGC models and building OCI images for ######
###### use with Kserve's ModelCar feature                            ######
######                                                               ######
###### TODO                                                          ######
###########################################################################

# iterate over arguments and create named parameters
while [ $# -gt 0 ]; do
	if [[ $1 == *"--"* ]]; then
		param="${1/--/}"
		if [ "$param" = "push" ]; then
		  declare "$param"=true
		else
		  declare "$param"="$2"
		fi
	fi
	shift
done

# optional named parameters default values
registry=${registry:-quay.io}
owner=${owner:-ecosystem-appeng}
tag=${tag:-dev}
push=${push:-false}
dir=${dir:=models}

# required named parameters
[[ -z $model ]] && echo "please use --model to set the model name" && exit 1

[[ ! -d "$dir" ]] &&

podman build --tag "$registry/${owner}/$model:$tag" ./pocs/disconnected-environments --build-arg MODEL_NAME="$model" --build-arg MODELS_DIR="$dir"
[[ "$push" = true ]] && podman push "$registry/${owner}/$model:$tag"
