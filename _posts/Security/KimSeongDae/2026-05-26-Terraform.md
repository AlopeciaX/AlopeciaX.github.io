---
title: Azure + Terraform
date: 2026-05-26
categories:
  - security
comments: true
tags:
  - 모의침투
  - Azure
  - Terraform
---
---
**클라우드 정의**

	1. 언제 어디서나 어떠한 단말을 사용하더라도 인터넷 접속만 가능하다면
	관리자의 개입없이 원하는 서비스(리소스)를 비용을 지불하고 즉각적으로 이용할 수 있다.
		1.1. 5가지 특징
			1.1.1. On-Demand Self-Service
			1.1.2. Broad Network Access
			1.1.3. Measured Service
			1.1.4. Rapid Elasticity
			1.1.5. Resource Pooling
	2. 공유 책임 모델
		2.1. IaaS : 인프라(Hardware, 네트워크, 컴퓨팅(OS)) - MySQL, PHP + APP + Data
		2.2. PaaS : 개발환경 제공, - App, Data
		2.3. SaaS : Software 제공(완전관리형 모델)
	3. Public Cloud + Private Cloud (Hybrid Cloud)
		3.1. Multi Hybrid Cloud
		3.2. 통합된 관리 환경


**클라우드 최초**

	1.AWS(Amazone Web Service): Black Friday, 


**Azure 사용법**

	1. Resource 그룹 생성
	2. 가상 네트워크 생성
		2.1. 만약에 Azure Bastion 사용할거면 443포트 열어줘야하고, outbound로 ssh, rdp 열어줘야 함
		2.2. 특수한 서비스는 서브넷 용도로 지정해줘야 함
		2.3. 서브넷 크기는 최소 /16, 최대 /29
		2.4. 프라이빗 서브넷 체크 해제 (외부에서 접속가능(bastion이라))
		2.5. web1, web2는 프라이빗 체크
		2.6. 사용 가능한 IP가 251개인 이유?: 처음,끝은 안되고, 1,2,3은 Azure에서 DHCP로 사용중이기 때문
		2.7. public id는 미리 만들어두는게 좋음
		2.8. 테라폼은 NIC를 미리 만들어놔도 됨 Azure는 안됨
	3. 공용 IP 주소 만들기
		3.1. 리소스 가서 공용 ip 주소 확인
		3.2. 공용 ip 접두사 만들기 (20.249.126.32/31 이렇게 나오면 32,33 쓸 수 있음)
		


![](../../../assets/images/Security/KimSeongDae/2026-05-26-Terraform/file-20260526113444185.png)