#!/usr/bin/env bash
set -euo pipefail

UPSTREAM_IMAGE=${UPSTREAM_IMAGE:-quay.io/ascend/vllm-ascend:qwen3.8-a2}
TARGET_IMAGE=${TARGET_IMAGE:-REPLACE_ME_SWR_REGISTRY/REPLACE_ME_SWR_ORGANIZATION/vllm-ascend:qwen3.8-a2}

fail() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

command -v docker >/dev/null 2>&1 || fail "docker is required"
[[ "${TARGET_IMAGE}" != *REPLACE_ME_* ]] || fail "set TARGET_IMAGE to your target-region SWR image URI"

printf 'The script expects an active SWR login. Generate the login command in the SWR console.\n'
docker pull "${UPSTREAM_IMAGE}"
docker tag "${UPSTREAM_IMAGE}" "${TARGET_IMAGE}"
docker push "${TARGET_IMAGE}"

repo_digest=$(docker image inspect "${TARGET_IMAGE}" --format '{{index .RepoDigests 0}}')
[[ -n "${repo_digest}" ]] || fail "the pushed image has no RepoDigest"
printf 'PUSH_OK image=%s\n' "${repo_digest}"
printf 'Copy this digest into the ModelArts deployment and config.env.\n'
