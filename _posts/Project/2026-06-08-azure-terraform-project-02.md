---
title: Azure + Terraform 프로젝트 (2) - Terraform 코드 작성
date: 2026-06-08
categories:
  - project
comments: true
tags:
  - azure
  - terraform
---
---

00_init.tf

- `version = "=4.74.0"` → 팀원 모두 동일한 버전 사용 보장
- `features {}` → 최소한의 설정만 (불필요한 옵션 제거)
- `subscription_id = var.subid` → 구독 ID를 변수로 관리 (보안)

01_rg.tf

- 모든 리소스의 시작점이라 가장 먼저 생성
- 딱 필요한 두 줄만 (name, location)
- 다른 모든 파일에서 `depends_on = [azurerm_resource_group.tuna_rg]` 로 참조

02_vnet.tf

- VNet만 따로 분리 → 서브넷(`03_sub.tf`)과 역할 구분
- `10.101.x.x` Korea Central / `10.102.x.x` Korea South → IP 대역으로 리전 구분
- `depends_on` → RG 먼저 생성 보장

03_sub.tf

- VNet과 서브넷 분리 → 수업 스타일 + 역할 명확화
- `default_outbound_access_enabled = false` → vmss, bastion, gateway 서브넷은 직접 인터넷 차단 (NAT GW 경유 강제)
- `default_outbound_access_enabled = true` → appgw는 인터넷 통신 필요
- `GatewaySubnet`, `AzureBastionSubnet` → Azure 규칙상 이름 고정

04_pubip.tf

- `Static` → IP 고정 (Traffic Manager 엔드포인트 등록 시 IP 변경되면 안 됨)
- `sku = "Standard"` → AppGW WAF_v2는 Standard SKU 공인 IP 필수 (Basic 사용 시 배포 오류), 교수님 코드에는 없는데 교수님은 일반 LB 사용이라 생략 가능했음
- `domain_name_label` → Traffic Manager가 AppGW를 엔드포인트로 등록하려면 DNS 레이블 필수
- `zones = ["1","2","3"]` → vpngw1만 적용, Korea Central은 가용성 영역 지원 / Korea South는 미지원이라 vpngw2엔 생략
- `ip_version` 생략 → 기본값이 IPv4라 명시 불필요




골든 이미지 방식이 실무에서는 더 좋지만, 저희는 Terraform 단일 실행으로 완전 자동화를 구현하기 위해 install.sh 방식을 채택했습니다.


배포 순서에 따라 install.sh가 작동되는 vmss도 존재
시간을 늦춰서 배포 진행
