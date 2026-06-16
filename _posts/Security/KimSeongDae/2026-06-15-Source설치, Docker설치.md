---
title: Source 직접 설치, Docker 설치
date: 2026-06-15
categories:
  - security
comments: true
tags:
  - Docker
---
---

apache.org

hadoop 빅데이터 시스템?

하둡 에코시스템 (Hadoop EcoSystem)

bz2 > gz 30%

![](../../../assets/images/Security/KimSeongDae/2026-06-15-Source설치,%20Docker설치/file-20260616092610756.png)

https://downloads.apache.org/httpd/httpd-2.4.68.tar.bz2

docker -> iptables 설치됨 브릿지 연결 -> 자동 포트 오픈


dnf install -y wget, bzip2, tar



![](../../../assets/images/Security/KimSeongDae/2026-06-15-Source설치,%20Docker설치/file-20260616093300047.png)

유닉스 x86 돌아감 -> linux

https://downloads.apache.org/apr/apr-1.7.6.tar.bz2
https://downloads.apache.org/apr/apr-1.7.6.tar.gz

![](../../../assets/images/Security/KimSeongDae/2026-06-15-Source설치,%20Docker설치/file-20260616094017753.png)

![](../../../assets/images/Security/KimSeongDae/2026-06-15-Source설치,%20Docker설치/file-20260616094028641.png)

https://downloads.apache.org/apr/apr-util-1.6.3.tar.bz2
https://downloads.apache.org/apr/apr-util-1.6.3.tar.gz

tar xvfj로 압축해제

```bash
   ./configure --prefix=/apr
   make
   make install
```

![](../../../assets/images/Security/KimSeongDae/2026-06-15-Source설치,%20Docker설치/file-20260616094434083.png)

dnf install -y gcc

![](../../../assets/images/Security/KimSeongDae/2026-06-15-Source설치,%20Docker설치/file-20260616094742202.png)

![](../../../assets/images/Security/KimSeongDae/2026-06-15-Source설치,%20Docker설치/file-20260616094840516.png)

![](../../../assets/images/Security/KimSeongDae/2026-06-15-Source설치,%20Docker설치/file-20260616094901769.png)

![](../../../assets/images/Security/KimSeongDae/2026-06-15-Source설치,%20Docker설치/file-20260616095034733.png)

![](../../../assets/images/Security/KimSeongDae/2026-06-15-Source설치,%20Docker설치/file-20260616095130097.png)

	make 시 오류 생김 -> 나중에 큰 문제생김

dns install -y expat-devel


--> apr, apr-util 완료


![](../../../assets/images/Security/KimSeongDae/2026-06-15-Source설치,%20Docker설치/file-20260616095416357.png)

![](../../../assets/images/Security/KimSeongDae/2026-06-15-Source설치,%20Docker설치/file-20260616095443405.png)

![](../../../assets/images/Security/KimSeongDae/2026-06-15-Source설치,%20Docker설치/file-20260616095524208.png)

	pcre.org -> pcre -> 8.45 -> pcre-8.45.tar.bz2 (링크주소복사)
	뒤에 /download가 붙을거임 그거 지우고 wget


![](../../../assets/images/Security/KimSeongDae/2026-06-15-Source설치,%20Docker설치/file-20260616095651553.png)

	tar xvfj pcre-..
	./configure --prefix=/pcre

![](../../../assets/images/Security/KimSeongDae/2026-06-15-Source설치,%20Docker설치/file-20260616095758429.png)
![](../../../assets/images/Security/KimSeongDae/2026-06-15-Source설치,%20Docker설치/file-20260616095813784.png)

	c++도 설치

make && make install: make성공 시 make install 실행
make || make install: make 실패시 make install 실행
make; make install: make 끝나면 성공/실패 유무 상관없이 make install


![](../../../assets/images/Security/KimSeongDae/2026-06-15-Source설치,%20Docker설치/file-20260616100118751.png)

	왜 없지 -> 경로잘못됨

https://downloads.apache.org/httpd/httpd-2.4.68.tar.bz2
https://downloads.apache.org/httpd/httpd-2.4.68.tar.gz



![](../../../assets/images/Security/KimSeongDae/2026-06-15-Source설치,%20Docker설치/file-20260616100214828.png)

	make && make install 실행

https://sourceforge.net/projects/pcre/files/pcre/8.45/pcre-8.45.tar.bz2
https://sourceforge.net/projects/pcre/files/pcre/8.45/pcre-8.45.tar.gz

![](../../../assets/images/Security/KimSeongDae/2026-06-15-Source설치,%20Docker설치/file-20260616100335865.png)

	expat-devel을 나중에 설치해서 생기는 문제 -> 젤 먼저 설치해야 함


---

## 다시 진행

```bash
dnf install -y wget tar gcc gcc-c++ expat-devel
```



![](../../../assets/images/Security/KimSeongDae/2026-06-15-Source설치,%20Docker설치/file-20260616102752976.png)
./configure --prefix=/web/apr
./configure --prefix=/web/aprutil --with-apr=/web/apr
./configure --prefix=/web/pcre
./configure --prefix=/usr/local/apache2 --with-apr=/web/apr --with-apr-util=/web/aprutil --with-pcre=/web/pcre/bin/pcre-config

![](../../../assets/images/Security/KimSeongDae/2026-06-15-Source설치,%20Docker설치/file-20260616103539673.png)

![](../../../assets/images/Security/KimSeongDae/2026-06-15-Source설치,%20Docker설치/file-20260616103904263.png)


![](../../../assets/images/Security/KimSeongDae/2026-06-15-Source설치,%20Docker설치/file-20260616103712520.png)


##### 환경변수 설정
![](../../../assets/images/Security/KimSeongDae/2026-06-15-Source설치,%20Docker설치/file-20260616104336079.png)

![](../../../assets/images/Security/KimSeongDae/2026-06-15-Source설치,%20Docker설치/file-20260616104508987.png)

경로 지정없이 바로 시작 가능


---
다시2

```bash
mkdir /web #나중에 삭제할때 편함
cd /web
dnf install -y wget tar gcc gcc-c++ expat-devel #expat-devel 미리 설치하지 않으면 오류남
wget .bz/.gz
tar xvfj #bz2일때
tar xvfz #gz일때
```

https://downloads.apache.org/apr/apr-1.7.6.tar.bz2
https://downloads.apache.org/apr/apr-1.7.6.tar.gz


https://downloads.apache.org/apr/apr-util-1.6.3.tar.bz2
https://downloads.apache.org/apr/apr-util-1.6.3.tar.gz


https://downloads.apache.org/httpd/httpd-2.4.68.tar.bz2
https://downloads.apache.org/httpd/httpd-2.4.68.tar.gz


https://sourceforge.net/projects/pcre/files/pcre/8.45/pcre-8.45.tar.bz2
https://sourceforge.net/projects/pcre/files/pcre/8.45/pcre-8.45.tar.gz

![](../../../assets/images/Security/KimSeongDae/2026-06-15-Source설치,%20Docker설치/file-20260616105904387.png)

![](../../../assets/images/Security/KimSeongDae/2026-06-15-Source설치,%20Docker설치/file-20260616105950945.png)

```bash
cd apr-1.7.6
./configure --prefix=/web/apr
make && make install

cd ../apr-util-1.6.3
./configure --prefix=/web/aprutil \
--with-apr=/web/apr
make && make install

cd ../pcre-8.45
./configure --prefix=/web/pcre
make && make install

cd ../httpd-2.4.68
./configure --prefix=/usr/local/apache2 \
--with-apr=/web/apr \
--with-apr-util=/web/aprutil \
--with-pcre=/web/pcre/bin/pcre-config
make && make install

vi /root/.bashrc #PATH:/usr/local/apache2/bin 추가
su - root
apachectl start

ss -nat #80포트 열어줘야됨을 확인
firewall-cmd --add-port=80/tcp

vi /usr/local/apache2/htdocs/index.html
```

![](../../../assets/images/Security/KimSeongDae/2026-06-15-Source설치,%20Docker설치/file-20260616112637245.png)

	source설치 후 web 구동 성공

--> 삭제
```bash
apachectl stop
ss -nat #listen 중인 80포트 있는지 확인
rm -rf /usr/local/apache2/
rm -rf /web
```


---

## docker 설치

```bash
dnf install -y dnf-plugins-core
dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

dnf -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
systemctl enable --now docker

docker search httpd
docker pull httpd

docker run -itd -p 60080:80 --name h1 httpd
docker ps -a

docker exec -it h1 /bin/bash
echo 'JHJANG-DOCKER-WEB' > htdocs/index.html
```

![](../../../assets/images/Security/KimSeongDae/2026-06-15-Source설치,%20Docker설치/file-20260616114028752.png)

##### it works -> 메인페이지변경 -> 이미지화

![](../../../assets/images/Security/KimSeongDae/2026-06-15-Source설치,%20Docker설치/file-20260616114404087.png)

먼저 로그인

```bash
docker run -itd -p 60080:80 --name h1 httpd
docker ps -a

docker exec -it h1 /bin/bash
```

![](../../../assets/images/Security/KimSeongDae/2026-06-15-Source설치,%20Docker설치/file-20260616114858300.png)


##### 이미지 생성 시 주의할 점

![](../../../assets/images/Security/KimSeongDae/2026-06-15-Source설치,%20Docker설치/file-20260616114939789.png)

![](../../../assets/images/Security/KimSeongDae/2026-06-15-Source설치,%20Docker설치/file-20260616115020838.png)

![](../../../assets/images/Security/KimSeongDae/2026-06-15-Source설치,%20Docker설치/file-20260616115035871.png)

해당 이미지를 다른 사람과 공유하기 위해 hub.docker.com에 업로드 하고 싶음

##### 리포지토리 제작

![](../../../assets/images/Security/KimSeongDae/2026-06-15-Source설치,%20Docker설치/file-20260616115228249.png)

![](../../../assets/images/Security/KimSeongDae/2026-06-15-Source설치,%20Docker설치/file-20260616115330529.png)

이미지의 이름을 바꿔줘야함

![](../../../assets/images/Security/KimSeongDae/2026-06-15-Source설치,%20Docker설치/file-20260616115524683.png)

해쉬값이 동일하면 이미지는 하나만 가지고 있음

![](../../../assets/images/Security/KimSeongDae/2026-06-15-Source설치,%20Docker설치/file-20260616115605918.png)

![](../../../assets/images/Security/KimSeongDae/2026-06-15-Source설치,%20Docker설치/file-20260616115625589.png)

public repository에 h1.0 이미지가 잘 올라간걸 확인 가능


---

## nginx 올려보기

내용 바꾸고 -> n1.0

docker run -itd -p 60580:80 --name n2 nginx
docker exec -it n1 /bin/bash
