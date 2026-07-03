---
title: "Azure 클라우드 인프라 및 M365 Defender 보안 구축"
date: 2026-06-01
categories:
  - project
comments: true
tags:
  - azure
  - terraform
---

## 프로젝트 개요

- **기간**: 2026.05.13 ~ 05.19 (경기인력개발원)
- **역할**: Azure 인프라 설계, Terraform 코드 작성 및 자동화
- **목표**: 고가용성 고려한 설계 + GUI 대신 코드(Terraform)로 완전 자동화
- **기술**: Terraform · AzureRM Provider · Application Gateway(WAF) · VMSS · Site-to-Site VPN · Azure Bastion · Traffic Manager · MySQL · Bluemax 방화벽

> 📝 M365 Defender 파트는 별도 정리 예정

---

## 아키텍처 (1차 → 3차)

- **1차**: Site-to-Site VPN 기본 구조 → 단일 Hub라 장애에 취약
- **2차**: 리전별 Hub 이중화 + Front Door 도입 → 규모 대비 과도하게 복잡
- **3차(최종)**: Front Door 제거, **Traffic Manager**로 단순화. 양 리전(Korea Central/South) 대칭 구성으로 이중화 완성

> 🖼️ *사진 자리 — 최종 아키텍처 구성도*

---

## Terraform 자동화

- 파일 역할별 분리: `init`(Provider) → `rg` → `vnet` → `subnet` → `pubip`
- 서브넷은 `default_outbound_access_enabled`로 NAT Gateway 경유 강제 (App GW만 예외)
- App GW WAF_v2는 공인 IP `Standard` SKU 필수 (Basic 쓰면 배포 오류 — 직접 겪음)
- **Bootstrap 단계 분리**: Key Vault·Storage Account는 별도 초기화로 민감정보 로컬 노출 방지
- 배포 방식은 Golden Image 대신 `install.sh` 부트스트랩 스크립트 채택 (Terraform 단일 실행 자동화가 목표라서)

> 🖼️ *사진 자리 — Terraform 폴더 구조 / apply 결과*

---

## 보안 구성

- Application Gateway + WAF, NSG(서브넷별 접근 제어), Azure Bastion(공인 IP 없는 관리 접속)
- Bluemax 방화벽으로 온프레미스 DB 연동 구간 정책 수립
- Key Vault + Managed Identity로 DB 계정 정보 분리

---

## 트러블슈팅

- MySQL Charset 미지원 → 지원 Charset 변경
- NIC 생성 실패(IP-서브넷 불일치) → 서브넷 재설계
- VPN 실패(IPSec 불일치) → 암호화 정책·PSK 재설정
- 민감정보 평문 저장 → Key Vault 적용

---

## 검증

VPN은 Azure·온프레미스 양쪽 로그로 교차 확인(`Connected`/`ESTABLISHED`, 실제 트래픽 통과까지 확인). 그 외 DB 연동, WAF, Auto Scaling, Traffic Manager Failover, Key Vault, Private DNS까지 **9개 항목 전부 정상 동작** 확인.

> 🖼️ *사진 자리 — VPN 연결 상태 화면 / Failover 테스트 화면*

---

## 회고

- "그럴듯한 구조"보다 **규모에 맞는 단순화**가 더 안정적이었다 (Front Door 제거 사례)
- Terraform + Key Vault로 코드-비밀정보 분리 습관을 익혔다
- 로그를 한쪽만 보지 않고 양쪽에서 교차 검증하는 습관을 들였다
