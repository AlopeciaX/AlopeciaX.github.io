---
title: 하이브리드 클라우드 보안 구축 (1) — 온프레미스 네트워크 & 중앙 로그 수집
date: 2026-06-15
categories:
  - project
comments: true
tags:
  - azure
  - terraform
---
---
## 개요

앞선 프로젝트(Azure + Terraform 그룹웨어 구축)의 후속으로, **온프레미스 영역을 실제 기업 내부망 구조에 가깝게 구체화**하는 프로젝트. 기존에는 방화벽+DB 서버 중심의 단순 구조였다면, 이번에는 L2/L3 스위치 기반 VLAN 분리, DB 접근 통제, 중앙 로그 수집, 백업/장애 대응 체계까지 추가로 구성했다.

**핵심 키워드**: L2/L3 스위치 VLAN 분리 · iptables 접근 제어 · rsyslog 중앙 로그 수집 · RAID1 · ELK(Docker)

---

## 온프레미스 네트워크: L2·L3 스위치 기반 VLAN 분리

역할별로 네트워크를 분리하기 위해 L3 스위치(VLAN 간 라우팅/Gateway)와 L2 스위치(단말 Access 계층) 구조를 구성했다.

| 구분 | VLAN | 대역 | Gateway | 용도 |
|---|---|---|---|---|
| 사용자망 | VLAN10 | 192.168.1.0/24 | 192.168.1.254 | 일반 사용자 단말 |
| 관리/사용자망 | VLAN20 | 192.168.2.0/24 | 192.168.2.254 | 관리 및 내부 통신 |
| 서버망 | VLAN30 | 192.168.3.0/29 | 192.168.3.1 | DB Server, Log Server, 관리 PC |
| 분석망 | VLAN40 | 192.168.4.0/30 | 192.168.4.1 | 트래픽 분석/모니터링 |
| 방화벽 연동망 | VLAN50 | 192.168.11.0/30 | 192.168.11.2 | L3 스위치 ↔ BlueMax 방화벽 |

> 🖼️ *사진 자리 — 온프레미스 네트워크 구성도 + 실제 사용한 L2·L3 스위치 장비 사진*

DB Server(192.168.3.2)와 Log Server(192.168.3.3)를 같은 **VLAN30 서버망**에 배치하되, 다른 사용자 VLAN과는 논리적으로 분리했다. Azure ↔ 온프레미스 Site-to-Site VPN 트래픽은 BlueMax 방화벽 → L3 스위치를 거쳐 VLAN30으로 전달되도록 구성했다.

> 🖼️ *사진 자리 — L3 스위치 VLAN Interface 설정 화면 (VLAN40/50 Access Port 설정, Trunk Port 설정, show switchport 결과)*

## DB Server 접근 제어 (iptables)

- 기본 INPUT 정책: **DROP**
- 허용: 관리 PC의 SSH 접속, Azure Web Server 대역의 MySQL(3306) 접근만
- 그 외 모든 접근 시도는 `IPTABLES_DROP` 로그로 기록 후 차단

> 🖼️ *사진 자리 — DB Server iptables 접근 제어 정책 설정 화면*

## 중앙 로그 수집 & RAID1

- Log Server에 5GB 디스크 2개를 추가해 **RAID1**로 구성 → `/dev/md0`를 `/var/log/remote`에 마운트해 단일 디스크 장애에도 로그 보존
- DB Server / 방화벽에서 발생하는 iptables 차단 로그를 `rsyslog`로 Log Server에 중앙 전송해, 비정상 접근 시도 추적과 보안 감사가 가능하도록 구성

> 🖼️ *사진 자리 — Log Server RAID1 구성 확인 화면 (mdadm 상태) + /var/log/remote 마운트 확인 화면*

## ELK 기반 웹 로그 수집 (Docker)

- `docker-compose`로 Elasticsearch, Logstash, Kibana 컨테이너를 구성
- `docker ps`로 3개 컨테이너 정상 기동 확인 후, 웹 서버 로그를 ELK로 수집해 시각화

> 🖼️ *사진 자리 — docker-compose.yml 화면 + docker ps 실행 결과 화면 + Kibana 대시보드 화면*

---

## 정리

- 방화벽 하나로 막연히 "보안이 됐다"고 넘어가지 않고, **VLAN 분리 → 접근 제어(iptables) → 로그 수집(rsyslog+RAID1) → 시각화(ELK)**까지 계층별로 보안을 구성한 게 이번 단계의 핵심이었다.
- 특히 로그 저장소를 RAID1로 이중화해둔 덕분에, "로그가 남았는지"뿐 아니라 "로그를 안전하게 보존할 수 있는지"까지 고려했다.
