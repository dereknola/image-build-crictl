#!/usr/bin/env bash

cd $(dirname $0)

which yq > /dev/null || go install github.com/mikefarah/yq/v4@v4.35.2

TAG_MINOR=$(./semver-parse.sh $1 minor)
K8S_VERSION=$(curl -sL https://proxy.golang.org/k8s.io/kubernetes/@v/list | grep -v - | grep v1.${TAG_MINOR} | sort -V | tail -n 1)
if [ -z "${K8S_VERSION}" ] || [ "${K8S_VERSION}" == "v.." ]; then
  echo "No Kubernetes version found in tag ${1}"
  exit 1
fi

GO_VERSION_URL="https://raw.githubusercontent.com/kubernetes/kubernetes/${K8S_VERSION}/.go-version"
GO_VERSION=$(curl -sL "${GO_VERSION_URL}")
if [[ "${GO_VERSION}" != "1."* ]]; then
  echo "No Go version found for Kubernetes ${K8S_VERSION}"
  exit 1
fi

BASE_URL='https://hub.docker.com/v2/repositories/rancher/hardened-build-base/tags'
NEXT_URL=$BASE_URL
MAX_PAGE=10
PAGE=0
TAG=""

while [ -n "${NEXT_URL}" ] && [ $PAGE -lt $MAX_PAGE ]; do
  RESPONSE=$(curl -s "$NEXT_URL")
  NEXT_URL=$(echo "$RESPONSE" | yq -r '.next // ""')
  set -x
  TAGS=$(echo "$RESPONSE" | yq -r '.results[].name')
  set +x
  TAG=$(echo "${TAGS}" | grep "${GO_VERSION}b[0-9+]$" | head -n 1)
  if [ -n "$TAG" ]; then
    break
  fi
  
  PAGE=$((PAGE + 1))
done

if [ -z "${TAG}" ]; then
  echo "No hardened-build-base tag found for Go ${GO_VERSION}"
  exit 1
fi

echo "${TAG}"
