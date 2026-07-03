---
title: Azure 클라우드 인프라 및 M365 Defender 보안 구축 (3) — 테스트 및 검증
date: 2026-06-11
categories:
  - project
comments: true
tags:
  - azure
  - terraform
---
---
## 개요

구축한 하이브리드 클라우드 인프라(그룹웨어 서비스)가 설계 의도대로 동작하는지 검증한 단계. 네트워크 연결, VPN 통신, 웹 서비스 접근, DB 연동, Auto Scaling, Failover까지 항목별로 확인했다.

---

## VPN 연결 검증

- **Azure 측**: Azure Portal에서 Korea Central 리전 VPN Gateway ↔ 온프레미스 간 Site-to-Site VPN 터널이 `Connected` 상태인 것을 확인
- **온프레미스(BlueMax) 측**: IPSec VPN 이벤트 로그에서 Azure 양 리전과의 터널이 `ESTABLISHED` 상태로 수립되고, CHILD_SA 협상이 정상 완료된 것을 확인
- **트래픽 검증**: BlueMax 방화벽 정책 Hit Count 기준, Korea Central VMSS에서 6,724건, Korea South VMSS에서 350건의 MySQL 트래픽이 정책을 통과 — 양 리전 모두 VPN 경유 DB 접근이 정상 동작함을 확인

> 🖼️ *사진 자리 — Azure Portal VPN Connection 상태 화면 + BlueMax IPSec 연결 로그 화면*

## 그 외 검증 항목

- **DB Server 연동**: VMSS → 온프레미스 MySQL 접속 정상 확인
- **Application Gateway / WAF**: 트래픽 분산 및 웹 방화벽 정책 정상 적용
- **VMSS Auto Scaling**: 부하 증가 시 자동 확장 정책 정상 동작
- **Traffic Manager Failover**: 리전 장애 상황을 가정한 장애 조치 시나리오에서 정상 리전으로 트래픽 전환 확인
- **Key Vault**: 비밀정보(DB 계정, 인증서 등) 관리 체계 정상 구성 확인

## 종합 검증 결과

| 검증 항목 | 결과 |
|---|---|
| Site-to-Site VPN 연결 | 성공 |
| 온프레미스 DB 연동 | 성공 |
| Private DNS 조회 | 성공 |
| Application Gateway 연동 | 성공 |
| WAF 정책 적용 | 성공 |
| VMSS 구성 | 성공 |
| Auto Scaling 정책 적용 | 성공 |
| Traffic Manager 구성 | 성공 |
| Key Vault 구성 | 성공 |

> 🖼️ *사진 자리 — Auto Scaling 동작 화면 / Traffic Manager Failover 테스트 화면*

---

## 정리

- 설계했던 항목 9가지를 모두 실제로 검증하며 마무리했다. 특히 VPN 트래픽을 **Azure 쪽 로그와 온프레미스(BlueMax) 쪽 로그 양쪽에서 교차 확인**한 게 포인트 — 한쪽만 보고 "연결됐다"고 판단하지 않고, 실제 트래픽이 정책을 통과하는지까지 확인했다.
- Auto Scaling과 Traffic Manager Failover처럼 "장애 상황을 가정한 테스트"는 실제 운영 환경에서의 안정성을 미리 검증해볼 수 있는 좋은 경험이었다.
