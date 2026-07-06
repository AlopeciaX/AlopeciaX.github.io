---
title: kubectl 기초 실습 정리
date: 2026-07-06
categories:
  - cloud
comments: true
tags:
  - kubernetes
---
---
## Ingress

무중단 배포

1.블루, 그린 배포
![](../../../assets/images/Cloud/KimSeongDae/2026-07-06-kubernetes-kubectl%202%201%201/file-20260706093445190.png)


2.롤링 업데이트

![](../../../assets/images/Cloud/KimSeongDae/2026-07-06-kubernetes-kubectl%202%201%201/file-20260706093424202.png)

3.카나리아

![](../../../assets/images/Cloud/KimSeongDae/2026-07-06-kubernetes-kubectl%202%201%201/file-20260706093536467.png)

```bash
apiVersion: apps/v1
kind: Deployment
metadata:
  name: dep-nginx
  labels:
    app: nginx
    env: devel
spec:
  replicas: 4
  selector:
    matchLabels:
      tem: nginx
  template:
    metadata:
      name: tem-nginx
      labels:
        tem: nginx
    spec:
      containers:
      - name: n1
        image: nginx:1.14
        imagePullPolicy: Never
        ports:
        - containerPort: 80
        resources:
          limits:
            cpu: "200m"
            memory: "200Mi"
          requests:
            cpu: "100m"
            memory: "100Mi"
```