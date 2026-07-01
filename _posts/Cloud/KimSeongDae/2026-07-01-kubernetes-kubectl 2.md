---
title: kubectl 기초 실습 정리
date: 2026-07-01
categories:
  - cloud
comments: true
tags:
  - kubernetes
---
---

```bash
#! /bin/bash setenforce 0 grubby --update-kernel ALL --args selinux=0 systemctl disable --now firewalld timedatectl set-timezone Asia/Seoul # Master # firewall-cmd --add-port={80,443,6443,2379,2380,10250,10251,10252,30000-32767}/tcp --permanent # Node # firewall-cmd --add-port={80,443,10250,30000-32767}/tcp --permanent # swap off swapoff -a sed -i '/swap/ s/^\(.*\)$/#\1/g' /etc/fstab # overlay 및 iptables Module Load cat > /etc/modules-load.d/k8s.conf << EOF overlay br_netfilter EOF modprobe overlay modprobe br_netfilter # iptables 및 NAT 활성화 cat > /etc/sysctl.d/k8s.conf << EOF net.bridge.bridge-nf-call-ip6tables = 1 net.bridge.bridge-nf-call-iptables = 1 net.ipv4.ip_forward =1 EOF sysctl --system
```

```bash
openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | \ openssl rsa -pubin -outform der 2>/dev/null | \ openssl dgst -sha256 -hex | \ sed 's/^.* //'
```
