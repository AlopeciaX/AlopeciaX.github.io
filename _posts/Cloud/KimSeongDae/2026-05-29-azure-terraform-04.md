---
title: Azure + Terraform 실습 (4) - NSG, NIC 구성
date: 2026-05-29
categories:
  - cloud
comments: true
tags:
  - azure
  - terraform
---
---

##### 1. NSG 생성

##### 05_nic.tf

![](../../../assets/images/Cloud/KimSeongDae/2026-05-29-azure-terraform-04/file-20260529094056733.png)


##### 06_nsg.tf

![](../../../assets/images/Cloud/KimSeongDae/2026-05-29-azure-terraform-04/file-20260529094019686.png)

##### 07_natgw.tf

![](../../../assets/images/Cloud/KimSeongDae/2026-05-29-azure-terraform-04/file-20260529095326639.png)

![](../../../assets/images/Cloud/KimSeongDae/2026-05-29-azure-terraform-04/file-20260529095541602.png)

	ip 주소 잘 할당됐는지 확인


##### 2. 가상머신

![](../../../assets/images/Cloud/KimSeongDae/2026-05-29-azure-terraform-04/file-20260529122031888.png)

	전체적인 구조

##### 3. 나만의 도메인 연결

![](../../../assets/images/Cloud/KimSeongDae/2026-05-29-azure-terraform-04/file-20260529123139180.png)

	네임서버도 azure껄로 변경

![](../../../assets/images/Cloud/KimSeongDae/2026-05-29-azure-terraform-04/file-20260529123626918.png)

	네임서버 변경

##### DNS