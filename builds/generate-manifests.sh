#!/usr/bin/env bash

# Copyright (c) 2023 Red Hat, Inc.

###############################################################################################
###### Script for for creating manifest files from the kustomization builds.             ######
######                                                                                   ######
###### It requires yq and kustomize (and gsed for Mac users). It will not                ######
###### save namespaces for brevity.                                                      ######
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
  # split manifests file to multiple files by kind-name and current index (subtracting 1 because we delete namespaces so we're skipping 0)
  (cd "$temp" && yq -s '($index - 1) + "_" + .kind | downcase' kustomize_manifests.yaml)
  # remove namespaces, and original kustomize build
  find "$temp" \( -regex '.*namespace.*.yml' -o -regex '.*kustomize_manifests.yaml' \) -delete
  # mask secret values
  for manifest in $temp/*; do
    [[ "$manifest" == *"_secret"* ]] &&  yq -i '. |
      select(.data | has("NGC_API_KEY")) |= .data.NGC_API_KEY = "bas64-ngc-api-key-goes-here" |
      select(.data | has(".dockerconfigjson")) |= .data.".dockerconfigjson" = "base64-pull-config-for-nvcr.io-goes-here"
      ' "$manifest"
  done
done < <(find "$pocs_folder" -type d -print0)

# clean target build folder
rm -rf "${builds_folder:?}/"*/
# copy generated manifest files
cp -r "${temp_folder:?}/"* "$builds_folder"

# post-clean temp
rm -rf "$temp_folder"
