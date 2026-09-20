# GLM/Qwen Deployment Branch

Read this file only for GLM, CodeGeeX/GLM, Qwen/Qwen-VL, or their quantized variants. Derive exact parameters from the model card, weight configuration, and actual runtime.

## Shared checks

- Weights, tokenizer or processor, chat template, and generation configuration come from one compatible revision.
- Confirm whether the model is Dense or MoE, has built-in Reasoning, includes MTP or draft layers, or requires custom code.
- Quantization must exactly match the image, operators, and hardware generation. Never infer W4A8, W8A8, C8, or similar formats from filenames alone.
- Validate normal chat, streaming, Reasoning, Tool Calling, structured output, and target context instead of checking only `/models`.
- Confirm context, parallel topology, memory utilization, batching, graph compilation, and cache parameters from actual processes.

## GLM considerations

- Confirm the runtime's Reasoning Parser and Tool Call Parser and preserve reasoning fields in streams.
- MTP, MLAPO, FlashComm, EPLB, Shared Expert, sparse quantization operators, and PD disaggregation are capabilities of a particular model/image/hardware combination, not universal switches.
- For multi-node or PD deployments, validate every Prefill and Decode rank rather than only the entry proxy.
- Never mix parameters between A2, A3, or other hardware generations.

## Qwen considerations

- Distinguish text, Coder, VL, Audio, and MoE variants; their processors, input protocols, and resource models differ.
- For Qwen-VL acceptance, freeze image counts, resolution, video frames, and media transport.
- Check that the chat template, Tool Calling format, Thinking switch, and streaming fields match the client adapter.
- Include multimodal processor caching and media preprocessing nodes in the architecture.

## Additional branch acceptance

- At least one normal response, one streaming response, one target-capability request, and one boundary input.
- Returned content, Reasoning, Tool Call or JSON fields match what the real client sees.
- Run functional regression again after stress to catch empty streams, parser errors, or dropped instances.
