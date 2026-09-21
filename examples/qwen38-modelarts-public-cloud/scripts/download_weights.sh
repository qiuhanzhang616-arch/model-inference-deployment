#!/usr/bin/env bash
set -euo pipefail

MODEL_ID=${MODEL_ID:-Eco-Tech/Qwen3.8-27B-w8a8}
MODEL_ROOT=${MODEL_ROOT:-/mnt/sfs-turbo/qwen38/models/Qwen3.8-27B-w8a8}

fail() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

command -v modelscope >/dev/null 2>&1 || fail "modelscope CLI is required; install it in the approved build environment"
[[ "${MODEL_ROOT}" == /* ]] || fail "MODEL_ROOT must be an absolute path"
[[ "${MODEL_ROOT}" != "/" ]] || fail "MODEL_ROOT cannot be /"

mkdir -p "${MODEL_ROOT}"
printf 'Downloading %s to %s\n' "${MODEL_ID}" "${MODEL_ROOT}"
modelscope download --model "${MODEL_ID}" --local_dir "${MODEL_ROOT}"

[[ -r "${MODEL_ROOT}/config.json" ]] || fail "config.json is missing after download"
[[ -r "${MODEL_ROOT}/quant_model_description.json" ]] || fail "Ascend W8A8 metadata is missing after download"

mapfile -t weight_files < <(find "${MODEL_ROOT}" -maxdepth 1 -type f -name '*.safetensors' -size +100M | sort)
(( ${#weight_files[@]} == 10 )) || fail "expected 10 materialized safetensors shards; found ${#weight_files[@]}"

(
  cd "${MODEL_ROOT}"
  find . -maxdepth 1 -type f -print0 | sort -z | xargs -0 sha256sum > SHA256SUMS
)

printf 'DOWNLOAD_OK model=%s shards=%s manifest=%s\n' "${MODEL_ID}" "${#weight_files[@]}" "${MODEL_ROOT}/SHA256SUMS"
