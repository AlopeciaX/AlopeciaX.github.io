---
title: Azure + Terraform 실습 (3) - VNet 피어링, VPN
date: 2026-05-28
categories:
  - cloud
comments: true
tags:
  - azure
  - terraform
---
---

### 오늘 목표

> 
1. 서로 다른 Vnet에 존재하는 VM을 통신시키는 방법
	1.1. public ip 사용
	1.2. VPN으로 vnet을 연결
	1.3. Express Route
		전용 회선필요
		비용 비쌈
	1.4. Vnet Peering
		비용 저렴




 vpn사용 이유
	2.1. 암호화
	2.2. 종단간 신뢰성확보

site to site : ipsec
point to site: ssl

IaC Ansible 자동화

---

### 테라폼

![](../../../assets/images/Cloud/KimSeongDae/2026-05-28-azure-terraform-03/file-20260528094550895.png)

	어제 한 부분에서 변수로 생성


> 서로 다른 네트워크대역의 가상머신끼리 통신을 하려면?

1. 가상머신 생성(web1, web2)
2. 인바운드 규칙 설정 (icmpv4 추가)

![](../../../assets/images/Cloud/KimSeongDae/2026-05-28-azure-terraform-03/file-20260528101810016.png)

![](../../../assets/images/Cloud/KimSeongDae/2026-05-28-azure-terraform-03/file-20260528101923828.png)

3. 피어링 추가

![](../../../assets/images/Cloud/KimSeongDae/2026-05-28-azure-terraform-03/file-20260528102243536.png)![](../../../assets/images/Cloud/KimSeongDae/2026-05-28-azure-terraform-03/file-20260528102417081.png)

##### 04_pubip.tf
![](../../../assets/images/Cloud/KimSeongDae/2026-05-28-azure-terraform-03/file-20260528114209505.png)

##### 05_nic.tf
![](../../../assets/images/Cloud/KimSeongDae/2026-05-28-azure-terraform-03/file-20260528122638982.png)

