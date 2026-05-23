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
## Metasploitable3-ub1404 설정

	user: vagrant / pw: vagrant

![](../../../assets/images/Security/VM-Setup/2026-05-23-Metas3-ub1404_settings/file-20260523113947009.png)

![](../../../assets/images/Security/VM-Setup/2026-05-23-Metas3-ub1404_settings/file-20260523114925625.png)

```bash
sudo nano /etc/network/interfaces
sudo ifdown eth0 && ifup eth0

reboot

ip a
```

	수정 뒤에는 Ctrl+O -> Enter -> Ctrl+X
	부팅 하고 ip a 명령어를 쳤을 때 설정한 ip로 변경되어 있으면 성공

