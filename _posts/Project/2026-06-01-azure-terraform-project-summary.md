---
title: "[요약] Azure 클라우드 인프라 및 M365 Defender 보안 구축"
date: 2026-06-01
categories:
  - project
comments: true
tags:
  - azure
  - terraform
  - 요약
---

## 프로젝트 목표

Azure 클라우드와 온프레미스 데이터베이스를 **Site-to-Site VPN**으로 연동해, 고가용성·보안성·운영 자동화를 모두 갖춘 **하이브리드 클라우드 기반 그룹웨어 서비스**를 구축한다.

> 📝 아래 내용은 프로젝트 중 **Azure 인프라(Terraform/네트워크/VPN/Application Gateway)** 파트를 정리한 것이며, **M365 Defender 보안 구성** 파트는 별도 정리 예정입니다.

- **고가용성**: Application Gateway + VMSS Auto Scaling, Traffic Manager 기반 리전 장애 대응(DR)
- **보안성**: Site-to-Site VPN, 서비스/관리/데이터 영역 분리, Key Vault + Managed Identity로 민감정보 관리
- **자동화**: Terraform으로 인프라 전체를 코드화(IaC)

**기술 스택**: Terraform · AzureRM Provider · Application Gateway(WAF_v2) · VMSS · Site-to-Site VPN · Azure Bastion · Traffic Manager · MySQL · Ubuntu/Rocky Linux

---

## 아키텍처

설계를 1차 → 3차까지 개선하며 완성했다. 초기에는 단일 Hub 구조 → 리전별 Hub 이중화 → Front Door 제거하고 Traffic Manager로 단순화, 순서로 발전시켰다.

> 🖼️ *사진 자리 — 최종(3차) 아키텍처 구성도 1장*

---

## 핵심 성과

- Korea Central / Korea South **양 리전 대칭 구성**으로 리전 단위 이중화 완성
- Application Gateway(WAF) + VMSS Auto Scaling으로 트래픽 급증에도 자동 대응
- Terraform + Key Vault 조합으로 **코드에 비밀번호를 남기지 않는 IaC 파이프라인** 구현
- VPN, DB 연동, WAF, Auto Scaling, Traffic Manager Failover, Key Vault까지 **9개 검증 항목 전부 정상 동작 확인**

---

## 트러블슈팅

| 문제 | 원인 | 해결 |
|---|---|---|
| MySQL Database 생성 실패 | 지원되지 않는 Charset 사용 | 지원 Charset으로 수정 |
| NIC 생성 실패 | IP가 서브넷 범위와 불일치 | 서브넷 대역 재설계 |
| VPN 연결 실패 | IPSec 설정 불일치 | 암호화 정책·PSK 재설정 |
| 민감정보 노출 우려 | Terraform 변수 파일에 직접 저장 | Azure Key Vault 적용 |

---

## 느낀점

아키텍처를 세 번 갈아엎으면서, "더 그럴듯해 보이는 구조(Front Door)"가 항상 정답은 아니라는 걸 배웠다. 프로젝트 규모에 맞게 Traffic Manager로 단순화한 결정이 오히려 안정성을 높였다. Terraform과 Key Vault를 함께 쓰면서 코드-비밀정보 분리라는, 실무에서 당연히 요구되는 습관을 처음부터 몸에 익힐 수 있었던 프로젝트였다.

---

## 상세 포스트

- [1편 — 아키텍처 설계]({% post_url 2026-06-01-azure-terraform-project-01 %})
- [2편 — Terraform 코드 설계]({% post_url 2026-06-08-azure-terraform-project-02 %})
- [3편 — 테스트 및 검증]({% post_url 2026-06-11-azure-terraform-project-03 %})
