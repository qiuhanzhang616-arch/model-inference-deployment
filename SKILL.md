---
name: model-inference-deployment
description: Plan, implement, and validate rollback-safe inference deployments across models, inference frameworks, accelerators, and cloud or local platforms. Use for new services, migrations, scaling, rebuilds, or standardization. Complete the deployment questionnaire and document current and target baselines first. Treat performance tuning and formal performance testing as separate follow-on work, and never apply GLM, Qwen, or hardware-specific parameters before requirements are confirmed.
---

# Model Inference Deployment

Turn the user's model and business requirements into a traceable, verifiable, and rollback-safe online or offline inference service. Deployment succeeds only after complete acceptance, not merely when a container starts or a port responds.

## First step: clarify before acting

For a new deployment, migration, rebuild, or scaling request, first read the complete [pre-deployment checklist](references/pre-deployment-checklist.md).

1. Prefill known answers from the conversation, files, and read-only inspection, then ask the user to confirm them.
2. Until the model, workload, target platform, capacity, security boundaries, and acceptance criteria are clear, do not select a final size, write final launch parameters, or create or modify cloud resources.
3. The user may mark unknown items as pending inspection. Do not ask them to rediscover technical facts that read-only checks can establish.
4. Before writing configuration, creating resources, restarting, switching traffic, or migrating data, present the exact execution checklist and obtain authorization for those actions.

## Distinguish deployment types

- **New deployment**: build the model service, network, security, storage, monitoring, and access endpoint from an empty environment.
- **In-place rebuild**: preserve the business endpoint or resources while replacing the image, weights, runtime, or launch configuration.
- **Migration**: move across accounts, regions, clusters, hardware, frameworks, or service forms.
- **Scale up or down**: change replicas, nodes, or parallel topology without implicitly changing model behavior.
- **Standard image or template**: produce a reusable image, IaC, deployment script, or runbook.

For every type, define the source and target, downtime method, data consistency, rollback point, and responsibility boundary.

## Establish the deployment baseline

After the questionnaire, complete the [deployment baseline template](references/deployment-baseline.md) and ask the user to confirm:

- current state and evidence sources;
- target architecture and model-service contract;
- unconfirmed or conflicting information;
- resource, security, network, storage, and operations boundaries;
- planned steps, impact, and expected duration;
- functional, capacity, and reliability acceptance items;
- backup and rollback plan.

For a new environment, the current state may be empty, but the target baseline is mandatory. When configuration files, console state, and actual processes disagree, trust verified runtime evidence and record the discrepancy.

## Design the target architecture

Choose for the current project rather than inheriting a historical architecture:

- Service form: realtime, asynchronous, batch, streaming, agent, embedding, reranking, multimodal, or generative media.
- Runtime form: managed inference, containers, Kubernetes, bare metal, multi-node, or hybrid.
- Model artifacts: weight version, quantization, tokenizer or processor, chat template, adapters, and licenses.
- Compute topology: accelerator model, device count, nodes, replicas, and applicable TP/DP/PP/EP/CP/PD parallelism.
- Request entry: authentication, API protocol, streaming, gateway, load balancing, queues, rate limits, timeouts, and retries.
- Network: public access, dedicated line or VPN, VPC, NAT, DNS, certificates, security groups, ACLs, and ingress/egress dependencies.
- Storage: images, weights, shared filesystems, object storage, logs, caches, and backups.
- Operations: health checks, logs, metrics, alerts, automatic recovery, scaling, and change audit.

Never infer client compatibility, Tool Calling, Reasoning, structured output, or attachment support from the model name alone. Validate them through the target API and runtime.

## Prepare and execute the deployment

Before implementation:

1. Pin versions or digests for the model, image, dependencies, and deployment configuration.
2. Check compatibility across hardware, drivers, firmware, runtime, operators, and quantization format.
3. Define secret injection so passwords, API keys, and private keys never enter the repository, image, logs, or report.
4. For an existing environment, preserve configuration, scripts, image and version details, the weight inventory, and hashes.
5. Prepare rollback steps that do not depend on the new configuration directory.
6. Reconfirm the authorized resource, cost, downtime, and traffic-switch scope.

During implementation, record commands, timestamps, operator, resource IDs, actual image digests, process arguments, and exceptions. If the user asks to pause, stop new changes and do not extend prior authorization.

## Layered acceptance

Validate in order:

1. **Infrastructure**: compute, network, storage, DNS, certificates, and permissions.
2. **Runtime**: every instance and rank is ready, with the correct process, model, device count, and parallel topology.
3. **Interface**: model listing, non-streaming, streaming, error codes, timeouts, and authentication.
4. **Model capabilities**: required text or multimodal behavior, Reasoning, Tool Calling, JSON, Embedding, and other project-specific functions.
5. **Reliability**: health probes, restart recovery, instance failures, queues, rate limits, logs, metrics, and alerts.
6. **Minimum capacity smoke test**: proves only that the target request shape runs; it is not a formal performance result.
7. **Rollback drill**: verifies recovery to the known stable version.

Route formal throughput, latency, concurrency limits, and optimal performance parameters to separate testing and tuning workflows. This skill never turns a smoke-test result into a capacity commitment.

## Deliverables

- Confirmed deployment questionnaire and baseline.
- Target architecture, dependencies, and security boundaries.
- Reproducible deployment scripts, IaC, images, or operating steps.
- Model, image, configuration, and weight version inventory.
- API usage, authentication method, and client examples without real secrets.
- Monitoring, logging, alerting, health checks, and routine operations guidance.
- Acceptance evidence, known limits, rollback steps, and responsibility boundaries.

For GLM or Qwen projects, also read the [GLM/Qwen deployment branch](references/branches/glm-qwen.md).
