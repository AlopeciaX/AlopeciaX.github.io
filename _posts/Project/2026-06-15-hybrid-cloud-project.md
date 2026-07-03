---
title: 하이브리드 클라우드 보안구축
date: 2026-06-15
categories:
  - project
comments: true
tags:
  - azure
  - terraform
  - 온프레미스
---
---

> 4인 팀 프로젝트 · 경기인력개발원 · 2026.05.20 ~ 06.08 담당: Terraform 코드 작성 및 자동화, DB 이중화, L2 스위치 설정

## 한눈에 보는 결과

- 온프레미스 네트워크 — L2 스위치 2대 + L3 스위치 + Bluemax 방화벽, VLAN 5개로 역할 분리
- DB 이중화 — 온프레미스 MySQL(Source) ↔ Azure MySQL(Replica) 실시간 복제, 지연 0초
- 장애 대응 — 온프레미스 DB 장애 시 Azure DB로 수동 Failover 검증 완료
- 로그 수집 — ELK Stack으로 웹 로그 시각화, X-Forwarded-For로 실접속자 IP 식별
- Azure 연동 — Site-to-Site VPN으로 온프레미스-Azure 두 리전 연결, Terraform으로 자동화

> 📝 앞선 "Azure 클라우드 인프라" 프로젝트의 후속 — 온프레미스 영역을 실제 기업 내부망 구조로 구체화하고, 이전 프로젝트에서 부족했던 로그 분석·DB 이중화를 보완

---

## 온프레미스 네트워크

- L2 스위치 2대 + L3 스위치 + Bluemax 방화벽으로 내부망 구성
- VLAN10/20/30/40/50으로 역할별 분리
- 보안 담당자 PC만 다른 VLAN 접속 허용, 나머지는 접근 차단
- 각 스위치에 Hostname, 배너, NTP, Syslog, VLAN, ACL 설정 적용

**VLAN 구성**

- VLAN10: 192.168.1.0/24 — 사용자망
- VLAN20: 192.168.2.0/24 — 관리/사용자망
- VLAN30: 192.168.3.0/29 — 서버망(DB/Log Server)
- VLAN40: 192.168.4.0/30 — 분석망
- VLAN50: 192.168.11.0/30 — 방화벽 연동망

> 🖼️ _사진 자리 — 온프레미스 네트워크 구성도, L3 스위치 VLAN 설정 화면_

---

## 방화벽 정책

- 최소 권한 원칙 적용: 내부 사용자 인터넷 허용, Azure DB 연동, Kibana 접근 통제 등 필요한 트래픽만 허용
- 방화벽 로그는 로그 서버로 전송해 중앙 수집

---

## DB 이중화 — 이번 프로젝트 핵심

- 온프레미스 MySQL DB를 **Source**로, Azure MySQL Flexible Server를 **Replica**로 구성
- 실시간 데이터 복제 구현, **복제 지연 시간 0초** 달성
- 온프레미스 DB 장애 시 Azure DB로 전환하는 **수동 Failover 검증 성공**
- DB 백업은 매일 새벽 3시 Azure Storage로 자동 저장, 최대 7일치 보관

> 🖼️ _사진 자리 — DB 복제 상태 확인 화면, Failover 테스트 화면_

---

## 로그 수집 및 분석

- ELK Stack으로 Azure VMSS 웹 서버 로그를 중앙 수집, Kibana로 시각화
- X-Forwarded-For 헤더 적용 → 실제 접속자 IP 식별 가능
- WordPress 관리자 페이지 접근 시도 등 보안 이벤트 실시간 탐지
- 온프레미스 DB 서버는 iptables 정책 적용 + rsyslog로 로그 서버 전송

> 🖼️ _사진 자리 — Kibana 대시보드, 보안 이벤트 탐지 화면_

---

## Azure 연동

- Site-to-Site VPN으로 온프레미스 ↔ Azure 두 리전(Korea Central/South) 연결
- 멀티리전 이중화 구조를 Terraform으로 자동화
- Traffic Manager로 DNS 기반 글로벌 라우팅 + Failover 구성

---

## 트러블슈팅

- DB 이중화 초기 설정 시 복제 지연 발생 → 설정 튜닝으로 지연 0초 달성
- 방화벽 정책 과다 허용 우려 → 최소 권한 원칙으로 재설계

---

## 인프라 동작 순서

1. 사용자 PC → L2 스위치 → L3 스위치 → Bluemax 방화벽
2. 방화벽에서 정책 통과한 트래픽만 → Site-to-Site VPN → Azure
3. 웹 요청 로그는 실시간으로 ELK Stack → Kibana 시각화
4. DB 쓰기는 온프레미스(Source) → Azure(Replica)로 실시간 복제
5. 온프레미스 DB 장애 시 → Azure DB로 수동 전환

---

## 회고

- 방화벽 하나로 "보안이 됐다"고 넘어가지 않고, 네트워크 분리 → 접근 제어 → 로그 수집 → DB 이중화까지 계층별로 직접 쌓아 올렸다
- 복제 지연 0초를 직접 달성하고, Failover까지 눈으로 검증한 게 가장 남는 경험이다
- 이전 프로젝트(Azure 인프라)에서 부족했던 "온프레미스 디테일"과 "DB 이중화"를 이번에 실제로 보완했다

**다음 개선 계획**

- 자동 Failover(현재는 수동) 구현
- 온프레미스 네트워크 장비 이중화