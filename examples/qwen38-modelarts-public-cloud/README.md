# Qwen3.8-27B W8A8 on Huawei Cloud ModelArts Standard

This guide deploys a single Qwen3.8-27B W8A8 text service on **Huawei Cloud public cloud** using **ModelArts Standard real-time inference**, a four-device Ascend A2/910B-compatible flavor, TP=4, and a 200K total context budget.

It is a reusable template. Values beginning with `REPLACE_ME_` belong to the deployer's Huawei Cloud account and must be replaced. Do not copy project IDs, VPC IDs, SFS endpoints, SWR paths, service URLs, credentials, or API keys from another account or region.

## 1. Tested service profile

| Item | Value |
|---|---|
| Model | `Eco-Tech/Qwen3.8-27B-w8a8` |
| Architecture | `Qwen3_5ForConditionalGeneration` |
| Quantization | Ascend W8A8 |
| Service | ModelArts Standard real-time inference |
| Compute | One container with four Ascend A2/910B-compatible devices |
| Parallelism | Tensor parallelism 4 |
| Total context | `204800` tokens, input plus requested output |
| Served name | `qwen3.8-27b-w8a8` |
| Container port | `8080` |
| Max sequences | `32` |
| Max batched tokens | `16384` |
| NPU memory utilization | `0.90` |
| Enabled | Chunked prefill, prefix caching, Full Decode graph, CPU binding |
| Disabled | MTP/speculative decoding in this tested profile |

Qwen3.8 has a native 262,144-token context. This profile uses 204,800 total tokens without RoPE scaling. `chat_template_kwargs.enable_thinking=false` is a **request field**, not a server-wide switch.

The four-device flavor name is region-specific. Record the exact flavor selected in `config.env.example`; do not assume that a flavor available in one region exists in another.

## 2. Public source addresses

### Model weights

- ModelScope page: <https://www.modelscope.cn/models/Eco-Tech/Qwen3.8-27B-w8a8>
- Model ID: `Eco-Tech/Qwen3.8-27B-w8a8`
- vLLM-Ascend model guide: <https://docs.vllm.ai/projects/ascend/en/latest/tutorials/models/Qwen3.8-27B.html>

Review the model license and your organization's software-supply policy before downloading. Generate and retain your own file manifest and SHA-256 checksums after download.

### Container image

- Upstream A2 image: `quay.io/ascend/vllm-ascend:qwen3.8-a2`
- Upstream installation guide: <https://docs.vllm.ai/projects/ascend/en/latest/getting_started/installation.html>
- Target image in your account:
  `REPLACE_ME_SWR_REGISTRY/REPLACE_ME_SWR_ORGANIZATION/vllm-ascend:qwen3.8-a2`
- Production selection: use the pushed SWR image **by digest**:
  `REPLACE_ME_SWR_IMAGE_URI@sha256:REPLACE_ME_IMAGE_DIGEST`

The original tested environment used the ModelArts catalog alias `modelarts/vllm-ascend:nightly-releases-v0.25.1rc`. That catalog alias is not guaranteed to exist in Huawei Cloud public-cloud regions and is not a portable image address. Mirror the upstream image into your own SWR repository and pin its digest.

## 3. Huawei Cloud portals and permission references

Use the console for your account type:

- International/public-cloud console: <https://console-intl.huaweicloud.com/>
- Chinese-mainland console: <https://console.huaweicloud.com/>
- IAM: <https://console-intl.huaweicloud.com/iam/>
- ModelArts: <https://console-intl.huaweicloud.com/modelarts/>
- SWR: <https://console-intl.huaweicloud.com/swr/>
- SFS Turbo: <https://console-intl.huaweicloud.com/sfs/>
- VPC: <https://console-intl.huaweicloud.com/vpc/>
- OBS: <https://console-intl.huaweicloud.com/obs/>

Official documentation:

- IAM user and ModelArts permissions: <https://support.huaweicloud.com/intl/en-us/usermanual-standard-modelarts/umn-standard-modelarts-0004.html>
- ModelArts agency authorization: <https://support.huaweicloud.com/intl/en-us/permission-modelarts/modelarts_24_0091.html>
- Permission dependencies and agencies: <https://support.huaweicloud.com/intl/en-us/permission-modelarts/modelarts_24_0081.html>
- ModelArts custom images and SWR: <https://support.huaweicloud.com/intl/en-us/usermanual-standard-modelarts/modelarts_23_0084.html>
- ModelArts real-time inference: <https://support.huaweicloud.com/intl/en-us/helppanel-modelarts/ma_help_012.html>

Typical operator policies for this workflow are listed below. Apply least privilege and follow your organization's IAM policy.

| Service | Typical policy | When needed |
|---|---|---|
| ModelArts | `ModelArts FullAccess` | Required if the operator creates or changes a dedicated resource pool. |
| ModelArts | `ModelArts CommonOperations` | Use instead when an administrator supplies the resource pool and the operator only uses resources. |
| OBS | `OBS OperateAccess` | Required by the standard ModelArts permission guide and useful for logs or artifacts. |
| SWR | `SWR OperateAccess` | Required to push and select the custom inference image. |
| VPC | `VPC FullAccess` | Needed when the operator creates or changes the pool network. |
| SFS | `SFS Turbo FullAccess` | Needed when the operator creates or manages the shared file system. |
| Cloud Eye | `CES FullAccess` | Optional for service monitoring and alarms. |
| SMN | `SMN FullAccess` | Optional for alarm notifications. |

In ModelArts, configure an agency for the target IAM user. The agency must be able to read the selected SWR image and access the OBS/SFS/VPC resources used by the service. Agency authorization is region-specific. Permission changes can take time to become effective.

## 4. Repository contents

```text
qwen38-modelarts-public-cloud/
├── README.md
├── config.env.example
├── scripts/
│   ├── download_weights.sh
│   ├── launch_modelarts_qwen38_tp4_200k.sh
│   ├── mirror_image_to_swr.sh
│   ├── preflight_modelarts_qwen38_tp4.sh
│   └── smoke_qwen38_text.py
└── tests/
    └── validate_example.py
```

Copy `config.env.example` to a protected operator workspace, replace every `REPLACE_ME_` value, and do not commit the completed file.

## 5. Fill the deployment worksheet

```bash
cp config.env.example config.env
chmod 600 config.env
vi config.env
```

At minimum, supply:

- Huawei Cloud region and project ID;
- dedicated resource pool and four-device Ascend flavor;
- VPC, subnet, and security group IDs;
- SFS Turbo endpoint/export and mount configuration;
- SWR registry, organization, repository, tag, and final digest;
- ModelArts service/deployment names;
- the API address copied from the deployed service page.

Never place an API key, AK/SK, IAM token, SWR login command, or private key in `config.env` or in this repository.

## 6. Create network, storage, and compute

1. Select one region and confirm that ModelArts Standard, the required four-device Ascend flavor, SWR, and SFS Turbo are available there.
2. Create or select a VPC and subnet. Record their IDs.
3. Create a dedicated ModelArts Standard resource pool or obtain one from the platform administrator.
4. Interconnect the resource pool with the VPC that contains SFS Turbo.
5. Create an SFS Turbo file system in the same reachable network. Record its endpoint/export.
6. Allow only the required east-west traffic between the resource pool and SFS Turbo. Do not expose NFS directly to the public internet.
7. Decide whether the service is called over the public ModelArts endpoint or a private VPCEP connection. Record the client CIDRs and authentication method.

Recommended mount layout inside the inference container:

```text
/mnt/sfs-turbo/qwen38/
├── models/Qwen3.8-27B-w8a8/
├── scripts/
├── manifests/
└── logs/
```

## 7. Download weights to SFS Turbo

Run the download from an authorized ECS or ModelArts notebook that can mount the target SFS Turbo and reach ModelScope.

```bash
export MODEL_ROOT=/mnt/sfs-turbo/qwen38/models/Qwen3.8-27B-w8a8
bash scripts/download_weights.sh
```

The script does not install packages automatically. Install and approve the required ModelScope CLI in your controlled build environment before running it.

Store the generated manifest:

```bash
mkdir -p /mnt/sfs-turbo/qwen38/manifests
cp "${MODEL_ROOT}/SHA256SUMS" /mnt/sfs-turbo/qwen38/manifests/qwen38-w8a8.SHA256SUMS
```

## 8. Mirror and pin the runtime image

Create a private SWR organization and repository in the target region. In the SWR console, choose **Generate Login Command**, execute that command interactively, and do not save it in shell scripts or Git.

```bash
export TARGET_IMAGE=REPLACE_ME_SWR_REGISTRY/REPLACE_ME_SWR_ORGANIZATION/vllm-ascend:qwen3.8-a2
bash scripts/mirror_image_to_swr.sh
```

Copy the resulting `RepoDigest` into `config.env`. ModelArts must select the SWR image by digest for a reproducible deployment.

## 9. Upload scripts to SFS Turbo

```bash
install -d -m 0755 /mnt/sfs-turbo/qwen38/scripts
install -m 0755 scripts/launch_modelarts_qwen38_tp4_200k.sh /mnt/sfs-turbo/qwen38/scripts/
install -m 0755 scripts/preflight_modelarts_qwen38_tp4.sh /mnt/sfs-turbo/qwen38/scripts/
install -m 0755 scripts/smoke_qwen38_text.py /mnt/sfs-turbo/qwen38/scripts/
sha256sum /mnt/sfs-turbo/qwen38/scripts/* > /mnt/sfs-turbo/qwen38/manifests/qwen38-scripts.SHA256SUMS
```

The inference service should mount SFS read-only. Runtime caches are written under `/tmp` in the container.

## 10. Create the ModelArts Standard real-time service

In the target-region ModelArts console, create a real-time service and one deployment with these values:

| Field | Value |
|---|---|
| Resource pool | `REPLACE_ME_RESOURCE_POOL_NAME` |
| Flavor | `REPLACE_ME_4_DEVICE_ASCEND_A2_FLAVOR` |
| Replicas | `1` |
| Image | `REPLACE_ME_SWR_IMAGE_URI@sha256:REPLACE_ME_IMAGE_DIGEST` |
| Container protocol/port | `HTTP / 8080` |
| SFS mount source | `REPLACE_ME_SFS_TURBO_ENDPOINT:/REPLACE_ME_EXPORT` |
| Container mount path | `/mnt/sfs-turbo` |
| Startup command | `bash /mnt/sfs-turbo/qwen38/scripts/launch_modelarts_qwen38_tp4_200k.sh` |
| Deployment timeout | `60 minutes` or your approved value |
| Request timeout | `120 seconds` was used by the tested service; choose a value that matches your queueing/SLA design |
| Authentication | API key or IAM token; do not use unauthenticated access for production |

Environment variables:

```text
SFS_ROOT=/mnt/sfs-turbo/qwen38
MODEL_ROOT=/mnt/sfs-turbo/qwen38/models/Qwen3.8-27B-w8a8
MODEL_NAME=qwen3.8-27b-w8a8
PORT=8080
```

Health probes:

| Probe | Path | Guidance |
|---|---|---|
| Startup | `GET /health` | Allow enough time for loading ten weight shards and graph capture. |
| Readiness | `GET /health` | Do not send traffic until it succeeds. |
| Liveness | `GET /health` | Use conservative failure thresholds to avoid killing a healthy service during temporary load. |

Before directing production traffic, open the deployment logs and verify the actual command line, TP=4, model path, context length, image digest, four visible devices, and one ready replica.

## 11. Run preflight and acceptance checks

Use a ModelArts shell/debug facility or the same image on an authorized four-device validation node:

```bash
export MODEL_ROOT=/mnt/sfs-turbo/qwen38/models/Qwen3.8-27B-w8a8
bash /mnt/sfs-turbo/qwen38/scripts/preflight_modelarts_qwen38_tp4.sh
```

After the deployment is Running, copy the exact chat-completions URL from the ModelArts service page and keep the API key only in an environment variable:

```bash
export MODELARTS_API_KEY='REPLACE_AT_RUNTIME_NOT_IN_GIT'
python3 /mnt/sfs-turbo/qwen38/scripts/smoke_qwen38_text.py \
  --url 'REPLACE_ME_MODELARTS_CHAT_COMPLETIONS_URL' \
  --model qwen3.8-27b-w8a8 \
  --api-key-env MODELARTS_API_KEY
```

Acceptance checklist:

- service and deployment are `Running`, with `1/1` replica ready;
- the image is the expected SWR digest;
- `/v1/models` exposes `qwen3.8-27b-w8a8` and reports the intended context;
- non-streaming returns valid content;
- streaming includes a terminal `finish_reason` and `[DONE]`;
- thinking is disabled only when the request includes `chat_template_kwargs.enable_thinking=false`;
- an over-limit request is rejected clearly and does not crash the service;
- post-test health and short chat still pass;
- authentication rejects missing or invalid credentials.

Formal QPS, TTFT, TPOT, stability, and capacity testing is a separate workflow. A successful smoke test is not a production-capacity commitment.

## 12. Rollback and change management

Before the first upgrade:

1. retain the last working ModelArts deployment version;
2. retain the previous SWR image digest;
3. keep versioned launch scripts instead of editing the only copy in place;
4. keep weight and script SHA-256 manifests;
5. record who approves traffic switching and rollback.

Rollback procedure:

1. stop new traffic or set the service traffic weight to zero;
2. switch to the last working ModelArts deployment version or clone it as a new deployment;
3. verify its image digest, launch script, weight manifest, and mount;
4. wait for readiness and repeat non-streaming, streaming, authentication, and health tests;
5. restore traffic only after acceptance passes.

## 13. Known compatibility note

MTP/speculative decoding is disabled in this tested launch profile. A first-request regression was observed with one tested vLLM-Ascend 0.25.1 release candidate. Do not enable MTP merely because the checkpoint contains an MTP head. Enable it only after validating the exact image/model/hardware combination, including a first real request and post-request health.

Related upstream issue: <https://github.com/vllm-project/vllm-ascend/issues/13630>

## 14. Common failures

| Symptom | Check |
|---|---|
| Image cannot be selected | Confirm the image is in SWR in the same region, the repository is accessible, the digest exists, and the ModelArts agency can read SWR. |
| Model path missing | Confirm SFS Turbo is reachable from the resource-pool VPC and mounted at `/mnt/sfs-turbo`. |
| `403` or permission denied | Verify IAM user policies and the region-specific ModelArts agency. |
| Fewer than four devices | Verify the selected flavor and ModelArts resource allocation; do not change TP to hide the mismatch. |
| Startup probe fails | Inspect weight integrity, image compatibility, model load time, graph capture, and startup-probe thresholds. |
| First request crashes | Confirm MTP is disabled and compare the exact vLLM/vLLM-Ascend versions with the known issue. |
| Long requests return empty output | Compare queue time with the ModelArts request timeout; treat HTTP 200 with no valid output as failure. |

## 15. Values every deployer must replace

Run this before deployment:

```bash
grep -RIn 'REPLACE_ME_' .
```

Every match in a runtime configuration must be resolved. Placeholders in this guide may remain as examples. Never replace placeholders with credentials in a tracked file.
