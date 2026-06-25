---
title:
date: 2026-06-22
categories:
  - cloud
comments: true
tags:
  - docker
---
---
master         |    node1 node2

master node        worknode

=> k8s kubernetes

kubernetes에서 물리적인 가장 작은단위는 컨테이너가 아닌 파드(pod)이다.
가급적 하나의 파드안에서는 하나의 컨테이너만 실행

volume을 갖다 붙이는이유: 컨테이너와 데이터라이프스타일을 다르게 하기 위해서