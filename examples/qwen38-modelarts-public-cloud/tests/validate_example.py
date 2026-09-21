#!/usr/bin/env python3
"""Static validation for the public-cloud deployment example."""

from __future__ import annotations

import pathlib
import re


ROOT = pathlib.Path(__file__).resolve().parents[1]
REQUIRED = [
    ROOT / "README.md",
    ROOT / "config.env.example",
    ROOT / "scripts" / "download_weights.sh",
    ROOT / "scripts" / "mirror_image_to_swr.sh",
    ROOT / "scripts" / "preflight_modelarts_qwen38_tp4.sh",
    ROOT / "scripts" / "launch_modelarts_qwen38_tp4_200k.sh",
    ROOT / "scripts" / "smoke_qwen38_text.py",
]
FORBIDDEN_PATTERNS = [
    re.compile(r"(?i)\b(?:10|127|169\.254|192\.168)\.(?:\d{1,3}\.){1,2}\d{1,3}\b"),
    re.compile(r"(?i)\b172\.(?:1[6-9]|2\d|3[01])\.(?:\d{1,3}\.)\d{1,3}\b"),
    re.compile(r"(?i)\bprivate[-_ ]cloud\b"),
    re.compile(r"(?i)\.(?:internal|local)(?:\b|/)"),
]


def main() -> int:
    missing = [str(path.relative_to(ROOT)) for path in REQUIRED if not path.is_file()]
    if missing:
        raise SystemExit(f"missing files: {missing}")

    all_text = "\n".join(path.read_text(encoding="utf-8") for path in REQUIRED)
    leaked = [pattern.pattern for pattern in FORBIDDEN_PATTERNS if pattern.search(all_text)]
    if leaked:
        raise SystemExit(f"private-environment values found: {leaked}")

    required_markers = [
        "REPLACE_ME_REGION",
        "REPLACE_ME_PROJECT_ID",
        "REPLACE_ME_SWR_REGISTRY",
        "REPLACE_ME_SFS_TURBO_ENDPOINT",
        "REPLACE_ME_MODELARTS_CHAT_COMPLETIONS_URL",
        "quay.io/ascend/vllm-ascend:qwen3.8-a2",
        "Eco-Tech/Qwen3.8-27B-w8a8",
        "MAX_MODEL_LEN=204800",
        "--tensor-parallel-size 4",
    ]
    absent = [marker for marker in required_markers if marker not in all_text]
    if absent:
        raise SystemExit(f"required markers absent: {absent}")

    credential_pattern = re.compile(
        r"(?im)^(?:export\s+)?[A-Z0-9_]*(?:API_KEY|SECRET|PASSWORD)\s*=\s*"
        r"(?!['\"]?REPLACE|['\"]?\$\{)[^\s#]+"
    )
    if credential_pattern.search(all_text):
        raise SystemExit("possible committed credential assignment found")

    print("EXAMPLE_VALID")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
