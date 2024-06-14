#!/usr/bin/env bash

# Copyright (c) 2023 Red Hat, Inc.

###############################################################################################
###### Script for for creating manifest files from the kustomization builds.             ######
######                                                                                   ######
###### It requires yq and kustomize (and gsed for Mac users). It will not                ######
###### save secrets or namespaces for privacy and brevity.                               ######
###### Run this script from the project's root, or use --pocs_folder and --builds_folder ######
###### for tweaking the working path.                                                    ######
###############################################################################################

# iterate over arguments and create named parameters
while [ $# -gt 0 ]; do
	if [[ $1 == *"--"* ]]; then
		param="${1/--/}"
		declare "$param"="$2"
	fi
	shift
done

# optional named parameters default values
temp_folder=${temp_folder:-temp}
pocs_folder=${pocs_folder:-pocs}
builds_folder=${builds_folder:-builds}

# set sed
[[ $OSTYPE == "darwin"* ]] && sed="gsed" || sed="sed"

# pre-clean temp
rm -rf "$temp_folder"

# iterate over all subfolders of the pocs folder and build the kustomize manifests in the temp folder
while IFS= read -r -d '' poc
do
  # skip root pocs folder
  [[ "$poc" == "$pocs_folder" ]] && continue
  # verify kustomization exist
  [[ -f "$poc"/kustomization.yaml ]] || continue

  # set target temp folder
  temp=$(echo "$poc" | "$sed" -e s/"$pocs_folder"/"$temp_folder"/)
  # create temp folder
  mkdir -p "$temp"
  # build kustomize manifests into temp folder
  kustomize build "$poc" > "$temp"/kustomize_manifests.yaml
  # split manifests file to multiple files by kind-name (concatenate name if expects more than one of the same kind)
  (cd "$temp" && yq -s '.kind | downcase' kustomize_manifests.yaml)
  # remove secret files, namespaces, and original kustomize build
  find "$temp" \( -regex '.*/secret.*.yml' -o -regex '.*/namespace.*.yml' -o -regex '.*kustomize_manifests.yaml' \) -delete
done < <(find "$pocs_folder" -type d -print0)

# clean target build folder
rm -rf "${builds_folder:?}/"*/
# copy generated manifest files
cp -r "${temp_folder:?}/"* "$builds_folder"

# post-clean temp
rm -rf "$temp_folder"
