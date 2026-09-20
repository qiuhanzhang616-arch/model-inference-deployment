# Deployment Baseline Template

## 1. Project identity

- Project/environment:
- Deployment type: new / rebuild / migration / scale / template
- Business owner:
- Technical owner:
- Planned window:

## 2. Current baseline

- Current service and request path:
- Current model, weight revision, tokenizer/processor:
- Current image, framework, drivers/toolchain:
- Current compute, topology, network, and storage:
- Current API, authentication, and domain:
- Current monitoring, logs, alerts, and health checks:
- Differences between saved configuration and actual processes:
- Evidence time and source:

For a new deployment, write "no existing service." A migration or rebuild must record source-side runtime evidence.

## 3. Target baseline

- Business scenario and real request:
- Model and capability contract:
- Target compute and parallel topology:
- Target runtime and immutable image:
- Target network, security, and authentication:
- Target storage, backup, and retention:
- Target API and client compatibility:
- Target availability, capacity, and operations:

## 4. Open items

| Item | Current information | Missing/conflicting | How to obtain | Blocking stage |
|---|---|---|---|---|

## 5. Change plan

| Order | Action | Target | Impact | Verification | Rollback point |
|---|---|---|---|---|---|

## 6. Acceptance contract

- Infrastructure acceptance:
- Runtime acceptance:
- API/authentication acceptance:
- Model-capability acceptance:
- Reliability/recovery acceptance:
- Minimum-capacity smoke test:
- Security and audit acceptance:

## 7. Authorization and stop conditions

- Approved resources and actions:
- Downtime/traffic-switch window:
- Cost and duration limits:
- Errors that require stopping:
- Approval status:

## 8. Backup and rollback

- Known stable version:
- Configuration/script/weight inventory and hashes:
- Backup location:
- Rollback commands or operations:
- Rollback verification:
