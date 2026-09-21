#!/usr/bin/env python3
"""Non-streaming and streaming acceptance checks for the Qwen3.8 service."""

from __future__ import annotations

import argparse
import json
import os
import ssl
import urllib.request


def post(url: str, payload: dict, api_key: str | None, insecure: bool):
    headers = {"Content-Type": "application/json"}
    if api_key:
        headers["Authorization"] = f"Bearer {api_key}"
    request = urllib.request.Request(
        url,
        data=json.dumps(payload).encode("utf-8"),
        headers=headers,
        method="POST",
    )
    context = ssl._create_unverified_context() if insecure else None
    return urllib.request.urlopen(request, timeout=180, context=context)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--url", required=True)
    parser.add_argument("--model", default="qwen3.8-27b-w8a8")
    parser.add_argument("--api-key-env", default="MODELARTS_API_KEY")
    parser.add_argument("--insecure", action="store_true")
    args = parser.parse_args()

    api_key = os.environ.get(args.api_key_env, "").strip()
    if not api_key:
        raise SystemExit(f"Environment variable is empty: {args.api_key_env}")

    payload = {
        "model": args.model,
        "messages": [
            {"role": "system", "content": "You are a concise assistant."},
            {"role": "user", "content": "Reply with exactly: QWEN_TEXT_OK"},
        ],
        "max_completion_tokens": 32,
        "temperature": 0,
        "chat_template_kwargs": {"enable_thinking": False},
    }

    with post(args.url, {**payload, "stream": False}, api_key, args.insecure) as response:
        body = json.load(response)
    content = body["choices"][0]["message"].get("content", "")
    if content.strip() != "QWEN_TEXT_OK":
        raise SystemExit(f"non-streaming response failed: {content!r}")

    chunks: list[str] = []
    saw_done = False
    finish_reason = None
    with post(args.url, {**payload, "stream": True}, api_key, args.insecure) as response:
        for raw_line in response:
            line = raw_line.decode("utf-8").strip()
            if not line.startswith("data:"):
                continue
            data = line[5:].strip()
            if data == "[DONE]":
                saw_done = True
                break
            event = json.loads(data)
            choices = event.get("choices") or []
            if not choices:
                continue
            choice = choices[0]
            chunks.append(choice.get("delta", {}).get("content", ""))
            if choice.get("finish_reason") is not None:
                finish_reason = choice["finish_reason"]

    streamed = "".join(chunks)
    if streamed.strip() != "QWEN_TEXT_OK":
        raise SystemExit(f"streaming response failed: {streamed!r}")
    if not saw_done:
        raise SystemExit("stream ended before [DONE]")
    if finish_reason is None:
        raise SystemExit("stream omitted terminal finish_reason")

    print(
        json.dumps(
            {
                "status": "ok",
                "model": body.get("model"),
                "usage": body.get("usage"),
                "stream_finish_reason": finish_reason,
            },
            ensure_ascii=False,
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
