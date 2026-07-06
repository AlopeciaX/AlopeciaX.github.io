---
title: Pod 개념 정리
date: 2026-07-02
categories:
  - cloud
comments: true
tags:
  - kubernetes
---
---
## 개요

Kubernetes에서 가장 작은 배포 단위인 Pod에 대해 다시 정리한다.

---

## Pod란

- Kubernetes에서 생성·관리할 수 있는 가장 작은 단위. 컨테이너를 직접 배포하지 않고 Pod 단위로 배포한다.
- 하나의 Pod 안에 여러 컨테이너를 넣을 수 있지만, 가급적 하나의 Pod에는 하나의 컨테이너만 두는 것을 권장한다.
- 같은 Pod 안의 컨테이너들은 네트워크(IP, 포트)와 스토리지(볼륨)를 공유한다.
- Pod는 재시작되어도 같은 개체로 취급되지 않는다. 기존 Pod가 죽으면 새 Pod가 생성되며, 이때 Pod IP도 바뀐다. → 그래서 Service로 고정 진입점을 만들어야 한다 (07-06 글 참고).

---

## 자주 쓰는 kubectl 명령

bash

```bash
# Pod 생성 (명령형)
kubectl run <이름> --image <이미지> --port <포트>

# 목록/상세 확인
kubectl get pods
kubectl get pods -o wide
kubectl describe pod <이름>

# 로그/접속
kubectl logs <이름>
kubectl exec -it <이름> -- /bin/bash

# 삭제
kubectl delete pod <이름>
```