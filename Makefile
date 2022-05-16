.PHONY: test
test:
	@echo "\n🛠️  Running unit tests..."
	go test ./...

.PHONY: build
build:
	@echo "\n🔧  Building Go binaries..."
	GOOS=darwin GOARCH=amd64 go build -o bin/admission-webhook-darwin-amd64 .
	GOOS=linux GOARCH=amd64 go build -o bin/admission-webhook-linux-amd64 .

.PHONY: docker-build
docker-build:
	@echo "\n📦 Building simple-kubernetes-webhook Docker image..."
	docker build -t simple-kubernetes-webhook:latest .

.PHONY: docker-push
docker-push:
	@echo "\n📦 Pushing simple-kubernetes-webhook Docker image to hub.docker..."
	docker tag simple-kubernetes-webhook docker.io/jinqin2003/simple-kubernetes-webhook
	docker push jinqin2003/simple-kubernetes-webhook

.PHONY: create-cert
create-cert:
	@echo "\n⚙️  Creating cert-manager selfsigned CA..."
	kubectl apply -f dev/manifests/cert-manager/

.PHONY: delete-cert
delete-cert:
	@echo "\n⚙️  Deleting cert-manager selfsigned CA..."
	kubectl delete -f dev/manifests/cert-manager/selfsigned-ca.yaml

.PHONY: deploy-config
deploy-config:
	@echo "\n⚙️  Applying cluster config..."
	kubectl apply -f dev/manifests/cluster-config/

.PHONY: delete-config
delete-config:
	@echo "\n♻️  Deleting Kubernetes cluster config..."
	kubectl delete -f dev/manifests/cluster-config/

.PHONY: copy-secrets
copy-secrets:
	@echo "\n🚀 Copying secret simple-kubernetes-webhook-tls..."
	kubectl get secret simple-kubernetes-webhook-tls --namespace cert-manager -oyaml | grep -v '^\s*namespace:\s' | kubectl apply --namespace default -f -
	kubectl get secret simple-kubernetes-webhook-tls --namespace cert-manager -oyaml | grep -v '^\s*namespace:\s' | kubectl apply --namespace apps -f -

.PHONY: delete-secrets
delete-secrets:
	@echo "\n🚀 Deleting secrets ..."
	kubectl delete secret simple-kubernetes-webhook-tls --namespace default
	kubectl delete secret simple-kubernetes-webhook-tls --namespace apps

.PHONY: deploy
deploy: deploy-config
	@echo "\n🚀 Deploying simple-kubernetes-webhook..."
	kubectl apply -f dev/manifests/webhook/

.PHONY: delete
delete:
	@echo "\n♻️  Deleting simple-kubernetes-webhook deployment if existing..."
	kubectl delete -f dev/manifests/webhook/ || true

.PHONY: pod
pod:
	@echo "\n🚀 Deploying test pod..."
	kubectl apply -f dev/manifests/pods/lifespan-seven.pod.yaml

.PHONY: delete-pod
delete-pod:
	@echo "\n♻️ Deleting test pod..."
	kubectl delete -f dev/manifests/pods/lifespan-seven.pod.yaml

.PHONY: bad-pod
bad-pod:
	@echo "\n🚀 Deploying \"bad\" pod..."
	kubectl apply -f dev/manifests/pods/bad-name.pod.yaml

.PHONY: delete-bad-pod
delete-bad-pod:
	@echo "\n🚀 Deleting \"bad\" pod..."
	kubectl delete -f dev/manifests/pods/bad-name.pod.yaml

.PHONY: taint
taint:
	@echo "\n🎨 Taining Kubernetes node.."
	kubectl taint nodes kind-control-plane "acme.com/lifespan-remaining"=4:NoSchedule

.PHONY: logs
logs:
	@echo "\n🔍 Streaming simple-kubernetes-webhook logs..."
	kubectl logs -l app=simple-kubernetes-webhook -f

.PHONY: delete-all
delete-all: delete delete-config delete-pod delete-bad-pod
