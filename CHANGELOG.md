# Changelog

**Repository:** `dpn-infrastructure-aws`  
**Description:** `Tracks all notable changes, version history, and roadmap toward 1.0.0 following Semantic Versioning.`

<!-- SPDX-License-Identifier: OGL-UK-3.0 -->

--- 

All notable changes to this repository will be documented in this file.

This project follows **Semantic Versioning (SemVer)** ([semver.org](https://semver.org/)), using the format:

`[MAJOR].[MINOR].[PATCH]`
- **MAJOR** (`X.0.0`) – Incompatible API/feature changes that break backward compatibility.
- **MINOR** (`0.X.0`) – Backward-compatible new features, enhancements, or functionality changes.
- **PATCH** (`0.0.X`) – Backward-compatible bug fixes, security updates, or minor corrections.
- **Pre-release versions** – Use suffixes such as `-alpha`, `-beta`, `-rc.1` (e.g., `2.1.0-beta.1`).
- **Build metadata** – If needed, use `+build` (e.g., `2.1.0+20260314`).

---

## How to Update This Changelog

1. When making changes, update this file under the **Unreleased** section.
2. Before a new release, move changes from **Unreleased** to a new dated section with a version number.
3. Follow **Semantic Versioning** rules to categorise changes correctly.
4. If pre-release versions are used, clearly mark them as `-alpha`, `-beta`, or `-rc.X`.

---

## Release 1.0.0

- Established initial project implementation, repository baseline, and README documentation.
- Added OpenTofu bootstrap stack for remote state management, including S3 backend and DynamoDB state locking.
- Implemented core networking module covering VPC, subnets, routing, and centralized egress.
- Added EKS module for private cluster provisioning, including node groups and cluster access configuration.
- Implemented security module for IAM roles, KMS keys, and security group management.
- Added workload identity and IRSA modules, including dedicated IRSA support for the AWS Load Balancer Controller and application workloads.
- Added ingress module and Kubernetes platform module for in-cluster add-ons and load balancing.
- Implemented storage, database, and EFS modules for persistent and shared workload storage.
- Added container registry module for image storage and management.
- Added compliance and observability modules to support monitoring and organizational security requirements.
- Added management host and management host IAM modules for controlled operator access to the private cluster.
- Added deployment helper script (`deploy.sh`) driven by environment variables for bootstrap and main stack deployment.
- Reduced configuration to a single `example` environment with synthetic documentation values for public reference use.
- Added prerequisites, deployment, and access documentation.
 
---

## Maintained by the National Energy System Operator (NESO)

Copyright 2026 NESO and the Crown.  This work is licensed under the Open Government Licence 3.0 (OGL). This work has been developed by NESO using content licensed by the Department for Business and Trade (UK) under the OGL.   
 
Licensed under the Open Government Licence v3.0.

For full licensing terms, [OGL_LICENSE.md](./OGL_LICENSE.md)
