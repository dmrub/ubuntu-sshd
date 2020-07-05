#!/bin/bash

set -eo pipefail

THIS_DIR=$( (cd "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P) )

IMAGE_PREFIX=${IMAGE_PREFIX:-ubuntu-sshd}
IMAGE_TAG=${IMAGE_TAG:-latest}
IMAGE_NAME=${IMAGE_PREFIX}:${IMAGE_TAG}

error() {
    echo >&2 "* [entrypoint.sh] Error: $*"
}

fatal() {
    error "$@"
    exit 1
}

read-keys() {
    local key_dir=$1
    local keys key
    if [[ -d "$key_dir" ]]; then
        for f in "$key_dir"/*.pub; do
            if [[ -r "$f" ]]; then
                key="$(< "$f")"
                if [[ -z "$keys" ]]; then
                    keys=$key
                elif [[ "$keys" == *$'\n' ]]; then
                keys="${keys}${key}"
                else
                    keys="${keys}$'\n'${key}"
                fi
            fi
        done
    fi
    echo "$keys"
}

usage() {
    echo "Run ubuntu-sshd container"
    echo
    echo "$0 [options]"
    echo "options:"
    echo "      --podman               Use podman instead of docker"
    echo "  -b, --base                 Base container (default: ${IMAGE_BASE})"
    echo "  -t, --tag=                 Image name and optional tag"
    echo "                             (default: ${IMAGE_NAME})"
    echo "      --help                 Display this help and exit"
}

USE_PODMAN=

while [[ $# -gt 0 ]]; do
    case "$1" in
        --podman)
            USE_PODMAN=true
            shift
            ;;
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

echo "USE_PODMAN:        $USE_PODMAN"
echo "IMAGE_BASE:        $IMAGE_BASE"
echo "IMAGE_NAME:        $IMAGE_NAME"

cd "$THIS_DIR"
ARGS=()
OPENSSH_AUTHORIZED_KEYS="$(read-keys keys)"
OPENSSH_ROOT_AUTHORIZED_KEYS="$(read-keys root-keys)"

if [[ "$USE_PODMAN" = "true" ]]; then
    set -xe
    podman run -p 2222:22 "${ARGS[@]}" \
        -e OPENSSH_AUTHORIZED_KEYS="$OPENSSH_AUTHORIZED_KEYS" \
        -e OPENSSH_ROOT_AUTHORIZED_KEYS="$OPENSSH_ROOT_AUTHORIZED_KEYS" \
        --name="$IMAGE_PREFIX" \
        --rm -ti "${IMAGE_NAME}" "$@"
else
    set -xe
    docker run -p 2222:22 "${ARGS[@]}" \
        -e OPENSSH_AUTHORIZED_KEYS="$OPENSSH_AUTHORIZED_KEYS" \
        -e OPENSSH_ROOT_AUTHORIZED_KEYS="$OPENSSH_ROOT_AUTHORIZED_KEYS" \
        --name="$IMAGE_PREFIX" \
        --rm -ti "${IMAGE_NAME}" "$@"
fi
