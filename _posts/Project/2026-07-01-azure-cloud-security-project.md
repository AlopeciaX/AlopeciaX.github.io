---
title: 4. Azure 클라우드 데이터 및 App 보안
date: 2026-07-01
categories:
  - project
comments: true
tags:
  - azure
  - terraform
  - security
  - project
---
---
# Azure 클라우드 데이터 및 App 보안 프로젝트 — 상세 기록

## 1. 프로젝트 목표

기존 인프라(WordPress + Azure MySQL Flexible Server, Application Gateway/WAF, Azure Firewall, Bastion 구조)에 **"내부자 위협(Insider Threat)" 시나리오**를 적용해, 아래 질문에 실제로 답할 수 있는 인프라를 만드는 것이 목표였다.

- DB 패스워드를 아예 없앨 수 있는가? (Entra ID 전용 인증)
- 팀원이 늘어나거나 퇴사할 때, 권한을 자동으로 주고 회수할 수 있는가?
- VM이 SSH로 뚫려도, 그 사람이 DB 전체 권한까지 가져갈 수 없게 만들 수 있는가?
- 이 모든 걸 Terraform 코드 하나로 재현 가능하게 만들 수 있는가?

---

## 2. 최초 코드 리뷰에서 발견한 문제

업로드된 초기 코드(`4차project_code.zip`)를 검토하며 아래 문제를 확인했다.

|문제|내용|
|---|---|
|MySQL AAD 일반 사용자 등록 코드 부재|`tuna-web-vm`을 DB 사용자로 등록하는 `CREATE AADUSER`가 코드 어디에도 없음|
|민감정보 노출|`.gitignore` 대상(`terraform.tfvars`, `team_members.env`)인데 zip에는 그대로 포함되어 있었음|
|약한 기본 비밀번호|`00_bootstrap.sh`에 `DB_PASSWORD="${DB_PASSWORD:-It12345@}"` 하드코딩|
|NSG-UDR 정책 중복|Web NSG가 Internet 80/443 직접 허용 + Deny 규칙 동시 존재 (UDR로 실질 우회는 안 되지만 일관성 부족)|
|Before/After 데모 취약점|`upload.php`(웹쉘), `search.php`(SQLi), `ssrf.php` — 의도된 교육용 코드, After 조치는 주석 처리 상태|

---

## 3. MySQL Entra ID 인증 — 실제 겪은 문제와 해결 순서

### 3-1. az-cli 구버전 문제

VM에 설치된 `azure-cli`가 **2.0.81(2018년 버전)** 이라 `az mysql flexible-server` 명령어 자체가 없었음.

- **원인**: `install.sh.tpl`의 `curl -sL https://aka.ms/InstallAzureCLIDeb | bash` 스크립트가 Microsoft 저장소를 등록하려 했는데, Azure Firewall이 `packages.microsoft.com`을 차단해 실패 → 이어지는 `apt install azure-cli`가 Ubuntu 기본 저장소의 방치된 구버전을 대신 설치
- **해결**: Firewall `allow-web-outbound` 규칙에 `packages.microsoft.com`, `aka.ms`, `azurecliprod.blob.core.windows.net` 추가. 이후 `curl | bash` 방식 자체를 지양하고, GPG 키 등록 + apt 저장소 등록을 명시적으로 하는 방식으로 `install.sh.tpl` 재작성

### 3-2. AAD Admin 계정 불일치

`az mysql flexible-server ad-admin list`로 확인해보니 등록된 admin이 의도한 계정(student618)이 아니라 **student612**였음. Portal에서 재등록.

### 3-3. 게스트 계정의 테넌트 불일치 (`ERROR 9123`)

게스트 계정(student618)이 홈 테넌트(mscsschool) 기준으로 `az login`하면 그 테넌트의 토큰이 발급되는데, MySQL 서버는 리소스 테넌트(sim981naver) 기준 토큰을 요구 → 불일치로 거부.

- **해결**: `az login --tenant <ID>`, `az account get-access-token --tenant <ID>`로 대상 테넌트를 명시

### 3-4. MySQL 사용자명 32자 제한 (`ERROR 1470`)

`mysql.user` 테이블 자체의 컬럼 길이 제한(32자, AAD 기능과 무관한 MySQL 고유 제약). 게스트 UPN(`student612_mscsschool.onmicrosoft.com#EXT#@sim981naver.onmicrosoft.com`, 70자)은 그대로 등록 불가.

- 최초엔 `CREATE AADUSER ... AS ...` 문법으로 우회 가능하다고 잘못 안내했다가, 실제로 그런 문법이 존재하지 않는다는 걸 확인 후 정정
- **최종 해결**: 로그인명은 32자 이내의 짧은 alias(`student612`, `former-employee` 등)로 등록하고, 신원 검증은 `IDENTIFIED BY '<Object ID>'`로 처리 (alias는 임의 이름, 실제 매칭은 Object ID)

### 3-5. Directory Role 위임 (PIM)

student618이 `tuna-mysql-identity`(MySQL 서버의 UserAssigned Identity)에 Directory Reader를 스스로 부여할 수 있도록, sim이 `Privileged Role Administrator`를 위임.

- PIM 화면 진입 시 "P2 라이선스 필요" 안내가 떴으나, "Active" 방식 즉시 할당은 P2 없이도 가능했음
- 역할 할당 직후 Portal에서 "할당 추가" 버튼이 잠긴 것처럼 보였는데, **로그아웃 후 재로그인**하니 세션 토큰이 갱신되며 해결됨 (권한 변경이 즉시 토큰에 반영되지 않는 문제)

---

## 4. Terraform 코드 자동화 — 파일별 상세 변경

### `01_var.tf`

- `extra_db_users` 변수 신설: 팀원을 `{login, object_id, subscription_role(선택)}` 맵으로 관리
- **버그 발견 및 수정**: 이 변수에 `sensitive = true`를 붙였더니, `for_each`의 값으로 sensitive 변수를 쓸 수 없다는 Terraform 제약(`Invalid for_each argument`)에 걸려 apply 자체가 실패함 → `sensitive` 속성 제거
- `lock_shared_ssh_key`(bool, 기본 false): 공유 SSH 키 잠금 여부를 제어하는 스위치
- `subid` 변수: 초기엔 `100_run.sh`가 환경변수(`TF_VAR_subid`)로 주입했으나, 스크립트를 거치지 않고 `terraform apply`를 단독 실행하면 값이 비어 파싱 에러가 반복됨 → `terraform.tfvars`에 고정값으로 직접 명시하는 방식으로 변경해 환경변수 의존성 제거

### `07_bastion.tf`

- `sku = "Standard"` 추가: Basic SKU에서는 Bastion 연결 화면에 "Microsoft Entra ID" 인증 옵션 자체가 나타나지 않음
- `tunneling_enabled = true`, `ip_connect_enabled = true`: 로컬 PC에서 Bastion을 거쳐 임의 사설 IP(MySQL 등)로 터널링하기 위해 추가 (이후 다른 방식으로 대체했지만 유지)

### `09_web_vm.tf`

- `azurerm_virtual_machine_extension.aad_login`(`AADSSHLoginForLinux`) 추가 — 개인별 Entra ID 신원으로 SSH 로그인
- RBAC 역할 할당 7개 추가:
    - 관리자(student618): VM `Reader` + `Virtual Machine Administrator Login`(sudo 가능), Bastion `Reader`
    - 팀원(`extra_db_users` 각각): VM `Reader` + `Virtual Machine User Login`(sudo 불가), Bastion `Reader`
    - 선택적 구독 스코프 역할(`subscription_role`): 과거 재직자의 실제 접근 패턴(예: 구독 Reader) 재현용
- **검증된 함정**: 계정에 구독/리소스그룹 스코프 `Owner`나 `Contributor`가 남아있으면, `Virtual Machine User Login`만 부여해도 `loginAsAdmin` 액션이 이미 포함되어 있어 sudo가 그대로 뚫림 — 최소 권한 테스트를 하려면 상위 스코프의 광범위한 권한부터 제거해야 함을 실제로 확인

### `11_mysql.tf`

- `GRANT ALL PRIVILEGES` → `SELECT, INSERT, UPDATE, DELETE, CREATE, ALTER, INDEX, DROP, CREATE TEMPORARY TABLES, LOCK TABLES`로 최소 권한화
- `CREATE AADUSER` 자동화 로직을 세 번에 걸쳐 재설계:
    1. **1차**: 로컬 PC에서 `mysql` 클라이언트로 직접 접속 (VNet 밖이라 사설 DB 접근 불가 — 구조적으로 실패)
    2. **2차**: Bastion IP 터널링(`az network bastion tunnel --target-ip-address`)으로 로컬 PC에서 임시 포트를 열어 우회 (MySQL 사설 IP는 Private DNS Zone A레코드를 ARM API로 조회해 확보) — 로컬에 `mysql` 클라이언트가 없어서 실행 불가
    3. **3차(최종)**: `az vm run-command invoke`로 **VM 안의 mysql 클라이언트를 원격 실행** — Bastion/SSH 인증 자체가 필요 없고, VM Agent를 통해 root 권한으로 직접 실행되므로 가장 안정적. 이 로직은 결국 Terraform `null_resource`에서 분리해 별도 셸 스크립트(`20_register_db_users.sh`)로 이전
- `audit_log_events` 값 버그: `"CONNECTION,QUERY_DDL,QUERY_DML"`로 잘못 지정했다가 `InvalidConfigurationValue` 에러로 발견 → 실제 허용값(`DDL,DML_SELECT,DML_NONSELECT,DCL,ADMIN,DML,GENERAL,CONNECTION,CONNECTION_V2,TABLE_ACCESS`) 확인 후 `"CONNECTION,DDL,DML"`로 수정

### `14_firewall.tf`

- `graph.microsoft.com` 추가 — `AADSSHLoginForLinux` 확장이 PAM 계정 조회 시 Microsoft Graph API를 호출하는데, 이게 막혀 있어 확장 설치가 `SSL_ERROR_SYSCALL`로 실패했던 걸 확인 후 추가
- `packages.microsoft.com` 등 az-cli 설치용 도메인은 이전 단계에서 이미 추가됨

### `15_log.tf`

- `audit_log_events` 오타 수정 (위 3-mysql 항목 참고)
- 진단 설정(`fw_diag`, `mysql_diag`, `waf_diag`) 3개가 반복적으로 "already exists" 에러를 냈던 문제: 원인은 `100_run.sh`의 `try_import` 함수가 `&>/dev/null`로 에러를 전부 숨겨서, 실패 원인을 알 수 없었던 것. 로그를 보이게 고친 뒤 확인해보니 실제로는 이미 state에 정상 반영되어 있었고, 반복 에러의 진짜 원인은 **`var.subid`가 비어있어 다른 리소스(`subscription_activity_diag`)가 에러를 내며 apply 전체가 중단**되던 것이었음

### `install.sh.tpl`

- MySQL 토큰 발급 로직: "cron이 50분마다 캐시 파일 갱신" 방식에 "캐시 파일이 없거나 비어있으면 IMDS 직접 호출" 폴백을 추가한 하이브리드 방식으로 변경
- IMDS(`169.254.169.254`) 접근을 `www-data`/`root` 프로세스로만 제한하는 iptables 규칙 추가 — 일반 SSH 로그인 계정이 VM의 Managed Identity 토큰을 도용해 DB에 직접 접속하는 경로 차단
- 공유 SSH 키(`azureuser`) 조건부 잠금 로직 추가: AAD SSH 로그인 확장이 실제로 설치 완료됐는지 최대 5분간 폴링 확인한 뒤에만 잠금 실행 — 확장 설치와 `custom_data`(cloud-init) 실행에는 순서 보장이 없어서, 무작정 잠그면 확장 설치가 안 끝난 상태에서 계정이 잠겨 VM에 아예 접근 못 하게 되는 락아웃 위험이 있었음을 사전에 발견하고 방지
- az-cli 설치를 `curl | bash` 방식에서 GPG 키 + apt 저장소 명시적 등록 방식으로 교체
- 부팅 초기 apt 잠금 충돌(unattended-upgrades 등과의 경합 추정) 대응: `apache2`, `azure-cli`, `iptables-persistent` 설치에 각각 최대 10회 재시도 로직(`apt_install_retry` 함수) 추가

### `100_run.sh`

- `try_import` 함수의 에러 은폐 문제 수정 → 이후 근본 원인(subid) 해결 후 아예 제거
- 3단계로 `20_register_db_users.sh` 자동 실행 추가

### `20_register_db_users.sh` (신규 파일)

- `az vm run-command invoke`로 VM 안의 mysql 클라이언트를 원격 실행해 `tuna-web-vm`, 팀원, 테스트 계정을 순차적으로 `CREATE AADUSER` 등록하는 자동화 스크립트
- 초기엔 `az ssh vm --command`를 시도했으나 해당 옵션이 실제로는 존재하지 않아(`unrecognized arguments`) `az vm run-command invoke`로 교체

---

## 5. 보안 검증 — "퇴사자(Former Employee)" 시나리오

실제 Entra ID 사용자를 하나 생성(`formerEmployee@sim981naver.onmicrosoft.com`)해 아래 권한만 부여하고 검증했다.

- 구독 스코프: `Reader`만 (loginAsAdmin 액션 없음)
- VM 스코프: `Reader` + `Virtual Machine User Login`
- Bastion 스코프: `Reader`
- MySQL: 최소 권한 계정 (`GRANT OPTION` 없음)

**검증 결과**

|항목|결과|
|---|---|
|Bastion → VM Entra ID SSH 로그인|성공 (개인 신원으로 접속)|
|`sudo su` 시도|관리자 재인증(디바이스 코드) 요구 화면으로 막힘 — 즉시 권한 상승 불가 확인|
|IMDS로 VM 신원(tuna-web-vm) 토큰 도용 시도|iptables 규칙에 의해 차단 확인|
|본인 명의 MySQL 계정 접속|정상 접속, 부여된 권한 범위 내 작업 가능|

---

## 6. 전체 자동화 완성 흐름

```
bash 100_run.sh
  → [1단계] Bootstrap (Key Vault/Storage 등 사전 리소스)
  → [2단계] terraform apply
      - 네트워크/방화벽/Bastion/VM/MySQL/RBAC 전체 생성
  → [3단계] 20_register_db_users.sh 자동 실행
      - az vm run-command invoke로 VM 원격 접속
      - tuna-web-vm / 팀원 / 테스트 계정 MySQL 등록
→ WordPress 정상 구동, DB 연결 확인
```

---

## 7. 최종적으로 남겨둔 과제 (완료하지 않은 것)

- VM 자체의 로그(syslog, auth.log, iptables 로그)가 아직 Log Analytics로 수집되지 않음 — 지금은 시나리오 재현 후 VM에 직접 들어가 로그를 확인해야 함
- Bastion 세션 로그, Key Vault 접근 로그, NSG Flow Log 미수집
- CI/CD 파이프라인(GitHub Actions + OIDC + self-hosted runner) 설계까지는 논의했으나, 시간 제약상 실제 구현은 보류하고 향후 과제로 남김
- `install.sh.tpl`의 az-cli 재시도 로직은 실제 근본 원인(apt 잠금 충돌)을 로그로 직접 확진한 것이 아니라 정황상 가장 유력한 추정에 기반한 방어 코드