# kro + Kyverno Demo

Demonstrates using [kro](https://kro.run) ResourceGraphDefinitions with [Kyverno](https://kyverno.io) policies to enforce team-level resource budget constraints across namespaces.

## Overview

This demo creates a `ClusterResourceQuotas` custom resource (via kro) that:

1. Discovers all `ResourceQuota` objects labeled for a team across namespaces
2. Aggregates CPU and memory usage in the status
3. Deploys a Kyverno `ClusterPolicy` that validates new `ResourceQuota` objects against the team's budget

## Prerequisites

- [kind](https://kind.sigs.k8s.io/)
- [helm](https://helm.sh/)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)

## Quick Start

```bash
# Create cluster with kro and kyverno installed
make cluster

# Optionally set versions
make cluster KRO_VERSION=0.9.0-rc1 KYVERNO_VERSION=3.7.1

# Deploy the demo resources
make demo-setup

# Test the budget policy
make demo-test
```

## Targets

```
make help
```

## Cleanup

```bash
make demo-clean    # Remove demo resources
make kind-delete   # Delete the cluster
```
