#!/usr/bin/env bash
set -euo pipefail

SFS_ROOT=${SFS_ROOT:-/mnt/sfs-turbo/qwen38}
MODEL_ROOT=${MODEL_ROOT:-${SFS_ROOT}/models/Qwen3.8-27B-w8a8}
MODEL_NAME=${MODEL_NAME:-qwen3.8-27b-w8a8}
PORT=${PORT:-8080}
MAX_MODEL_LEN=${MAX_MODEL_LEN:-204800}
MAX_NUM_SEQS=${MAX_NUM_SEQS:-32}
MAX_NUM_BATCHED_TOKENS=${MAX_NUM_BATCHED_TOKENS:-16384}
GPU_MEMORY_UTILIZATION=${GPU_MEMORY_UTILIZATION:-0.90}

fail() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

[[ "${PORT}" == "8080" ]] || fail "ModelArts Standard container port must be 8080 for this template"
[[ "${MAX_MODEL_LEN}" == "204800" ]] || fail "the tested 200K profile requires MAX_MODEL_LEN=204800"
[[ -r "${MODEL_ROOT}/config.json" ]] || fail "missing model config: ${MODEL_ROOT}/config.json"
[[ -r "${MODEL_ROOT}/quant_model_description.json" ]] || fail "missing Ascend W8A8 metadata"
command -v vllm >/dev/null 2>&1 || fail "vllm is unavailable in the selected image"

mapfile -t weight_files < <(find "${MODEL_ROOT}" -maxdepth 1 -type f -name '*.safetensors' -size +100M | sort)
(( ${#weight_files[@]} == 10 )) || fail "expected 10 materialized safetensors shards; found ${#weight_files[@]}"

export ASCEND_RT_VISIBLE_DEVICES=${ASCEND_RT_VISIBLE_DEVICES:-0,1,2,3}
export ASCEND_VISIBLE_DEVICES=${ASCEND_VISIBLE_DEVICES:-0,1,2,3}
export HCCL_BUFFSIZE=${HCCL_BUFFSIZE:-512}
export HCCL_CONNECT_TIMEOUT=${HCCL_CONNECT_TIMEOUT:-7200}
export HCCL_EXEC_TIMEOUT=${HCCL_EXEC_TIMEOUT:-0}
export PYTORCH_NPU_ALLOC_CONF=${PYTORCH_NPU_ALLOC_CONF:-expandable_segments:True}

# Keep the read-only SFS mount free of runtime caches.
export HF_HUB_OFFLINE=1
export TRANSFORMERS_OFFLINE=1
export VLLM_USE_MODELSCOPE=False
export HF_HOME=${HF_HOME:-/tmp/qwen38-hf-cache}
export XDG_CACHE_HOME=${XDG_CACHE_HOME:-/tmp/qwen38-xdg-cache}
mkdir -p "${HF_HOME}" "${XDG_CACHE_HOME}"

printf 'Starting Qwen3.8 model=%s served_name=%s port=%s topology=TP4 context=%s seqs=%s batch_tokens=%s memory=%s\n' \
  "${MODEL_ROOT}" "${MODEL_NAME}" "${PORT}" "${MAX_MODEL_LEN}" "${MAX_NUM_SEQS}" \
  "${MAX_NUM_BATCHED_TOKENS}" "${GPU_MEMORY_UTILIZATION}"

# MTP is deliberately not enabled in this tested profile.
exec vllm serve "${MODEL_ROOT}" \
  --host 0.0.0.0 \
  --port "${PORT}" \
  --served-model-name "${MODEL_NAME}" \
  --trust-remote-code \
  --quantization ascend \
  --dtype bfloat16 \
  --tensor-parallel-size 4 \
  --max-model-len "${MAX_MODEL_LEN}" \
  --max-num-seqs "${MAX_NUM_SEQS}" \
  --max-num-batched-tokens "${MAX_NUM_BATCHED_TOKENS}" \
  --gpu-memory-utilization "${GPU_MEMORY_UTILIZATION}" \
  --enable-chunked-prefill \
  --enable-prefix-caching \
  --compilation-config '{"cudagraph_mode":"FULL_DECODE_ONLY"}' \
  --additional-config '{"enable_cpu_binding":true}' \
  --generation-config vllm
