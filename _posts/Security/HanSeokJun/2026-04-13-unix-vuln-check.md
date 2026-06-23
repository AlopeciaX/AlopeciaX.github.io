---
title: UNIX 취약점 점검 - startx, crontab, r계열 서비스
date: 2026-04-13
categories:
  - security
comments: true
tags:
  - unix
  - 취약점진단
---
---

	UNIX => X Windows
	
	startx
	
	BASH shell script => UNIX 취약점 점검
	
	crontab으로 공격자가 수비자 pc로 들어가서 예약 파일 실행
	
	불필요한 r계열 서비스 활성화 여부 확인
	-> systemctl list-units --type=service | grep -E "rlogin|rsh|rexec"
	
	
	

