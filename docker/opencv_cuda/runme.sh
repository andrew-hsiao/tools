#!/bin/bash
#parameter: imanger_name, container_name, volumne_name_host (will be mapped to /ref)
IMG_NAME=opencv_cuda
CTN_NAME=opencv_cuda_c
VOL_PATH=${HOME}

if [ "$#" -eq 1 ]; then
  VOL_PATH=$3
fi

if [ "$#" -eq "2" ]; then
  IMG_NAME=$1
  CTN_NAME=$2
fi

if [ "$#" -eq "3" ]; then
  IMG_NAME=$1
  CTN_NAME=$2
  VOL_PATH=$3
fi

set -e

export CUDA_HOME=${CUDA_HOME:-/usr/local/cuda}

if [ ! -d ${CUDA_HOME}/lib64 ]; then
  echo "Failed to locate CUDA libs at ${CUDA_HOME}/lib64."
  exit 1
fi

export CUDA_SO=$(\ls /usr/lib/x86_64-linux-gnu/libcuda* | \
                    xargs -I{} echo '-v {}:{}')
export DEVICES=$(\ls /dev/nvidia* | \
                    xargs -I{} echo '--device {}:{}')

if [[ "${DEVICES}" = "" ]]; then
  echo "Failed to locate NVidia device(s). Did you want the non-GPU container?"
  exit 1
fi

export LIB_MODULES=$(\uname -r | xargs -I{} echo '-v /lib/modules/{}:/lib/modules/{}')

xhost +

docker run --privileged --rm -it \
  $CUDA_SO $LIB_MODULES $DEVICES \
  --env DISPLAY=$DISPLAY \
  --env="QT_X11_NO_MITSHM=1" \
  -v /dev/video0:/dev/video0 \
  -v /tmp/.X11-unix:/tmp/.X11-unix:ro  \
  -v ${VOL_PATH}:/ref \
  --name ${CTN_NAME} \
   ${IMG_NAME} bash

xhost -
