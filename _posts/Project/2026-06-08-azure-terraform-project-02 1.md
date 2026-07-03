---
title: "Azure 클라우드 인프라 및 M365 Defender 보안 구축 (2) — Terraform 코드 설계"
date: 2026-06-08
categories:
  - project
comments: true
tags:
  - azure
  - terraform
---

## 개요

아키텍처 설계를 바탕으로 실제 **Terraform 코드를 파일 단위로 분리 설계**한 단계.
단순히 동작하는 코드가 아니라, "왜 이렇게 나눴는지 / 왜 이 옵션을 썼는지"에 대한 설계 근거를 정리했다.

**핵심 키워드**: Terraform 모듈 분리 · 변수(Variable) 관리 · outbound 정책 · Golden Image vs 부트스트랩 스크립트

---

## 파일별 설계 근거

### `00_init.tf` — Provider 설정

- `version = "=4.74.0"` : 팀원 전체가 동일한 provider 버전을 쓰도록 고정
- `features {}` : 불필요한 옵션 없이 최소한으로 유지
- `subscription_id = var.subid` : 구독 ID를 변수로 분리해 코드에 하드코딩하지 않음 (보안)

### `01_rg.tf` — 리소스 그룹

- 모든 리소스의 시작점이라 가장 먼저 생성
- `name`, `location` 딱 두 줄만 정의
- 이후 모든 리소스에서 `depends_on = [azurerm_resource_group.tuna_rg]`로 참조해 생성 순서를 보장

### `02_vnet.tf` — 가상 네트워크

- VNet을 서브넷(`03_sub.tf`)과 파일 자체를 분리해 역할을 명확히 구분
- IP 대역으로 리전을 구분: `10.101.x.x` → Korea Central / `10.102.x.x` → Korea South
- `depends_on`으로 리소스 그룹이 먼저 생성되도록 보장

### `03_sub.tf` — 서브넷

- VNet-서브넷 분리는 수업에서 배운 스타일을 따르되, 역할 구분을 더 명확히 함
- `default_outbound_access_enabled = false` : VMSS, Bastion, Gateway 서브넷은 직접 인터넷 아웃바운드를 차단하고 NAT Gateway를 경유하도록 강제
- `default_outbound_access_enabled = true` : App Gateway는 인터넷 통신이 필요해 예외 처리
- `GatewaySubnet`, `AzureBastionSubnet` : Azure 정책상 이름이 고정되어 있어 그대로 사용

### `04_pubip.tf` — 공용 IP

- `Static` : IP를 고정해야 Traffic Manager 엔드포인트 등록 시 IP가 바뀌지 않음
- `sku = "Standard"` : App Gateway WAF_v2는 Standard SKU 공인 IP가 필수 (Basic 사용 시 배포 오류 발생) — 강사님 예제 코드는 일반 LB를 사용해 이 옵션이 없었지만, WAF_v2에서는 반드시 필요했음
- `domain_name_label` : Traffic Manager가 App Gateway를 엔드포인트로 등록하려면 DNS 레이블이 필수
- `zones = ["1","2","3"]` : `vpngw1`에만 적용. Korea Central은 가용성 영역을 지원하지만 Korea South는 미지원이라 `vpngw2`에는 생략
- `ip_version`은 기본값이 IPv4라 별도로 명시하지 않음

---

## 배포 자동화 방식: Golden Image vs 부트스트랩 스크립트

> 골든 이미지 방식이 실무에서는 더 널리 쓰이지만, 이번 프로젝트에서는 **Terraform 단일 실행으로 완전 자동화**하는 것이 목표였기 때문에 `install.sh` 부트스트랩 스크립트 방식을 채택했다.

- 배포 순서에 따라 `install.sh`가 동작하는 VMSS가 별도로 존재
- 의존 관계가 있는 리소스는 배포 시점을 의도적으로 늦춰서 순차 진행되도록 구성

---

## 정리

- Terraform 파일을 역할별로 잘게 쪼개두면, 나중에 특정 리소스만 수정할 때 영향 범위를 파악하기 쉬웠다.
- `default_outbound_access_enabled` 같은 세부 옵션 하나하나에도 "왜 true/false로 설정했는지" 이유가 있었기 때문에, 코드만 보고 넘어가지 않고 각 옵션의 배경을 기록해두는 습관이 유용했다.
