#!/bin/sh

set -e

layername="$1"
runtime="$2"
packages="${@:3}"

echo "================================="

echo "LayerName: $layername"
echo "Runtime: $runtime"
echo "Packages: $packages"

echo "================================="

host_temp_dir="$(mktemp -d)"

support_python_runtime=("python3.6,python3.7,python3.8,python3.9,python3.10,python3.11,python3.12")

support_node_runtime=("nodejs10.x,nodejs12.x,nodejs14.x,nodejs16.x,nodejs18.x,nodejs20.x")

if [[ "${support_node_runtime[*]}" =~ "${runtime}" ]]; then
    
    installation_path="nodejs"
    docker_image="public.ecr.aws/sam/build-$runtime:latest"
    echo "Preparing lambda layer"
    docker run --rm -v "$host_temp_dir:/lambda-layer" -w "/lambda-layer" "$docker_image" /bin/bash -c "mkdir $installation_path && npm install --prefix $installation_path --save $packages && zip -r lambda-layer.zip *"

elif [[ "${support_python_runtime[*]}" =~ "${runtime}" ]]; then
    
    installation_path="python"
    docker_image="public.ecr.aws/sam/build-$runtime:latest"
    echo "Preparing lambda layer"
    docker run --rm -v "$host_temp_dir:/lambda-layer" -w "/lambda-layer" "$docker_image" /bin/bash -c "mkdir $installation_path && pip install $packages -t $installation_path  && zip -r lambda-layer.zip * -x '*/__pycache__/*'"

else
    echo "Invalid runtime"
    exit 1
fi

echo "Uploading lambda layer to AWS"
aws lambda publish-layer-version --layer-name "$layername" --compatible-runtimes "$runtime" --zip-file "fileb://$host_temp_dir/lambda-layer.zip"

echo "Finishing up"
rm -rf "$host_temp_dir"

echo "Thanks from Srce Cde!"
