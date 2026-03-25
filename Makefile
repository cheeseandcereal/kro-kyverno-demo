KIND_CLUSTER_NAME ?= kro-kyverno-demo
KRO_VERSION ?= 0.9.0
KYVERNO_VERSION ?= 3.7.1

KUBECTL ?= kubectl
HELM ?= helm
KIND ?= kind

##@ Cluster

.PHONY: cluster
cluster: kind-create install-kro install-kyverno ## Create kind cluster with kro and kyverno
	@echo "Cluster '$(KIND_CLUSTER_NAME)' is ready with kro $(KRO_VERSION) and kyverno $(KYVERNO_VERSION)"

.PHONY: kind-create
kind-create: ## Create a kind cluster
	$(KIND) create cluster --name $(KIND_CLUSTER_NAME) --wait 5m

.PHONY: kind-delete
kind-delete: ## Delete the kind cluster
	$(KIND) delete cluster --name $(KIND_CLUSTER_NAME)

##@ Install

.PHONY: install-kro
install-kro: ## Install kro via helm
	$(HELM) install kro oci://registry.k8s.io/kro/charts/kro \
		--namespace kro-system --create-namespace \
		--version $(KRO_VERSION) \
		--wait

.PHONY: install-kyverno
install-kyverno: ## Install kyverno via helm
	$(HELM) repo add kyverno https://kyverno.github.io/kyverno/ || true
	$(HELM) repo update kyverno
	$(HELM) install kyverno kyverno/kyverno \
		--namespace kyverno --create-namespace \
		--version $(KYVERNO_VERSION) \
		--wait

##@ Demo

.PHONY: demo-setup
demo-setup: ## Create namespaces and apply the RGD + instance
	$(KUBECTL) create namespace production-1 --dry-run=client -o yaml | $(KUBECTL) apply -f -
	$(KUBECTL) create namespace production-2 --dry-run=client -o yaml | $(KUBECTL) apply -f -
	$(KUBECTL) apply -f manifests/rgd.yaml
	@echo "Waiting for CRD to be established..."
	@sleep 5
	$(KUBECTL) apply -f manifests/instance.yaml

.PHONY: demo-test
demo-test: ## Apply resource quotas to test the budget policy
	$(KUBECTL) apply -f manifests/rq-1.yaml
	$(KUBECTL) apply -f manifests/rq-2.yaml

.PHONY: demo-clean
demo-clean: ## Remove demo resources
	-$(KUBECTL) delete -f manifests/rq-2.yaml
	-$(KUBECTL) delete -f manifests/rq-1.yaml
	-$(KUBECTL) delete -f manifests/instance.yaml
	-$(KUBECTL) delete -f manifests/rgd.yaml

##@ Uninstall

.PHONY: uninstall-kro
uninstall-kro: ## Uninstall kro
	$(HELM) uninstall kro --namespace kro-system

.PHONY: uninstall-kyverno
uninstall-kyverno: ## Uninstall kyverno
	$(HELM) uninstall kyverno --namespace kyverno

##@ Helpers

.PHONY: help
help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

.DEFAULT_GOAL := help
