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

![](../../../assets/images/Security/VM-Setup/2026-05-21-kali_korean/file-20260521232704508.png)

![](../../../assets/images/Security/VM-Setup/2026-05-21-kali_korean/file-20260521232839308.png)

	먼저 칼리에 들어오면 root 비번부터 설정해준다 그리고 재부팅 후 root로 로그인


![](../../../assets/images/Security/VM-Setup/2026-05-21-kali_korean/file-20260521233039931.png)

	2026.1 버전부터는 update를 하지 않으면 한글화가 안되는 것 같다.

![](../../../assets/images/Security/VM-Setup/2026-05-21-kali_korean/file-20260521233051385.png)


![](../../../assets/images/Security/VM-Setup/2026-05-21-kali_korean/file-20260521233221691.png)

![](../../../assets/images/Security/VM-Setup/2026-05-21-kali_korean/file-20260521233211797.png)

	체크하고 OK

![](../../../assets/images/Security/VM-Setup/2026-05-21-kali_korean/file-20260521233303255.png)

```bash
cat << EOF >> ~/.xprofile
export GTK_IM_MODULE=fcitx
export QT_IM_MODULE=fcitx
export XMODIFIERS="@im=fcitx"
EOF
```

	코드를 그대로 복사해서 붙여넣기

![](../../../assets/images/Security/VM-Setup/2026-05-21-kali_korean/file-20260521233345035.png)

	그리고 reboot

![](../../../assets/images/Security/VM-Setup/2026-05-21-kali_korean/file-20260521233420274.png)
