---
title: 5. Azure 클라우드 행위기반 보안탐지 및 대응
date: 2026-07-20
categories:
  - project
comments: true
tags:
  - azure
  - terraform
  - security
  - cdr
  - project
---
---
진행중

센티널, 탐지대응


팀즈 이메일 생성(알람용)

![](../../assets/images/_posts/Project/2026-07-20-azure-cloud-CDR-project/file-20260713162955494.png)

관리자 계정으로 추가
-> 먼가 문제..

![](../../assets/images/_posts/Project/2026-07-20-azure-cloud-CDR-project/file-20260713164704838.png)

![](../../assets/images/_posts/Project/2026-07-20-azure-cloud-CDR-project/file-20260713171554616.png)

워드 프레스 초기 설정
## sentinel

![](../../assets/images/_posts/Project/2026-07-20-azure-cloud-CDR-project/file-20260713165002280.png)

### 웹 쉘 업로드 공격

![](../../assets/images/_posts/Project/2026-07-20-azure-cloud-CDR-project/file-20260713172632681.png)

![](../../assets/images/_posts/Project/2026-07-20-azure-cloud-CDR-project/file-20260713172642508.png)

![](../../assets/images/_posts/Project/2026-07-20-azure-cloud-CDR-project/file-20260713172552416.png)

OWASP CRS 933xxx(PHP Injection) 룰이 매치되고 누적 이상 점수가 임계값을 넘어서 최종적으로 Blocked됨을 확인가능 --> 웹쉘 업로드 탐지 정상 작동

+추가로 /wp-admin, /wp-login.php 경로 - AllowWpPaths 커스텀 룰로 Allowed 처리됨을 확인 가능 --> WordPress 정상 사용 방해하지 않는지 검증

#### Sentinel 규칙 검증

