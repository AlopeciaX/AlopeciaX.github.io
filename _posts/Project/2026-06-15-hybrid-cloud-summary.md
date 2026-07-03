---
title: "[요약] 하이브리드 클라우드 보안 구축 프로젝트"
date: 2026-06-15
categories:
  - project
comments: true
tags:
  - azure
  - terraform
  - 요약
---
---
## 프로젝트 목표

앞선 그룹웨어 프로젝트의 후속으로, **온프레미스 영역을 실제 기업 내부망 구조에 가깝게 구체화**하고 클라우드-온프레미스 간 보안 체계를 강화한다.

- L2·L3 스위치 기반 VLAN 분리로 사용자망/서버망/분석망 논리적 분리
- DB Server 접근 통제(iptables) + 중앙 로그 수집(rsyslog) + 로그 저장소 이중화(RAID1)
- 온프레미스 DB 백업을 Azure Storage로 자동 업로드 + Standby DB로 장애 대응

**기술 스택**: L2/L3 스위치 · iptables · rsyslog · RAID1 · Docker(ELK) · Azure Key Vault · Managed Identity · Azure Storage · Azure Database for MySQL

---

## 아키텍처

> 🖼️ *사진 자리 — 온프레미스 네트워크 구성도(VLAN10/20/30/40/50) + Azure 연동 구조 1장*

| VLAN | 대역 | 용도 |
|---|---|---|
| VLAN10 | 192.168.1.0/24 | 사용자망 |
| VLAN20 | 192.168.2.0/24 | 관리/사용자망 |
| VLAN30 | 192.168.3.0/29 | 서버망 (DB/Log Server) |
| VLAN40 | 192.168.4.0/30 | 분석망 |
| VLAN50 | 192.168.11.0/30 | 방화벽 연동망 |

---

## 핵심 성과

- iptables 기본 정책을 **DROP**으로 두고, 허용된 관리 PC·Azure 대역만 접근 가능하도록 최소 권한 원칙 적용
- Log Server를 **RAID1**로 구성해 단일 디스크 장애에도 로그 보존
- **Key Vault + Managed Identity**로 DB 백업 스크립트에 비밀번호를 하드코딩하지 않는 구조 구현
- `cron` 기반 매일 자동 백업 + 7일 지난 백업 자동 삭제 + **Standby DB 전환** 경로 확보

---

## 트러블슈팅 (설계 관점)

| 이슈 | 대응 |
|---|---|
| 서버망을 다른 VLAN과 어떻게 분리할지 | VLAN30(서버망)을 별도 분리하고 L3 스위치에서 Gateway 역할 부여 |
| 백업 스크립트에 민감정보를 어떻게 관리할지 | Key Vault Secret 조회 방식으로 전환, 코드에 평문 저장 금지 |
| 로그가 유실되면 감사 추적이 불가능한 문제 | RAID1 + rsyslog 중앙 수집으로 이중 안전장치 마련 |

---

## 느낀점

방화벽 하나로 "보안이 됐다"고 넘어가지 않고, **네트워크 분리 → 접근 제어 → 로그 수집 → 백업/장애 대응**까지 계층별로 보안을 쌓아 올리는 경험을 했다. 특히 "백업을 한다"는 것 자체보다 "백업에 쓰이는 정보를 어떻게 안전하게 관리할지"까지 고민한 게 이번 프로젝트에서 가장 남는 부분이다.

---

## 상세 포스트

- [1편 — 온프레미스 네트워크 & 중앙 로그 수집]({% post_url 2026-06-15-hybrid-cloud-01 %})
- [2편 — DB 백업 자동화 & Key Vault / Azure Storage]({% post_url 2026-06-16-hybrid-cloud-02 %})
