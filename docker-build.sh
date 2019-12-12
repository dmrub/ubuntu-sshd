#!/bin/bash

set -eo pipefail

THIS_DIR=$( (cd "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P) )

error() {
    echo >&2 "* Error: $*"
}

fatal() {
    error "$@"
    exit 1
}

message() {
    echo "$@"
}

IMAGE_BASE=ubuntu:18.04
IMAGE_PREFIX=${IMAGE_PREFIX:-ubuntu-sshd}
IMAGE_TAG=${IMAGE_TAG:-latest}
IMAGE_NAME=${IMAGE_PREFIX}:${IMAGE_TAG}

usage() {
    echo "Build ubuntu-sshd container"
    echo
    echo "$0 [options]"
    echo "options:"
    echo "  -b, --base                 Base container (default: ${IMAGE_BASE})"
    echo "  -t, --tag=                 Image name and optional tag"
    echo "                             (default: ${IMAGE_NAME})"
    echo "      --no-cache             Disable Docker cache"
    echo "      --help                 Display this help and exit"
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -b|--base)
            IMAGE_BASE="$2"
            shift 2
            ;;
        --base=*)
            IMAGE_BASE="${1#*=}"
            shift
            ;;
        -t|--tag)
            IMAGE_NAME="$2"
            shift 2
            ;;
        --tag=*)
            IMAGE_NAME="${1#*=}"
            shift
            ;;
        --no-cache)
            NO_CACHE=--no-cache
            shift
            ;;
        --help)
            usage
            exit
            ;;
        --)
            shift
            break
            ;;
        -*)
            fatal "Unknown option $1"
            ;;
        *)
            break
            ;;
    esac
done

echo "IMAGE_BASE:        $IMAGE_BASE"
echo "IMAGE_NAME:        $IMAGE_NAME"
echo "NO_CACHE:          $NO_CACHE"

set -x
docker build $NO_CACHE \
             --build-arg "BASE=$IMAGE_BASE" \
             -t "${IMAGE_NAME}" \
             "$THIS_DIR"
set +x
echo "Successfully built docker image $IMAGE_NAME"
