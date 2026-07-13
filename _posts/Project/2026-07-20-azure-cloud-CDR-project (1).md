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

![](../../assets/images/_posts/Project/2026-07-20-azure-cloud-CDR-project%20(1)/file-20260713174221677.png)

**Log Analytics Workspace & Sentinel 온보딩**

- `tuna-law` 워크스페이스 생성, 보존기간 30일
- `daily_quota_gb = 1`로 일일 수집량 상한을 걸어 크레딧 소진 방지
- `azurerm_sentinel_log_analytics_workspace_onboarding`으로 Sentinel(SecurityInsights) 활성화

**진단 설정(Diagnostic Settings) — 4개 소스 통합**

| 리소스 | 수집 로그/메트릭 |
|---|---|
| Azure Firewall | ApplicationRule, NetworkRule, DnsProxy 로그 + 전체 메트릭 |
| MySQL Flexible Server | SlowLogs, AuditLogs(CONNECTION/DDL/DML) + 전체 메트릭 |
| 구독 Activity Log | Administrative, Security 카테고리 |
| Application Gateway(WAF) | FirewallLog, AccessLog + 전체 메트릭 |

**Sentinel 분석 규칙(Analytics Rule) 6개 배포**

Action Group(이메일 알림, `team604tuna05@gmail.com`) + 아래 6개 규칙을 Terraform(`19_sentinel_rules.tf`)으로 코드화해 배포했다.

| 규칙 | 대상 로그 | 심각도 |
|---|---|---|
| 웹쉘 업로드 | WAF FirewallLog | High |
| SSRF/IMDS | WAF FirewallLog | High |
| SQL Injection | WAF FirewallLog | Medium |
| MySQL 비정상 접속 | MySqlAuditLogs | Medium |
| 방화벽 미허용 아웃바운드 | Firewall App/Network Rule | Medium |
| 권한 변경 | Activity Log | Medium |

![](../../assets/images/_posts/Project/2026-07-20-azure-cloud-CDR-project%20(1)/file-20260713174245222.png)

---

## 트러블슈팅

### 1. Storage Account 이름 전역 충돌

| 항목 | 내용 |
|---|---|
| 원인 | `tuna5tfstate604`가 Azure 전역에서 이미 사용 중 (`StorageAccountAlreadyTaken`) |
| 해결 | 이름을 `tuna05` 계열로 전면 교체, 리소스그룹명도 `team604tuna05`로 통일 후 재배포 |

### 2. MySQL AAD 인증 실패 — DB 연결 오류 (WordPress "데이터베이스 연결 중 오류")

배포 완료 후 사이트 접속 시 DB 연결 오류 발생. 원인 진단을 단계별로 좁혀갔다.

**진단 과정**
1. VM 내부 `/var/www/.mysql_aad_token` 확인 → 토큰은 정상 발급(1853바이트)
2. 토큰으로 직접 `mysql` 접속 시도 → `ERROR 1045 Access denied for user 'tuna-web-vm'`
3. MySQL에 등록된 `tuna-web-vm` 계정의 `AUTHENTICATION_STRING`(Object ID) 조회 시도
   → **관리자 토큰 자체가 거부됨**: `ERROR 9106 Azure AD access token is not valid ... does not contain group ID`
   → 원인: `az login`이 MySQL AAD Admin(student618)이 아닌 다른 계정으로 되어 있었음
4. `student618` 계정으로 재로그인 후 재조회 → **결과 행 자체가 없음** → `tuna-web-vm` 계정이 애초에 MySQL에 등록된 적이 없었던 것으로 확인

**근본 원인**: `20_register_db_users.sh`가 `az vm run-command invoke`의 결과(내부 `mysql` 명령의 성공/실패)를 검사하지 않고 무조건 `"✔ 등록 완료"`를 출력하는 구조였다. `az vm run-command invoke`는 원격 셸 내부 명령이 실패해도 Azure API 호출 자체는 성공 처리되어 CLI 종료 코드가 0으로 나오기 때문에, `100_run.sh` 최초 실행 시 로그인 계정이 맞지 않아 3개 계정 등록이 전부 조용히 실패했는데도 로그상으로는 "성공"으로 보였다.

**조치 (V4)**
- 스크립트 실행 전 현재 `az login` 계정을 화면에 표시하고 확인(y/N) 받도록 추가
- `az vm run-command` 반환 메시지에 `ERROR` 문자열이 있는지 검사해, 있으면 실패로 처리하고 `exit 1`

**추가 조치 (V5)**: `CREATE AADUSER IF NOT EXISTS`는 VM 재생성으로 Managed Identity Object ID가 바뀌어도 기존(예전 OID) 등록을 그대로 두는 구조라, VM 재생성 후 동일한 `Access denied`가 재발할 수 있는 잠재 결함이 있었다. `DROP USER IF EXISTS` 후 `CREATE AADUSER`로 변경해, 재실행할 때마다 항상 최신 Object ID로 덮어쓰도록 수정했다.

수동으로 `tuna-web-vm` 계정을 재등록한 뒤 Object ID(`9059d2c7-a08e-450a-a04c-ad5697726462`)가 정확히 일치하는 것을 확인했고, 이후 WordPress 사이트가 정상 접속됨을 확인했다.

📷 DB 연결 오류 화면
📷 `AUTHENTICATION_STRING` 일치 확인 쿼리 결과
📷 WordPress 정상 접속 화면

### 3. Sentinel 웹쉘 탐지 규칙의 KQL 조건 오류

배포된 규칙의 KQL이 실제 로그 구조와 맞지 않아 결과가 0건으로 나오는 문제를 발견하고 수정했다.

- **최초 쿼리**: `requestUri_s has "/uploads/" and ... | where action_s == "Blocked"`
- **문제**: OWASP CRS는 개별 공격 패턴(예: `933110`, PHP 파일 업로드 패턴)을 `Matched`로 별도 로그 줄에 남기고, 최종 차단 판정은 트랜잭션 이상 점수 룰(`949110`)이 `Blocked`로 별도 줄에 남긴다. 두 조건(`requestUri_s`+`action_s == Blocked`)이 서로 다른 로그 줄에 걸쳐 있어 AND로 묶으니 매치되는 행이 없었다.
- **수정 (V6)**: `ruleId_s == "933110"` 매치 자체를 웹쉘 시도 탐지 신호로 사용하도록 조건 변경. 실제 업로드 시도(2회)와 정확히 일치하는 2건의 탐지 결과를 확인했다.

```kql
AzureDiagnostics
| where Category == "ApplicationGatewayFirewallLog"
| where ruleId_s == "933110" or (requestUri_s has "/uploads/" and requestUri_s endswith ".php")
| extend AttackerIP = clientIp_s
```

📷 `/upload.php` 웹쉘 업로드 시도 → 403 Forbidden 차단 화면
📷 WAF FirewallLog 원본 (933110 Matched → 949110 Blocked, 2줄 구조) 확인
📷 수정된 쿼리로 실제 공격 횟수(2건)와 정확히 일치하는 필터링 결과 확인

---

## 취약점 재현 및 탐지 검증 진행 상황

| 공격 시나리오 | 재현 | WAF 차단 확인 | Sentinel 규칙 검증 |
|---|---|---|---|
| 웹쉘 업로드 (`/upload.php`) | ✅ | ✅ (933110 Matched → 949110 Blocked) | ✅ (V6에서 KQL 수정 후 확인) |
| SSRF (`/ssrf.php`) | 진행 예정 | - | - |
| SQL Injection (`/search.php`) | 진행 예정 | - | - |

---

## 탐지 및 대응 (진행중)

- Log Analytics `AzureDiagnostics` 테이블에서 WAF 로그 필드명(`requestUri_s`, `ruleId_s`, `action_s`, `clientIp_s`, `details_message_s`) 실측 확인 완료
- 웹쉘 탐지 규칙 KQL 실전 검증 완료 (V6)
- SSRF, SQL Injection 탐지 규칙 검증 예정
- Incident 생성 및 이메일 알림(`team604tuna05@gmail.com`) 수신 테스트 예정

📷 Sentinel Incident 생성 화면 (예정)
📷 이메일 알림 수신 화면 (예정)

---

## 코드 버전 이력

| 버전 | 변경 내용 |
|---|---|
| V3 | 최초 배포 성공 (네트워크/WAF/Firewall/Bastion/MySQL/Sentinel 로그 파이프라인) |
| V4 | `20_register_db_users.sh` 실패 감지 로직 추가 (로그인 계정 확인, ERROR 검사) |
| V5 | `20_register_db_users.sh` — `DROP USER` 후 재생성으로 OID 갱신 문제 방지 |
| V6 | `19_sentinel_rules.tf` — 웹쉘 탐지 규칙 KQL을 실측 로그 기준으로 수정 |

---

## 정리 및 회고

*(프로젝트 진행중 — SSRF/SQLi 탐지 검증, Incident 대응까지 완료 후 작성 예정)*
