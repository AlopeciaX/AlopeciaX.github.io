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
## Kali Linux 2026.1 설치 가이드 <3>

**한글화**

![](../../../assets/images/Security/VM-Setup/2026-05-21-kali_korean/file-20260522002730693.png)

```bash
sudo passwd root
# 자신 계정 비번
# root 비번 설정
# root 비번 재입력
reboot
```

![](../../../assets/images/Security/VM-Setup/2026-05-21-kali_korean/file-20260522002813341.png)

	root로 로그인

```bash
sudo apt install -y ibus ibus-hangul fonts-nanum*
reboot
```

![](../../../assets/images/Security/VM-Setup/2026-05-21-kali_korean/file-20260522002938974.png)

![](../../../assets/images/Security/VM-Setup/2026-05-21-kali_korean/file-20260521233420274.png)

	root 계정으로 접속

![](../../../assets/images/Security/VM-Setup/2026-05-21-kali_korean/file-20260522003041723.png)

![](../../../assets/images/Security/VM-Setup/2026-05-21-kali_korean/file-20260522003119088.png)


![](../../../assets/images/Security/VM-Setup/2026-05-21-kali_korean/file-20260522003353818.png)

![](../../../assets/images/Security/VM-Setup/2026-05-21-kali_korean/file-20260522003420693.png)

![](../../../assets/images/Security/VM-Setup/2026-05-21-kali_korean/file-20260522004131722.png)

![](../../../assets/images/Security/VM-Setup/2026-05-21-kali_korean/file-20260522003620060.png)

	vi 사용법
	키보드 i 입력 -> 방향키 아래 -> 기존에 있던 C지우고 ko_KR.UTF-8 넣기 -> esc -> 키보드 :wq 입력
	i : insert 모드 (편집 가능하다)
	:wq : 저장

![](../../../assets/images/Security/VM-Setup/2026-05-21-kali_korean/file-20260522004150692.png)

	reboot 해주기

![](../../../assets/images/Security/VM-Setup/2026-05-21-kali_korean/file-20260522003952560.png)

	한글 폰트로 바뀐걸 확인 가능하다
	예전 이름 유지를 선택한다. (바꾸면 실습하기 힘들어짐)

![](../../../assets/images/Security/VM-Setup/2026-05-21-kali_korean/file-20260522004039477.png)

	한글도 안깨지고 잘 입력되는걸 볼 수 있다.
	(vi로 .profile 수정안하면 한글 깨짐)

![](../../../assets/images/Security/VM-Setup/2026-05-21-kali_korean/file-20260522004251517.png)

	root는 영어로 바꿨지만 일반 계정은 한글로 바뀐걸 볼 수 있다.

![](../../../assets/images/Security/VM-Setup/2026-05-21-kali_korean/file-20260522004938660.png)

	vi ~/.config/user-dirs.dirs 로 들어간다.

![](../../../assets/images/Security/VM-Setup/2026-05-21-kali_korean/file-20260522004920015.png)

	키보드로 :%d 를 입력한 뒤 밑의 코드를 붙여넣는다.
	그리고 :wq 로 저장해준다.

```bash
XDG_DESKTOP_DIR="$HOME/Desktop"
XDG_DOWNLOAD_DIR="$HOME/Downloads"
XDG_TEMPLATES_DIR="$HOME/Templates"
XDG_PUBLICSHARE_DIR="$HOME/Public"
XDG_DOCUMENTS_DIR="$HOME/Documents"
XDG_MUSIC_DIR="$HOME/Music"
XDG_PICTURES_DIR="$HOME/Pictures"
XDG_VIDEOS_DIR="$HOME/Videos"
```

![](../../../assets/images/Security/VM-Setup/2026-05-21-kali_korean/file-20260522005348871.png)

	reboot해주고 확인해본다. 

![](../../../assets/images/Security/VM-Setup/2026-05-21-kali_korean/file-20260522000555102.png)

![](../../../assets/images/Security/VM-Setup/2026-05-21-kali_korean/file-20260522000705130.png)

![](../../../assets/images/Security/VM-Setup/2026-05-21-kali_korean/file-20260522001135246.png)

	배경화면뿐만 아니라 한글까지 잘 되는걸 볼 수 있다.

