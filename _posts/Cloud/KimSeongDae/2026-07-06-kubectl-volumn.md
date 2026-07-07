---
title: 볼륨
date: 2026-07-07
categories:
  - cloud
comments: true
tags:
  - kubernetes
---
---

```bash
mkdir /vol
cd /vol
```

```
#vi nginx.yml
apiVersion: v1
kind: Pod
metadata:
  name: nginx
  labels:
    app: nginx
    env: devel
spec:
containers:
- name: n1
  image: nginx
  imagePullPolicy: IfNotPresent
  ports:
  - containerPort: 80
    volumeMounts:
    -mountPath: /test1
    name: jhjang-vol
    volumes:
    -name: jhjang-vol
    emptydir: {}
```