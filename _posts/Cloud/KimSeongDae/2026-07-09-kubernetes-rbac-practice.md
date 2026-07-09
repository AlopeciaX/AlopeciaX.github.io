---
title: kubectl 실습 - Namespace 분리 및 RBAC 권한 설정
date: 2026-07-09
categories:
  - cloud
comments: true
tags:
  - kubernetes
  - rbac
---
---

## 시나리오

회사(`gogle`) 안에 `admin`팀, `sales`팀이 있고, 각 팀은 팀장/팀원 계정을 가진다.
쿠버네티스에서는 이걸 아래처럼 매핑해서 실습했다.

| 리눅스 개념 | 쿠버네티스 개념 |
|---|---|
| 회사 전체 | 클러스터 |
| 팀 (admin/sales) | Namespace |
| 사용자 계정 (a,b,c,d) | ServiceAccount |
| 팀장 / 팀원 권한 차이 | Role의 edit / view 권한 |

- `a`(admin팀 팀원), `b`(admin팀 팀장)
- `c`(sales팀 팀원), `d`(sales팀 팀장)
- 팀장은 자기 팀 Namespace에서 리소스 생성/수정 가능(edit), 팀원은 조회만 가능(view)
- 다른 팀 Namespace는 서로 접근 불가

## Namespace 생성

```bash
kubectl create namespace admin
kubectl create namespace sales
kubectl get namespaces
```

## ServiceAccount 생성

```bash
kubectl create serviceaccount a -n admin
kubectl create serviceaccount b -n admin
kubectl create serviceaccount c -n sales
kubectl create serviceaccount d -n sales
```

## Role / RoleBinding 설정 (admin 팀)

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: admin-viewer
  namespace: admin
subjects:
- kind: ServiceAccount
  name: a
  namespace: admin
roleRef:
  kind: ClusterRole
  name: view
  apiGroup: rbac.authorization.k8s.io
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: admin-editor
  namespace: admin
subjects:
- kind: ServiceAccount
  name: b
  namespace: admin
roleRef:
  kind: ClusterRole
  name: edit
  apiGroup: rbac.authorization.k8s.io
```

```bash
kubectl apply -f admin-rolebinding.yml
```

## Role / RoleBinding 설정 (sales 팀)

같은 구조를 `sales` Namespace에도 그대로 적용한다.

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: sales-viewer
  namespace: sales
subjects:
- kind: ServiceAccount
  name: c
  namespace: sales
roleRef:
  kind: ClusterRole
  name: view
  apiGroup: rbac.authorization.k8s.io
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: sales-editor
  namespace: sales
subjects:
- kind: ServiceAccount
  name: d
  namespace: sales
roleRef:
  kind: ClusterRole
  name: edit
  apiGroup: rbac.authorization.k8s.io
```

```bash
kubectl apply -f sales-rolebinding.yml
```

## 검증

```bash
kubectl auth can-i create pods -n admin --as=system:serviceaccount:admin:a   # no (팀원)
kubectl auth can-i create pods -n admin --as=system:serviceaccount:admin:b   # yes (팀장)
kubectl auth can-i get pods -n sales --as=system:serviceaccount:admin:a      # no (다른 팀 접근 불가)
```

## 정리

- Namespace로 팀 단위 리소스를 분리하고, RBAC(Role/RoleBinding)으로 같은 팀 안에서도 직급별 권한 차이를 줄 수 있었다.
- `ClusterRole`(view/edit는 쿠버네티스 기본 제공)을 그대로 재사용하고 `RoleBinding`으로 Namespace에 한정시키는 방식이 커스텀 Role을 만드는 것보다 간단했다.
