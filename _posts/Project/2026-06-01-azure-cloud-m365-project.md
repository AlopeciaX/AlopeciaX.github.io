---
title: Azure 클라우드 인프라 및 M365 Defender 보안구축
date: 2026-06-01
categories:
  - project
comments: true
tags:
  - azure
  - terraform
  - 온프레미스
---
---

> 4인 팀 프로젝트 · 경기인력개발원 · 2026.05.13 ~ 05.19 담당: Azure 인프라 설계, Terraform 코드 작성 및 자동화

## 한눈에 보는 결과

- 리전 이중화 — Korea Central / South 2개 리전
- 인프라 100% 코드화 — Terraform으로 63개 리소스 자동 생성
- 자동 확장 — CPU 70%↑ Scale-Out / 20%↓ Scale-In (1~5대)
- 온프레미스 연동 — Site-to-Site VPN(IPSec, AES256+SHA256)
- 장애 조치 — Traffic Manager Failover, 30초 간격 헬스체크
- 검증 결과 — 9개 항목 전체 성공

> 📝 M365 Defender 파트는 별도 정리 예정

---

## 아키텍처 (1차 → 3차)

- **1차**: VPN 기본 구조 → 단일 Hub라 장애에 취약
- **2차**: 리전별 Hub 이중화 + Front Door → 규모 대비 과도하게 복잡
- **3차(최종)**: Front Door 제거, Traffic Manager로 단순화 → 양 리전 대칭 구성

> 🖼️ _사진 자리 — 최종 아키텍처 구성도_

**Front Door 대신 Traffic Manager를 고른 이유**

- Front Door는 CDN·엣지 기능까지 포함된 무거운 서비스
- 이 프로젝트는 리전 2개짜리 단순 Failover만 필요
- Traffic Manager(DNS 기반)가 규모에 더 맞음

---

## Terraform 구현

**Bootstrap**

- Key Vault, Storage Account를 별도 RG(`team604tuna-infra`)에 우선 생성
- 이유: 민감정보를 본 인프라 코드와 분리

**네트워크**

- Korea Central: `tuna-vnet1` (10.101.0.0/16)
- Korea South: `tuna-vnet2` (10.102.0.0/16)
- 서브넷 4종: AppGW / VMSS / VPN Gateway / Bastion

**NSG**

- AppGW NSG: HTTP/HTTPS만 허용
- VMSS NSG: AppGW→HTTP, Bastion→SSH만 허용
- Bastion NSG: HTTPS/SSH/RDP만 허용

**Application Gateway (WAF)**

- WAF_v2, Prevention 모드, OWASP CRS 3.2
- Health Probe로 비정상 인스턴스 자동 제외
- `/wp-admin`, `/wp-json`은 WAF 예외 처리

**VMSS & Auto Scaling**

- SSH 키 인증만 허용(비밀번호 인증 비활성화)
- 최소 1 / 기본 2 / 최대 5대
- Managed Identity로 Key Vault 접근

**Site-to-Site VPN — 가장 까다로웠던 구간**

- Azure VPN Gateway ↔ 실제 BlueMax NGF 100 방화벽
- AES256 + SHA256 암호화
- 방화벽 정책은 필요한 통신만 허용 (DB MySQL, DB SSH, 백업 동기화 등)

> 🖼️ _사진 자리 — BlueMax NGF 100 장비 사진, VPN 연결 설정 화면_

**Private DNS / Traffic Manager**

- `db.tuna.internal`로 DB IP 대신 도메인 접근
- Traffic Manager: Priority 방식, Korea Central 1순위
- Health Monitoring: 30초 간격, 3회 실패 시 Failover

**Key Vault**

- Terraform은 `data` 소스로 기존 Key Vault만 조회 (신규 생성 X)
- VMSS는 `Get`/`List` 권한만 최소 부여
- `.tfvars`, `.tfstate`, `*.pem`, `id_rsa`는 `.gitignore` 처리

**결과**: `terraform apply`로 63개 리소스 정상 생성

> 🖼️ _사진 자리 — Terraform apply 완료 결과_

---

## 트러블슈팅

- MySQL Charset 미지원 → 지원 Charset으로 수정
- NIC 생성 실패(IP-서브넷 불일치) → 서브넷 재설계
- VPN 실패(IPSec 설정 불일치) → 암호화 정책·PSK 재설정
- 민감정보 평문 저장 → Key Vault로 전환

---

## 인프라 동작 순서

1. 사용자 요청 → Traffic Manager (Priority 기반 리전 선택)
2. → Application Gateway (WAF 필터링)
3. → VMSS (Health Probe 통과한 인스턴스만 처리, 부하 시 자동 확장)
4. → Private DNS로 DB 위치 조회
5. → Site-to-Site VPN 터널 → 온프레미스 MySQL
6. → 역순으로 응답 반환

- 관리자 접근: Azure Bastion 경유 (공인 IP 노출 없음)
- 민감정보 조회: Managed Identity → Key Vault
- DB 백업: 매일 새벽 2시 Crontab 자동 실행

---

## 검증 결과

- **VPN**: Azure·온프레미스 양쪽 로그 교차 확인, 실제 트래픽 6,724건/350건 통과 확인
- **DB 연동**: DNS 조회, MySQL 접속, 데이터 조회 전부 성공
- **백업**: Crontab 자동 실행 + Backup DB Server 확인 성공
- **애플리케이션**: 휴가 신청서 등록(INSERT) → 관리자 화면 조회까지 실제 동작 확인
- **WAF**: Health Probe 정상, WAF Prevention 모드 적용 확인
- **Auto Scaling**: 의도적 부하로 CPU 70%↑ → 인스턴스 자동 증설 직접 확인
- **Traffic Manager**: nslookup으로 Priority 1 응답 확인, FQDN 접속 성공

**종합**: VPN·DB연동·DNS·AppGW·WAF·VMSS·AutoScaling·TrafficManager·KeyVault **9개 전체 성공**

> 🖼️ _사진 자리 — VPN 연결 상태, Auto Scaling 동작, Traffic Manager Failover 테스트_

---

## 용어 정리

- **IaC**: 인프라를 코드로 관리하는 방식
- **VMSS**: 동일 설정 VM을 자동으로 늘리고 줄이는 서비스
- **WAF**: SQL Injection·XSS 같은 웹 공격을 막는 방화벽
- **NSG**: 서브넷/리소스별 트래픽 허용·차단 규칙
- **Managed Identity**: 비밀번호 없이 Azure AD로 인증하는 방식

---

## 회고

- "그럴듯한 구조"보다 규모에 맞는 단순화가 더 안정적이었다 (Front Door 제거 사례)
- Terraform + Key Vault로 코드-비밀정보 분리 습관을 익혔다
- 로그를 한쪽만 보지 않고 양쪽에서 교차 검증하는 습관을 들였다
- 부하를 직접 걸어서 Auto Scaling 동작까지 눈으로 확인했다

**다음 개선 계획**

- HTTPS/SSL 적용
- Azure Monitor + Sentinel 기반 통합 모니터링
- DB Master-Slave 이중화 강화