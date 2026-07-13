---
title: 5. Azure 클라우드 행위기반 보안탐지 및 대응
date: 2026-07-20
categories:
  - project
comments: true
tags:
  - azure
  - terraform
  - security
  - cdr
  - project
---
---
## 개요

이전 프로젝트(App 보안 설계)에서 구축한 WAF·Firewall·MySQL Entra ID 인증 기반 인프라 위에, 이번에는 **탐지·대응(Cloud Detection & Response)** 관점을 추가한 프로젝트. 웹쉘 업로드·SSRF·SQL Injection 공격을 재현하고, 이 공격들이 Azure Firewall/WAF/MySQL 로그에 어떻게 남는지 Microsoft Sentinel로 수집·분석해 실제 탐지·대응까지 이어지는 것을 목표로 진행중이다.

**핵심 키워드**: Microsoft Sentinel · Log Analytics Workspace · KQL 분석 규칙 · WAF/Firewall/MySQL 진단 로그 통합 · Incident 대응

---

## 아키텍처 개요

기존 프로젝트의 네트워크 구조(Web/DB/Bastion/Firewall 서브넷 분리, UDR 강제 경유, MySQL delegated subnet)를 그대로 재사용하고, 여기에 로그 수집·분석 계층을 얹었다.

- **Application Gateway (WAF_v2, Prevention 모드)**: OWASP CRS 3.2 + 업로드 폴더 PHP 실행 차단 커스텀 룰
- **Azure Firewall**: 아웃바운드 단일 출구, DNS Proxy로 VNet DNS 강제 경유
- **Azure Bastion (Standard)**: Entra ID 기반 SSH 로그인
- **MySQL Flexible Server**: Entra ID 전용 인증, Audit Log(CONNECTION/DDL/DML) 활성화
- **Log Analytics Workspace + Microsoft Sentinel**: Firewall/WAF/MySQL/구독 Activity 로그를 하나의 워크스페이스로 통합, Sentinel 온보딩까지 연결

📷 아키텍처 다이어그램 (예정)

---

## Terraform 인프라 구현

**Bootstrap 및 리소스 이름 관리**

- Key Vault·Storage Account를 이전과 동일하게 별도 리소스그룹(`team604tuna05-infra`)에 분리 배치
- 배포 중 Storage Account 이름(`tuna5tfstate604`)이 전역적으로 충돌해, `tuna05`로 전면 교체하고 리소스그룹명도 `team604tuna05`로 재배포

📷 Bootstrap 실행 및 Storage/Key Vault 생성 결과

**Log Analytics Workspace & Sentinel 온보딩**

- `tuna-law` 워크스페이스 생성, 보존기간 30일
- `daily_quota_gb = 1`로 일일 수집량 상한을 걸어 크레딧 소진 방지 (초과 시 다음날 UTC 00:00 자동 재개)
- `azurerm_sentinel_log_analytics_workspace_onboarding`으로 Sentinel(SecurityInsights) 활성화 — 이게 있어야 아래 진단 로그가 단순 저장을 넘어 분석 규칙/헌팅/인시던트 대상이 됨

📷 Log Analytics Workspace 및 Sentinel 온보딩 화면

**진단 설정(Diagnostic Settings) — 4개 소스 통합**

| 리소스 | 수집 로그/메트릭 |
|---|---|
| Azure Firewall | ApplicationRule, NetworkRule, DnsProxy 로그 + 전체 메트릭 |
| MySQL Flexible Server | SlowLogs, AuditLogs(CONNECTION/DDL/DML) + 전체 메트릭 |
| 구독 Activity Log | Administrative, Security 카테고리 |
| Application Gateway(WAF) | FirewallLog(SQLi/XSS 등 OWASP 매치 기록), AccessLog + 전체 메트릭 |

리소스 이름 재사용 시 진단 설정 이름 충돌이 발생할 수 있어, `100_run.sh`에 기존 로직대로 apply 실패 시 자동 import 후 재시도하는 절차를 그대로 유지했다.

📷 진단 설정 4종 적용 결과

**배포 자동화**

1. Bootstrap (Key Vault/Storage)
2. Terraform apply (네트워크/Firewall/Bastion/VM/MySQL/Log Analytics/Sentinel)
3. `az vm run-command invoke`로 MySQL AAD 사용자 자동 등록

📷 `100_run.sh` 전체 실행 로그 (Bootstrap → apply → DB 사용자 등록)

---

## 취약점 재현 (탐지 대상 시나리오)

이전 프로젝트에서 검증했던 세 가지 공격을, 이번에는 **"막았는가"가 아니라 "로그에 남는가/탐지되는가"** 관점으로 다시 배포했다.

- **웹쉘 업로드**: `/upload.php`로 파일 업로드 → `/uploads/*.php` 실행 시도
- **SSRF**: `/ssrf.php?url=`로 IMDS(169.254.169.254) 접근 시도
- **SQL Injection**: `/search.php?q=`에 파라미터화 없이 쿼리 직접 삽입

WAF는 Prevention 모드와 `BlockUploadsPhp` 커스텀 룰이 이미 적용된 상태라, 공격 요청이 App Gateway 단에서 먼저 차단되는지, 아니면 통과해서 다른 계층(Firewall/MySQL Audit Log)에서 탐지되는지를 구분해서 확인하는 중이다.

📷 웹쉘/SSRF/SQLi 공격 요청·응답 화면 (진행중)

---

## 탐지 및 대응 (진행중)

- Log Analytics `AzureDiagnostics` 테이블에서 WAF/Firewall 로그 수집 확인
- KQL 기반 Sentinel 분석 규칙(Analytics Rule) 작성 및 Incident 생성 검증
- Incident 발생 시 대응 절차(격리/차단/알림) 정리

📷 Sentinel 로그 쿼리 결과
📷 분석 규칙 생성 화면
📷 Incident 생성 및 대응 화면

---

## 트러블슈팅

| 문제 | 원인 | 해결 |
|---|---|---|
| Storage Account 생성 실패 (`StorageAccountAlreadyTaken`) | 이름이 Azure 전역에서 유일해야 하는데 `tuna5tfstate604`가 이미 사용 중 | 이름을 `tuna05` 계열로 전면 교체, 리소스그룹명도 `team604tuna05`로 통일 후 재배포 |

*(이후 트러블슈팅 항목은 진행되는 대로 추가 예정)*

---

## 정리 및 회고

*(프로젝트 진행중 — 탐지·대응 검증 완료 후 작성 예정)*
