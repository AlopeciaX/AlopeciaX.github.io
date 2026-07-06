---
title: kubadm 사전 준비 스크립트
date: 2026-07-01
categories:
  - cloud
comments: true
tags:
  - kubernetes
---
---
## 개요

kubeadm으로 클러스터를 구성하기 전, 전체 노드(마스터/워커)에 공통으로 적용하는 사전 준비 스크립트와, `kubeadm join` 시 필요한 CA 인증서 해시를 수동으로 확인하는 명령을 정리한다.

---

## 사전 준비 스크립트 (전체 노드 공통)

bash

```bash
#!/bin/bash

setenforce 0
grubby --update-kernel ALL --args selinux=0
systemctl disable --now firewalld
timedatectl set-timezone Asia/Seoul

# Master
# firewall-cmd --add-port={80,443,6443,2379,2380,10250,10251,10252,30000-32767}/tcp --permanent

# Node
# firewall-cmd --add-port={80,443,10250,30000-32767}/tcp --permanent

# swap off
swapoff -a
sed -i '/swap/ s/^\(.*\)$/#\1/g' /etc/fstab

# overlay 및 iptables Module Load
cat > /etc/modules-load.d/k8s.conf << EOF
overlay
br_netfilter
EOF
modprobe overlay
modprobe br_netfilter

# iptables 및 NAT 활성화
cat > /etc/sysctl.d/k8s.conf << EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF
sysctl --system
```

**스크립트 동작 요약**

- `setenforce 0` / `grubby --update-kernel`: SELinux를 즉시 비활성화하고, 재부팅 후에도 비활성 상태가 유지되도록 커널 파라미터에 반영
- `firewalld` 비활성화: 테스트 환경 기준. 운영 환경에서는 주석 처리된 `firewall-cmd` 라인처럼 필요한 포트만 열어서 사용
- `swapoff -a` + `/etc/fstab` swap 라인 주석 처리: kubelet은 swap이 켜져 있으면 정상 동작하지 않으므로 재부팅 후에도 꺼진 상태를 유지시킴
- `overlay`, `br_netfilter` 모듈 로드: 컨테이너 네트워킹(오버레이 네트워크, 브리지 트래픽 필터링)에 필요
- `net.bridge.bridge-nf-call-iptables`, `net.ipv4.ip_forward` 등: 파드 간 통신 및 iptables 기반 트래픽 처리를 위한 커널 설정

---

## CA 인증서 해시 확인 (kubeadm join용)

bash

```bash
openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | \
  openssl rsa -pubin -outform der 2>/dev/null | \
  openssl dgst -sha256 -hex | \
  sed 's/^.* //'
```

`kubeadm join` 명령에 필요한 `--discovery-token-ca-cert-hash sha256:<해시>` 값을 마스터 노드에서 직접 계산하는 명령이다. `kubeadm token create --print-join-command`로 join 명령 전체를 재발급받을 수도 있지만, 토큰만 새로 만들고 해시값만 별도로 확인하고 싶을 때 이 명령을 사용한다.

---

## 원본에서 수정한 부분

- 한 줄로 붙어 있던 사전 준비 스크립트를 원래의 여러 줄 형태로 복원 (가독성 및 실제 실행 가능 여부 확보)
- `net.ipv4.ip_forward =1` → `net.ipv4.ip_forward = 1`로 등호 앞뒤 공백 통일
- 제목 없이 코드 블록만 있던 구조에 개요와 각 명령의 목적 설명 추가
