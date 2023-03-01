#!/usr/bin/env bash

set -eo pipefail

THIS_DIR=$( cd "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P )

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

usage() {
    echo "Build ubuntu-sshd container"
    echo
    echo "$0 [options]"
    echo "options:"
    echo "      --buildah              Use buildah instead of docker"
    echo "  -b, --base                 Base container (default: ${BASE_IMAGE})"
    echo "  -t, --tag=                 Image name and optional tag"
    echo "                             (default: ${IMAGE})"
    echo "      --no-cache             Disable Docker cache"
    echo "      --help                 Display this help and exit"
}

# shellcheck source=docker-config.sh
source "$THIS_DIR/docker-config.sh" || \
    fatal "Could not load configuration from $THIS_DIR/docker-config.sh"

USE_BUILDAH=
NO_CACHE=

while [[ $# -gt 0 ]]; do
    case "$1" in
        --buildah)
            USE_BUILDAH=true
            shift
            ;;
        -b|--base)
            BASE_IMAGE="$2"
            shift 2
            ;;
        --base=*)
            BASE_IMAGE="${1#*=}"
            shift
            ;;
        -t|--tag)
            IMAGE="$2"
            shift 2
            ;;
        --tag=*)
            IMAGE="${1#*=}"
            shift
            ;;
        --no-cache)
            NO_CACHE=true
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

echo "Image Configuration:"
echo "USE_BUILDAH:       $USE_BUILDAH"
echo "IMAGE_NAME:        $IMAGE_NAME"
echo "IMAGE:             $IMAGE"
echo "IMAGE_BASE:        $IMAGE_BASE"
echo "NO_CACHE:          $NO_CACHE"

if [[ "$USE_BUILDAH" = "true" ]]; then
    set -x
    buildah bud ${NO_CACHE:+--no-cache} \
                --build-arg "BASE_IMAGE=$BASE_IMAGE" \
                -t "${IMAGE}" \
                -f Dockerfile \
                "$THIS_DIR"
    set +x
else
    set -x
    docker build ${NO_CACHE:+--no-cache} \
                --build-arg "BASE_IMAGE=$BASE_IMAGE" \
                -t "${IMAGE}" \
                -f Dockerfile \
                "$THIS_DIR"
    set +x
fi
echo "Successfully built docker image $IMAGE"
