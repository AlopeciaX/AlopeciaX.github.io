---
title: 쿠버네티스 kubectl
date: 2026-06-26
categories:
  - cloud
comments: true
tags:
  - kubernetes
---
---
## 개요

kubectl은 Kubernetes 클러스터를 제어하는 CLI 도구다. 이 글은 노드/파드/서비스/네임스페이스 기본 조작과 YAML로 리소스를 생성하는 실습 내용을 정리한다.

---

## 주요 개념

- **kubectl**: Kubernetes object를 실행·관리하는 CLI. [kubectl cheat sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/) 참고
- **Calico**: 파드 간 네트워크를 구성하는 CNI 플러그인
- **Namespace**: 하나의 클러스터 안에서 리소스 그룹을 논리적으로 분리하는 단위. 팀·환경별로 나눠 사용 가능
- **YAML 구조**: `인자값: 값` 형식. 주요 키는 `apiVersion`, `kind`, `metadata`(name, labels, env), `spec`

---

## STEP 1 — 클러스터 상태 확인

bash

```bash
kubectl get nodes          # 노드 목록
kubectl get namespaces     # 네임스페이스 목록 (= kubectl get ns)
kubectl get pods           # 기본 네임스페이스 파드 목록
kubectl get pods -A        # 전체 네임스페이스 파드 목록
kubectl api-resources      # 리소스 종류 확인 (shortnames, kind 포함)
```

---

## STEP 2 — 파드 실행 및 확인

bash

```bash
# 파드 생성
kubectl run app-nginx --image nginx --port 80

# 상태 확인
kubectl get pods
kubectl get pods app-nginx
kubectl get pods app-nginx -o wide    # IP 등 상세 정보 포함

# 상세 정보 / 로그
kubectl describe pods app-nginx
kubectl logs app-nginx
```

> `kubectl get pods app-nginx -o wide` 로 확인한 IP로 `curl` 테스트 가능  
> (단, 클러스터 내부 IP이므로 노드에서만 접근됨)

---

## STEP 3 — 서비스(NodePort) 노출

bash

```bash
kubectl expose pod app-nginx --type NodePort
kubectl get services
kubectl delete service app-nginx
```

NodePort를 사용하면 클러스터 외부에서 `노드IP:포트`로 파드에 접근할 수 있다.

---

## STEP 4 — 네임스페이스 관리

bash

```bash
# 조회
kubectl get namespace          # = kubectl get ns

# 특정 네임스페이스 파드 조회
kubectl get pods --namespace kube-system
kubectl get pods --namespace kube-public

# 생성 / 삭제
kubectl create namespace 1team
kubectl delete ns 1team

# 네임스페이스 지정하여 파드 실행
kubectl run app-nginx --image nginx --port 80 --namespace 1team

# 파드 삭제 (네임스페이스 명시 필수)
kubectl delete po app-nginx --namespace 1team
```

> `default` 네임스페이스는 삭제 불가

---

## STEP 5 — YAML로 리소스 생성

bash

```bash
mkdir /pod && cd /pod
vi ns1.yml
```

**ns1.yml 예시**

yaml

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: 1team
  labels:
    env: study
```

bash

```bash
kubectl apply -f ns1.yml      # 생성
kubectl get ns --show-labels  # 라벨 포함 확인
kubectl delete -f ns1.yml     # 삭제
```

---

## 요약

| 작업        | 명령어                                                          |
| --------- | ------------------------------------------------------------ |
| 파드 생성     | `kubectl run <이름> --image <이미지> --port <포트>`                 |
| 서비스 노출    | `kubectl expose pod <이름> --type NodePort`                    |
| 네임스페이스 지정 | `--namespace <이름>` 또는 `-n <이름>`                              |
| YAML 적용   | `kubectl apply -f <파일>.yml`                                  |
| 리소스 삭제    | `kubectl delete -f <파일>.yml` 또는 `kubectl delete <kind> <이름>` |

docker clone 생성
ip 21번

dnf -y install dnf-plugins-core
dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
dnf -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

systemctl enable --now docker
docker pull nginx
dpcler pull httpd
docker pull alpine
docker pull busybox
docker pull rockylinux/rockylinux
docker pull wordpress
docker pull mysql:8.0

clear
docker images

docker save -o all.tar alpine busybox httpd nginx rockylinux/rockylinux wordpress mysql:8.0
ls
ls -hal
scp all.tar root@10.0.0.12:/root/
scp all.tar root@10.0.0.13:/root/
