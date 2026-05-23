---
title: 칼리 리눅스 한글화
date: 2026-05-21
categories:
  - security
comments: true
tags:
  - Kali
  - install
---
---
## nessuss & openvas 설치

**nessuss 설치**

	먼저 nessus .deb 파일을 다운 받는다.
	그리고 Kali의 바탕화면으로 끌어다 놓는다.(안되면 복붙)

```bash
cd ~/Desktop/

dpkg -i Nessus-10.10.1-debian10_amd64.deb #설치한 파일명
```

	일반 사용자 계정일 경우 앞에 sudo를 붙여줘야 가능

**openvas 설치**
```bash
apt install -y gvm postgresql

gvm-setup
gvm-check-setup
gvm-start
```

