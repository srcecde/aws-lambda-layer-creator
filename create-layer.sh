#!/bin/sh

set -e

layername="$1"
runtime="$2"
packages="${@:3}"

echo "================================="

echo "LayerName: $layername"

support_python_runtime=("python3.6,python3.7,python3.8,python3.9")

if [[ "${support_python_runtime[*]}" =~ "${runtime}" ]]; then
	echo "Runtime: $runtime"
else
	echo "Invalid runtime"
	exit 1
fi

echo "Packages: $packages"

echo "================================="

host_temp_dir="$(mktemp -d)"

installation_path="python"
docker_image="public.ecr.aws/sam/build-$runtime:latest"

echo "Preparing lambda layer"
docker run --rm -v "$host_temp_dir:/lambda-layer" -w "/lambda-layer" "$docker_image" /bin/bash -c "mkdir $installation_path && pip install $packages -t $installation_path  && zip -r lambda-layer.zip *"

echo "Uploading lambda layer to AWS"
aws lambda publish-layer-version --layer-name "$layername" --compatible-runtimes "$runtime" --zip-file "fileb://$host_temp_dir/lambda-layer.zip"

echo "Finishing up"
rm -rf "$host_temp_dir"

echo "Thanks from Srce Cde!"
