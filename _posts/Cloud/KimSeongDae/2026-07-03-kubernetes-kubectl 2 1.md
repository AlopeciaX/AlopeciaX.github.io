---
title: kubectl 기초 실습 정리
date: 2026-07-03
categories:
  - cloud
comments: true
tags:
  - kubernetes
---
---
로드밸런서 설치

```bash
kubectl get configmap kube-proxy -n kube-system -o yaml | \
sed -e "s/strictARP: false/strictARP: true/" | \
kubectl diff -f - -n kube-system
```

