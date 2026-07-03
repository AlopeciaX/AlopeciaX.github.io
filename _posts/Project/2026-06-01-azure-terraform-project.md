---
title: Azure 클라우드 인프라 및 M365 Defender 보안 구축 (1) — 아키텍처 설계
date: 2026-06-01
categories:
  - project
comments: true
tags:
  - azure
  - terraform
---
---
## 개요

**하이브리드 클라우드 기반 그룹웨어 서비스 구축**을 목표로 한 팀 프로젝트. Azure 클라우드와 온프레미스 데이터베이스를 Site-to-Site VPN으로 연동하고, Terraform으로 인프라 전체를 코드화(IaC)했다. 아키텍처는 총 3차례에 걸쳐 개선하며 설계했다.

**핵심 키워드**: 하이브리드 클라우드 · Hub & Spoke · Terraform IaC · Application Gateway(WAF) · VMSS Auto Scaling · Traffic Manager · Site-to-Site VPN

---

## 프로젝트 목표

- **고가용성/확장성**: Application Gateway + VMSS로 자동 확장, Traffic Manager로 리전 장애 대응(DR)
- **보안성**: Azure ↔ 온프레미스 DB 간 Site-to-Site VPN, 서비스/관리/데이터 영역 분리 (최소 권한 원칙)
- **자동화**: Terraform으로 서버·네트워크·보안 정책·VPN을 코드로 정의해 반복 가능한 배포 구조 확보

**사용 기술 스택**

| 구분 | 기술 |
|---|---|
| IaC | Terraform v1.x + AzureRM Provider v4.23+ |
| 웹/DB | Ubuntu 20.04 (웹) + Apache 2.4 / Rocky Linux (DB) + MySQL 8.0 |
| 로드밸런싱 | Application Gateway (WAF_v2) |
| 자동 확장 | Virtual Machine Scale Set |
| 네트워크 | Site-to-Site VPN(IPSec/IKEv2), Azure Bastion, NAT Gateway, Private DNS |
| 트래픽 관리 | Azure Traffic Manager (Priority Mode) |
| 온프레미스 방화벽 | BlueMax NGF 100 |

---

## 아키텍처 설계 — 1차 → 3차 개선 과정

프로젝트 초기부터 완성형 아키텍처로 시작한 게 아니라, **설계 → 한계 발견 → 개선**을 3차례 반복하며 완성도를 높였다.

### 1차 아키텍처

Azure와 온프레미스 DB를 Site-to-Site VPN으로 연동하고, 서비스 영역(Web1/Web2 VNet)과 관리 영역을 VNet Peering으로 분리하는 기본 구조.

> 🖼️ *사진 자리 — 1차 시스템 아키텍처 구성도*

**한계**: 네트워크 연결·관리 기능이 **단일 Hub에 집중**돼 있어, Hub 장애 시 전체 서비스가 영향을 받는 구조적 문제 + DR 이중화 부족.

### 2차 아키텍처

Korea Central / Korea South 양쪽 리전에 **Hub를 각각 구성**해 이중화하고, Azure Bastion·Front Door·Application Gateway를 도입.

> 🖼️ *사진 자리 — 2차 시스템 아키텍처 구성도*

**한계**: Front Door와 Application Gateway를 동시에 쓰다 보니 프로젝트 규모 대비 구조가 과도하게 복잡해지고 비용·관리 부담 증가.

### 3차 아키텍처 (최종)

- Front Door 대신 **Traffic Manager**를 글로벌 진입점으로 선택 (DNS 기반, 더 단순하고 프로젝트 규모에 적합)
- 각 리전 내부는 **Application Gateway(WAF)**가 트래픽 분산 + 웹 공격 차단 담당
- Korea Central / Korea South 양 리전에 Application Gateway + VMSS + VPN Gateway를 대칭 구성해 리전 단위 이중화 완성

> 🖼️ *사진 자리 — 3차(최종) 시스템 아키텍처 구성도*

> 💡 설계 과정에서 배운 점: "더 좋아 보이는 기능(Front Door)"을 무조건 추가하기보다, **프로젝트 규모와 관리 복잡도를 함께 고려**해서 Traffic Manager로 단순화한 결정이 결과적으로 더 안정적인 구조를 만들었다.

---

## Terraform 기반 인프라 구현

- Terraform 파일을 역할별로 분리(init/RG/VNet/Subnet/PublicIP 등)해 유지보수성을 높였고, `subscription_id` 등 민감 정보는 변수로 분리
- **Azure Key Vault + Managed Identity**를 도입해 DB 계정 정보 등 민감 정보를 Terraform 코드와 완전히 분리

> 🖼️ *사진 자리 — Terraform 프로젝트 폴더 구조 / 주요 리소스 코드 화면*

---

## 구축 과정에서 발생한 문제와 해결

| 구분 | 발생 문제 | 원인 | 해결 방안 |
|---|---|---|---|
| MySQL | Database 생성 실패 | 지원되지 않는 Charset 사용 | 지원 Charset으로 수정 |
| Network | NIC 생성 실패 | IP 주소가 서브넷 범위와 불일치 | 서브넷 대역 재설정 |
| VPN | VPN 연결 실패 | IPSec 설정 불일치 | 암호화 정책 및 PSK 재설정 |
| Security | 민감정보 노출 우려 | Terraform 변수 파일에 직접 저장 | Azure Key Vault 적용 |

---

## 테스트 및 검증

VPN 연결, DB Server 연동, Application Gateway/WAF, VMSS Auto Scaling, Traffic Manager 장애 조치(Failover)까지 전 항목을 정상 동작 확인했다.

> 🖼️ *사진 자리 — Azure Portal 최종 리소스 구성 화면*

---

## 정리

- 아키텍처를 3차에 걸쳐 개선하면서, **설계 초기의 "그럴듯한 구조"가 실제로는 운영 복잡도만 높일 수 있다**는 걸 체감했다. Front Door를 걷어내고 Traffic Manager로 단순화한 게 대표적인 사례.
- Terraform + Key Vault 조합으로 "코드에 비밀 정보를 남기지 않는" 인프라 자동화 흐름을 처음부터 끝까지 경험했다.
- 문제 해결 표에 정리한 4가지 이슈(Charset, 서브넷, IPSec, 민감정보) 모두 실제로 겪고 고친 것들이라, 다음 프로젝트에서 동일한 실수를 줄이는 체크리스트로 남겨둘 만하다.
