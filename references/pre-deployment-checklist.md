# Pre-deployment Checklist

Send this questionnaire for every new project. Prefill known answers and mark unknown items as pending inspection.

## A. Business objective and scope

1. What capability is being deployed, and for whom: online chat, coding agent, batch, RAG, embedding, reranking, image/document/video understanding, speech, or image/video generation?
2. Is this a new deployment, migration, in-place rebuild, scaling change, or standard image/template?
3. Is the target production, pre-production, test, or POC? What are the planned users, average and peak requests, availability target, and launch date?
4. Which components are in scope, and which existing platform, network, authentication, gateway, or monitoring components must be reused?
5. What region, data-residency, compliance, audit, and cost constraints apply?

## B. Model and capability contract

1. What are the model name, version, source, immutable revision or weight path, and license constraints?
2. What are the model type, parameter size, Dense or MoE architecture, precision, and quantization format?
3. Are the tokenizer, processor, chat template, adapters, and custom code complete?
4. What are the context or input limit, output limit, and default sampling policy?
5. Are streaming, Reasoning, Tool Calling, JSON Schema, image, audio, video, batch, or Embedding APIs required?
6. Which API protocol, SDK, and agent must the service support? Is the model alias fixed?

## C. Workload and capacity

1. Provide a real request and expected output.
2. What are P50, P95, and maximum input and output sizes, with units?
3. What are average, peak, and burst concurrency or QPS and session duration? Is queueing allowed?
4. Are prefixes, shared context, cache entries, or conversation history reused?
5. When capacity is insufficient, should the system queue, rate-limit, scale, degrade, or fail?

## D. Platform and hardware

1. What cloud or local platform, region/AZ, account or project, and service form are targeted?
2. What accelerator model and generation, VRAM or HBM, device count, nodes, CPU, memory, and architecture are available?
3. Are resources dedicated or shared? Are quota, shapes, and image registries available?
4. Is TP/DP/PP/EP/CP/PD topology prescribed, or should it be designed from the model and workload?
5. What driver, firmware, toolchain, and base-image version limits apply?

## E. Network, security, and authentication

1. Do calls originate from the internet, VPC, dedicated line or VPN, or the same cluster? What is the full path?
2. Is a public IP allowed? Must traffic use NAT, ELB/API gateway, private DNS, or a fixed domain?
3. Which directions, CIDRs, and ports are required, and who manages security groups, ACLs, firewalls, and proxies?
4. What are the certificate source, domain, rotation, and private-CA requirements?
5. Is authentication IAM, API key, JWT, enterprise identity, or tenant-specific keys? How are secrets injected and rotated?
6. Are per-user audit, quotas, cost allocation, or traffic isolation required?

## F. Storage and data

1. Where will weights, images, configuration, cache, and logs live? What capacity, performance, and mount protocol are required?
2. Is a shared filesystem, object storage, offline download, or air-gapped installation required?
3. How are weight and configuration integrity verified? What backup and retention policies exist?
4. Does the system handle sensitive data, and how much of request bodies and logs may be retained?

## G. Runtime and current state

1. What inference framework, version, image tag or digest, and launch mechanism are used?
2. For an existing service, what process arguments, environment variables, model, device count, and topology are actually running?
3. What health checks, logs, metrics, alerts, recovery, and scaling already exist?
4. What known OOM, startup, operator, communication, empty-response, certificate, or compatibility issues exist?

## H. Acceptance and change authorization

1. What are the functional, reliability, and minimum-capacity acceptance criteria?
2. Who provides test data and judges model correctness?
3. Which resources may be created or changed? Are downtime, restart, traffic switch, and scaling approved?
4. What maintenance window, maximum cost, maximum duration, and stop conditions apply?
5. What is the known stable version, backup location, rollback-time objective, and approver?

## Pre-execution confirmation

Before implementation, show the user:

- confirmed scope and objectives;
- current and target baselines;
- unknown or conflicting items;
- resources and files to create or modify;
- network, security, data, and secret handling;
- expected downtime, cost, duration, and impact;
- acceptance checklist, stop conditions, and rollback plan.

Execute only the changes the user confirms.
