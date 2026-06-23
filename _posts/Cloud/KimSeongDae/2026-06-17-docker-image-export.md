---
title: Docker 이미지 내보내기 및 다른 서버로 옮기기
date: 2026-06-17
categories:
  - cloud
comments: true
tags:
  - docker
---
---

## 서버1 → 서버2 이미지 옮기기

Archive 방식을 가장 많이 씀

![](../../../assets/images/Cloud/KimSeongDae/2026-06-17-docker-image-export/file-20260617092334952.png)

![](../../../assets/images/Cloud/KimSeongDae/2026-06-17-docker-image-export/file-20260617092412214.png)

이게 없다면 wordpress는 정상동작하지않음

```bash
docker pull wordpress

docker pull mysql:8.0

dockerimages
docker save -o all.tar alpine busybox httpd mysql:8.0 nginx rockylinux/rockylinux wordpress
```


	하나의 파일을 묶고 풀면 거기에 풀어짐

![](../../../assets/images/Cloud/KimSeongDae/2026-06-17-docker-image-export/file-20260617101649068.png)

##### rocky9-2

![](../../../assets/images/Cloud/KimSeongDae/2026-06-17-docker-image-export/file-20260617101732095.png)


![](../../../assets/images/Cloud/KimSeongDae/2026-06-17-docker-image-export/file-20260617103014084.png)

에러가 왜날까? 

![](../../../assets/images/Cloud/KimSeongDae/2026-06-17-docker-image-export/file-20260617102939017.png)

![](../../../assets/images/Cloud/KimSeongDae/2026-06-17-docker-image-export/file-20260617102952083.png)

컨테이너를 복제하면 환경변수값이 초기화됨
그래서 임포트할때 추가해줘야 함

![](../../../assets/images/Cloud/KimSeongDae/2026-06-17-docker-image-export/file-20260617103244166.png)

![](../../../assets/images/Cloud/KimSeongDae/2026-06-17-docker-image-export/file-20260617103347398.png)

환경변수는 초기화되지만 나머지는 유지됨


--> 환경변수는 초기화되서 별로 좋아보이지않음


---

##### httpd

![](../../../assets/images/Cloud/KimSeongDae/2026-06-17-docker-image-export/file-20260617111531836.png)

![](../../../assets/images/Cloud/KimSeongDae/2026-06-17-docker-image-export/file-20260617111652407.png)

![](../../../assets/images/Cloud/KimSeongDae/2026-06-17-docker-image-export/file-20260617111741364.png)

실행은 되는거같지만 exit상태임 -> 로그를 봐야함

![](../../../assets/images/Cloud/KimSeongDae/2026-06-17-docker-image-export/file-20260617112011745.png)

![](../../../assets/images/Cloud/KimSeongDae/2026-06-17-docker-image-export/file-20260617112018837.png)

