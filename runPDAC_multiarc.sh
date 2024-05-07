#!/bin/bash

svs_path="$1"
inference_path="${2:-inference}"
inference_patches_path="${3:-inference/Patches}"

if [ -d "$inference_path" ]; then
    echo "inference_path Directory exists"
else
    echo "inference_path Directory does not exist"
    mkdir -p "$inference_path"
fi

if [ -d "$inference_patches_path" ]; then
    echo "inference_patches_path Directory exists"
else
    echo "inference_patches_path Directory does not exist"
    mkdir -p "$inference_patches_path"
fi


# Return 0 exit code if the program is found. Non-zero otherwise.
program_exists() {
  hash "$1" 2>/dev/null;
}

echo "Searching for a container runner..."
echo "Checking whether Apptainer/Singularity or Docker is installed..."

container_runner="singularity"
can_use_singularity=false
can_use_docker=false

if program_exists "singularity"; then
    echo "Found Apptainer/Singularity!"
    echo "Checking whether we have the ability to use Apptainer/Singularity..."
    if ( img=$(mktemp --suffix=.sif) \
         && singularity pull --force "$img" 'docker://alpine:3.12' 2> /dev/null > /dev/null \
         && singularity run "$img" true && rm -f "$img" ); then
        echo "We can use Apptainer/Singularity!"
        can_use_singularity=true
    else
        echo "Error: we found singularity/apptainer but we cannot pull and/or run"
        echo "       singularity/apptainer images..."
        echo "Trying Docker next..."
        container_runner="docker"
    fi
else
    echo "Could not find Apptainer/Singularity..."
    container_runner="docker"
fi

if [ "$container_runner" = "docker" ]; then
    if program_exists "docker" ; then
        echo "Found Docker!"
        echo "Checking whether we have permission to use Docker..."
        # attempt to use docker. it is potentially not usable because it requires sudo.
        if ! (docker images 2> /dev/null > /dev/null); then
            echo "Error: we found 'docker' but we cannot use it. Please ensure that that"
            echo "       Docker daemon is running and that you have the proper permissions"
            echo "       to use 'docker'."
            exit 3
        fi
        container_runner="docker"
        can_use_docker=true
        echo "We can use Docker!"
    else
        echo "Could not find Docker..."
    fi
fi

if [ "$can_use_docker" != true ] && [ "$can_use_singularity" != true ]; then
    echo "Error: no container runner found!"
    echo "       We cannot run this code without a container runner."
    echo "       We tried to find 'singularity' and 'docker' but neither is available."
    echo "       To fix this, please install Docker or Apptainer/Singularity."
    exit 4
fi

echo "Container runner: $container_runner"


echo "Checking whether the input directories exist..."
if [ ! -d "$svs_path" ]; then
    echo "Error: svs directory not found: $svs_path"
    exit 5
fi


run_pipeline_in_singularity() {

    # Run the TIL-align workflow.
    pancreatic_cluster_container="pancreatic_cluster_multiarc_latest.sif"
    echo "Checking whether pancreatic_cluster container exists..."
    if [ ! -f "$pancreatic_cluster_container" ]; then
        echo "Downloading pancreatic_cluster container"
        singularity pull docker://saarthak02/pancreatic_cluster_multiarc:latest
    fi


    echo "Running pipeline..."
    singularity exec --nv --bind $svs_path:/usr/src/app/SVS,$inference_patches_path:/usr/src/app/inference/Patches,$inference_path:/usr/src/app/inference pancreatic_cluster_multiarc_latest.sif /usr/src/app/run_docker.sh /usr/src/app/SVS /usr/src/app/inference/Patches /usr/src/app/inference
    

}

run_pipeline_in_docker() {
    echo "Running pipeline..."
    docker run --shm-size=2g -v $svs_path:/usr/src/app/SVS -v $inference_patches_path:/usr/src/app/inference/Patches  -v $inference_path:/usr/src/app/inference saarthak02/pancreatic_cluster_multiarc /usr/src/app/SVS /usr/src/app/inference/Patches /usr/src/app/inference

    #docker run --shm-size=2g --gpus all -v $svs_path:/usr/src/app/SVS -v $inference_patches_path:/usr/src/app/inference/Patches  -v $inference_path:/usr/src/app/inference saarthak02/pancreatic_cluster_multiarc /usr/src/app/SVS /usr/src/app/inference/Patches /usr/src/app/inference

}


if [ "$container_runner" = "singularity" ]; then
    run_pipeline_in_singularity
elif [ "$container_runner" = "docker" ]; then
    run_pipeline_in_docker
else
    echo "Error: we seem to have a point in the code we thought we would never reach."
    echo "       Please email Saarthak Kapse <saarthak.kapse@stonybrook.edu>."
    exit 7
fi