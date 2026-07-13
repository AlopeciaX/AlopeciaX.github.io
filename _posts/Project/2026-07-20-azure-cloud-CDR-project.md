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

---

## Terraform 인프라 구현

**Bootstrap**

- Key Vault·Storage Account를 이전과 동일하게 별도 리소스그룹(`team604tuna05-infra`)에 분리 배치

![](../../assets/images/Project/2026-07-20-azure-cloud-CDR-project/file-20260713164704838.png)
<sub>[terraform apply 완료 로그 — `Apply complete! Resources: 7 added, 0 changed, 0 destroyed.` 및 output 값(공인 IP, MySQL FQDN 등)]</sub>

![](../../assets/images/Project/2026-07-20-azure-cloud-CDR-project/file-20260713174221677.png)
<sub>[`team604tuna05-infra` 리소스그룹 개요 — Key Vault, Storage Account 생성 확인]</sub>

![](../../assets/images/Project/2026-07-20-azure-cloud-CDR-project/file-20260713174653068.png)
<sub>[Bootstrap 스크립트 실행 결과 — Storage Account/Key Vault 생성 완료]</sub>

**Log Analytics Workspace & Sentinel 온보딩**

- `tuna-law` 워크스페이스 생성, 보존기간 30일 / `daily_quota_gb = 1`로 일일 수집량 상한 설정
- `azurerm_sentinel_log_analytics_workspace_onboarding`으로 Sentinel(SecurityInsights) 활성화

**진단 설정(Diagnostic Settings) — 4개 소스 통합**

| 리소스 | 수집 로그/메트릭 |
|---|---|
| Azure Firewall | ApplicationRule, NetworkRule, DnsProxy 로그 + 전체 메트릭 |
| MySQL Flexible Server | SlowLogs, AuditLogs(CONNECTION/DDL/DML) + 전체 메트릭 |
| 구독 Activity Log | Administrative, Security 카테고리 |
| Application Gateway(WAF) | FirewallLog, AccessLog + 전체 메트릭 |

**Sentinel 분석 규칙(Analytics Rule) 6개 배포 — 전체 정상 활성화 확인**

Action Group(이메일 알림, `team604tuna05@gmail.com`) + 아래 6개 규칙을 Terraform(`19_sentinel_rules.tf`)으로 코드화해 배포했고, Portal에서 6개 규칙 모두 심각도(High 2 / Medium 4)까지 정확히 반영되어 활성화된 것을 확인했다.

| 규칙 | 대상 로그 | 심각도 |
|---|---|---|
| 웹쉘 업로드 | WAF FirewallLog | High |
| SSRF/IMDS | WAF FirewallLog | High |
| SQL Injection | WAF FirewallLog | Medium |
| MySQL 비정상 접속 | MySqlAuditLogs | Medium |
| 방화벽 미허용 아웃바운드 | Firewall App/Network Rule | Medium |
| 권한 변경 | Activity Log | Medium |

![](../../assets/images/Project/2026-07-20-azure-cloud-CDR-project/file-20260713174708416.png)
<sub>[Sentinel 분석 규칙 6개 활성화 화면 — 심각도 High 2 / Medium 4]</sub>

---

## WordPress 초기 설치

배포된 App Gateway 공인 IP로 접속해 WordPress 설치 마법사를 완료했다 (사이트 제목 `tunaWebPage`, 관리자 계정 `nova06`).

![](../../assets/images/Project/2026-07-20-azure-cloud-CDR-project/file-20260713171554616.png)
<sub>[WordPress 설치 정보 입력 화면 — 사이트 제목 `tunaWebPage`, 사용자명 `nova06`]</sub>

---

## MySQL Entra ID 인증 검증

VM의 Managed Identity Object ID와 MySQL에 등록된 AAD 사용자 정보를 대조해 인증 경로를 검증했다. WordPress가 비밀번호 없이 AAD 토큰만으로 정상 접속되는 것까지 확인했다.

![](../../assets/images/Project/2026-07-20-azure-cloud-CDR-project/file-20260713181949302.png)
<sub>[`mysql.user` 조회 결과 — `AUTHENTICATION_STRING`이 VM Managed Identity Object ID와 일치 확인]</sub>

![](../../assets/images/Project/2026-07-20-azure-cloud-CDR-project/file-20260713181855055.png)
<sub>[WordPress 사이트 정상 접속 화면 (DB 연결 정상화 후)]</sub>

---

## 웹쉘 업로드 탐지 검증

`/upload.php`로 PHP 웹쉘(`<?php system($_GET['cmd']); ?>`) 업로드를 시도한 결과, **WAF Prevention 모드에서 요청 자체가 403 Forbidden으로 차단**되는 것을 확인했다. Sentinel 분석 규칙도 실제 로그 구조에 맞게 조정한 뒤, 실제 업로드 시도 횟수(2회)와 정확히 일치하는 탐지 결과를 확인했다.

```kql
AzureDiagnostics
| where Category == "ApplicationGatewayFirewallLog"
| where ruleId_s == "933110" or (requestUri_s has "/uploads/" and requestUri_s endswith ".php")
| extend AttackerIP = clientIp_s
```

**1차 시도**

![](../../assets/images/Project/2026-07-20-azure-cloud-CDR-project/file-20260713172632681.png)
<sub>[`upload.php` 업로드 폼에서 `shell.php` 파일 선택]</sub>

![](../../assets/images/Project/2026-07-20-azure-cloud-CDR-project/file-20260713172642508.png)
<sub>[1차 웹쉘 업로드 시도 → 403 Forbidden]</sub>

**2차 시도 및 로그 분석**

![](../../assets/images/Project/2026-07-20-azure-cloud-CDR-project/file-20260713182143797.png)
<sub>[2차 웹쉘 업로드 시도 화면]</sub>

![](../../assets/images/Project/2026-07-20-azure-cloud-CDR-project/file-20260713182122181.png)
<sub>[2차 웹쉘 업로드 시도 → 403 Forbidden 결과]</sub>

원본 로그를 처음 조회했을 때(933110/949110 매치 발견 시점):

![](../../assets/images/Project/2026-07-20-azure-cloud-CDR-project/file-20260713172552416.png)
<sub>[최초 원본 로그 조회 — `/upload.php`에서 933110(Matched)·949110(Blocked) 최초 발견]</sub>

수정된 쿼리로 재확인한 결과:

![](../../assets/images/Project/2026-07-20-azure-cloud-CDR-project/file-20260713182225652.png)
<sub>[WAF FirewallLog 원본 재확인 — 933110 Matched → 949110 Blocked]</sub>

![](../../assets/images/Project/2026-07-20-azure-cloud-CDR-project/file-20260713182328592.png)
<sub>[수정된 Sentinel 쿼리 실행 결과 — 실제 공격 횟수(2건)와 정확히 일치]</sub>

---

## SSRF / SQL Injection 탐지 검증

SSRF(`/ssrf.php?url=http://169.254.169.254/...`)와 SQL Injection(`/search.php?q=' OR '1'='1`) 모두 **WAF Prevention 모드에서 요청 자체가 403 Forbidden으로 차단**됐다. 로그에서는 SSRF가 OWASP CRS `931100`(절대 URL 접근)·`931130`(IP 직접 접근) 매치로, SQLi는 `942xxx` 계열 룰 7~8개가 동시에 매치되는 것으로 확인됐으며, 둘 다 `949110`(트랜잭션 이상 점수 초과)으로 최종 차단이 기록됐다.

두 규칙은 웹쉘과 달리 **KQL 수정 없이 처음부터 정확하게 탐지**됐다. 매치 조건(IMDS IP 문자열 포함, `942` 룰 prefix)이 전부 같은 로그 줄에 함께 기록되는 구조라, 웹쉘 때 겪었던 "조건이 서로 다른 줄에 흩어지는" 문제가 발생하지 않았다.

**SSRF**

![](../../assets/images/Project/2026-07-20-azure-cloud-CDR-project/file-20260714001304598.png)
<sub>[SSRF 요청(`/ssrf.php?url=http://169.254.169.254/...`) → 403 Forbidden 차단]</sub>

![](../../assets/images/Project/2026-07-20-azure-cloud-CDR-project/file-20260714001805027.png)
<sub>[WAF 로그 전체 조회 — SSRF 관련 931100(절대 URL 접근)·931130(IP 직접 접근) 매치 확인]</sub>

![](../../assets/images/Project/2026-07-20-azure-cloud-CDR-project/file-20260714001809979.png)
<sub>[SSRF 탐지 Sentinel 쿼리 실행 결과 — 4건 매치]</sub>

**SQL Injection**

![](../../assets/images/Project/2026-07-20-azure-cloud-CDR-project/file-20260714003046091.png)
<sub>[WAF 로그 전체 조회 — SQL Injection 관련 942xxx 계열 룰 7~8개 매치, `942100`에 "Detect Sql Injection at ARGS" 명시]</sub>

![](../../assets/images/Project/2026-07-20-azure-cloud-CDR-project/file-20260714003150503.png)
<sub>[SQL Injection 탐지 Sentinel 쿼리(`ruleId_s startswith "942"`) 실행 결과 — 7건 매치]</sub>

---

## 취약점 재현 및 탐지 검증 현황

| 공격 시나리오 | 재현 | WAF 차단 확인 | Sentinel 규칙 검증 |
|---|---|---|---|
| 웹쉘 업로드 (`/upload.php`) | ✅ | ✅ (933110 → 949110) | ✅ (KQL 수정, V6) |
| SSRF (`/ssrf.php`) | ✅ | ✅ (931100/931130 → 949110) | ✅ (수정 불필요) |
| SQL Injection (`/search.php`) | ✅ | ✅ (942xxx 8개 룰 → 949110) | ✅ (수정 불필요) |

---

## 탐지 및 대응 (진행중)

- WAF 로그 필드명 실측 확인 완료, 웹쉘/SSRF/SQLi 세 가지 공격 시나리오 전부 재현·차단·탐지 검증 완료
- Incident 생성 및 이메일 알림(`team604tuna05@gmail.com`) 수신 테스트 예정
- MySQL 비정상 접속, 방화벽 미허용 아웃바운드, 권한 변경 규칙 3개는 아직 실제 트래픽으로 검증 전

📷 Sentinel Incident 생성 화면 (예정)
📷 이메일 알림 수신 화면 (예정)

---

## 트러블슈팅

| 문제 | 원인 | 해결 |
|---|---|---|
| Storage Account 생성 실패 (`StorageAccountAlreadyTaken`) | 이름이 Azure 전역에서 이미 사용 중 | `tuna05` 계열로 이름 전면 교체 후 재배포 |
| WordPress DB 연결 오류 | `20_register_db_users.sh`가 `az vm run-command`의 내부 실패를 감지 못해 계정 등록이 조용히 실패 | 로그인 계정 검증 + ERROR 감지 로직 추가(V4), `DROP` 후 재생성으로 OID 자동 갱신(V5) |
| Sentinel 웹쉘 규칙 결과 0건 | 933110(Matched)과 949110(Blocked)이 서로 다른 로그 줄에 기록되는데, 두 조건을 AND로 묶어 매치 행이 없었음 | 933110 매치 자체를 탐지 조건으로 수정(V6) |

---

## 코드 버전 이력

| 버전 | 변경 내용 |
|---|---|
| V3 | 최초 배포 성공 (네트워크/WAF/Firewall/Bastion/MySQL/Sentinel 로그 파이프라인) |
| V4 | `20_register_db_users.sh` 실패 감지 로직 추가 |
| V5 | `20_register_db_users.sh` — OID 갱신 문제 방지 (`DROP` 후 재생성) |
| V6 | `19_sentinel_rules.tf` — 웹쉘 탐지 규칙 KQL을 실측 로그 기준으로 수정 |

---

## 정리 및 회고

*(프로젝트 진행중 — Incident 생성/이메일 알림 확인, MySQL/방화벽/권한 변경 규칙 검증 완료 후 작성 예정)*
