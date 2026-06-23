---
title: Nessus & OpenVAS 취약점 스캔 진행
date: 2026-05-26
categories:
  - security
comments: true
tags:
  - 취약점진단
---
---
## Nessuss & OpenVAS 로 취약점 검사

**Nessus**

```bash
systemctl enable --now nessusd

# 만약 똑같이 안뜨면
systemctl restart nessusd
```

	접속 주소: https://127.0.0.1:8834

![](../../../assets/images/Network/VM-Setup/2026-05-26-nessus-openvas-scan/file-20260523124621031.png)
![](../../../assets/images/Network/VM-Setup/2026-05-26-nessus-openvas-scan/file-20260523124640722.png)

![](../../../assets/images/Network/VM-Setup/2026-05-26-nessus-openvas-scan/file-20260523131025495.png)

![](../../../assets/images/Network/VM-Setup/2026-05-26-nessus-openvas-scan/file-20260523131151176.png)

![](../../../assets/images/Network/VM-Setup/2026-05-26-nessus-openvas-scan/file-20260523131206650.png)

![](../../../assets/images/Network/VM-Setup/2026-05-26-nessus-openvas-scan/file-20260523131131915.png)

	타겟 ip주소 입력



**OpenVAS**

```bash
gvm-check-setup
gvm-start
```

	접속 주소: https://127.0.0.1:9392

![](../../../assets/images/Network/VM-Setup/2026-05-26-nessus-openvas-scan/file-20260523131509516.png)

	gvm-setup할때 admin/password 를 알려주는데 이거 꼭 기억하고 사이트에서 비번 바꿔주기

![](../../../assets/images/Network/VM-Setup/2026-05-26-nessus-openvas-scan/file-20260523132227791.png)

![](../../../assets/images/Network/VM-Setup/2026-05-26-nessus-openvas-scan/file-20260523132315809.png)

