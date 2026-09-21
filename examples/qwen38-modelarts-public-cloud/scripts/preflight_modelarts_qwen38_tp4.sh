#!/usr/bin/env bash
set -euo pipefail

MODEL_ROOT=${MODEL_ROOT:-/mnt/sfs-turbo/qwen38/models/Qwen3.8-27B-w8a8}
MAX_MODEL_LEN=${MAX_MODEL_LEN:-204800}

fail() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

[[ -d "${MODEL_ROOT}" ]] || fail "model directory not found: ${MODEL_ROOT}"
[[ -r "${MODEL_ROOT}/config.json" ]] || fail "config.json is missing"
[[ -r "${MODEL_ROOT}/quant_model_description.json" ]] || fail "Ascend W8A8 metadata is missing"
command -v vllm >/dev/null 2>&1 || fail "vllm is unavailable"
command -v npu-smi >/dev/null 2>&1 || fail "npu-smi is unavailable"

mapfile -t weight_files < <(find "${MODEL_ROOT}" -maxdepth 1 -type f -name '*.safetensors' -size +100M | sort)
(( ${#weight_files[@]} == 10 )) || fail "expected 10 materialized safetensors shards; found ${#weight_files[@]}"

python3 - "${MODEL_ROOT}" "${MAX_MODEL_LEN}" <<'PY'
import json
import pathlib
import sys

root = pathlib.Path(sys.argv[1])
requested_context = int(sys.argv[2])
config = json.loads((root / "config.json").read_text(encoding="utf-8"))
text_config = config.get("text_config") or {}
architectures = config.get("architectures") or text_config.get("architectures") or []
if architectures != ["Qwen3_5ForConditionalGeneration"]:
    raise SystemExit(f"ERROR: unexpected architecture: {architectures}")
native_context = text_config.get("max_position_embeddings") or config.get("max_position_embeddings")
if native_context is not None and requested_context > int(native_context):
    raise SystemExit(
        f"ERROR: requested context {requested_context} exceeds checkpoint context {native_context}"
    )
if not (config.get("vision_config") or text_config.get("vision_config")):
    raise SystemExit("ERROR: vision_config is absent from the expected Qwen3.8 checkpoint")
print(f"checkpoint=Qwen3_5ForConditionalGeneration native_context={native_context}")
PY

for device in 0 1 2 3; do
  [[ -e "/dev/davinci${device}" ]] || fail "/dev/davinci${device} is unavailable"
done

help_text=$(vllm serve --help 2>&1)
for option in \
  --quantization \
  --tensor-parallel-size \
  --max-model-len \
  --max-num-seqs \
  --max-num-batched-tokens \
  --enable-chunked-prefill \
  --enable-prefix-caching \
  --compilation-config \
  --additional-config \
  --generation-config; do
  grep -q -- "${option}" <<<"${help_text}" || fail "selected image does not support ${option}"
done

python3 - <<'PY'
import vllm
try:
    import vllm_ascend
except Exception as exc:
    raise SystemExit(f"ERROR: vllm_ascend import failed: {exc}")
print(f"vllm={getattr(vllm, '__version__', 'unknown')} vllm_ascend={getattr(vllm_ascend, '__version__', 'unknown')}")
PY

npu-smi info -l
printf 'PRECHECK_OK service=modelarts-standard topology=TP4 port=8080 model=%s context=%s\n' "${MODEL_ROOT}" "${MAX_MODEL_LEN}"
