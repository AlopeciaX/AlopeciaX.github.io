---
title: ARP Poisoning & DNS Spoofing 실습 - Ettercap
date: 2026-05-20
categories:
  - security
comments: true
tags:
  - 모의해킹
---

---

## 취약점이 없는 시스템 공격 유형

패치가 완료된 시스템이라도 **서비스 자체의 구조적 취약점**을 이용한 공격이 가능하다.

### 1. DHCP Starvation (DDoS 공격)

```
1. 클라이언트가 Discover 메시지 전송
2. DHCP 서버는 Mac Address 검증 없이 Offer 메시지 응답
3. 공격자가 Mac Address를 위조해 대량의 Discover 메시지 전송
4. DHCP 서버의 IP 자원이 고갈됨
5. 정상 클라이언트는 IP를 할당받지 못함
```

> **DHCP Starvation 공격** → IP 자원 고갈로 인한 서비스 거부

#### 🛡️ 방어
```
NAC 장비(IP/Mac Address 관리) 도입
Mac Address 필터링 기능 활성화
```

---

### 2. DNS Cache Poisoning

```
1. 사용자가 URL 조회 요청
2. DNS 서버가 외부 순환쿼리 수행
3. 응답 Name Server의 응답을 검증하지 않음
4. 공격자가 Public DNS에 가짜 응답을 지속 전송
5. Public DNS가 가짜 응답을 Cache에 저장
6. 이후 사용자에게 공격자의 IP 주소를 전달
```

> **DNS Cache Poisoning 공격** → 사용자를 악성 사이트로 유도

#### 🛡️ 방어
```
DNSSEC(DNS Security Extensions) 적용
DNS 응답 검증 활성화
신뢰할 수 있는 DNS 서버만 사용
```

---

### 3. SSH 터널링을 이용한 방화벽 우회

```
1. 사용하지 않는 원격데스크탑(RDP) 서비스를 구성
2. 방화벽에서 해당 포트를 차단
3. 공격자가 SSH 터널링을 이용해 차단된 서비스에 우회 접속
```

> 고객의 요구사항 이외의 서비스는 임의로 구성하지 말 것

#### 🛡️ 방어
```
불필요한 서비스는 아예 비활성화 (방화벽 차단만으로는 부족)
SSH 포트 접근을 허용된 IP만으로 제한
```

---

## 핵심 용어 정리

| 용어 | 설명 | 구분 |
|---|---|---|
| **위험 (Risk)** | 특정 위협이 취약점을 이용해 발생할 수 있는 잠재적 손실/피해 가능성 | - |
| **위협 (Threat)** | 모든 잠재적인 원인 (조직 or 시스템) | 외부적 요인 |
| **취약점 (Vulnerability)** | 보안상의 허점 (System, Application) | 내부적 요인 |

---

## ARP Poisoning 실습 (Ettercap)

### 실습 환경

| 머신 | IP |
|---|---|
| Kali (공격자) | 10.0.0.41 |
| Metasploitable3 (meta3) | 10.0.0.31 |
| Windows 10 (w10) | 10.0.0.178 |

---

### STEP 1. Ettercap 실행

```bash
ettercap -G &
```

> 호스트 스캔 시 IPv6로 뜨는 경우 아래 명령어로 IPv6 비활성화 후 재시작
> (처음부터 정상적으로 뜨면 생략 가능)

```bash
echo 0 > /proc/sys/net/ipv6/conf/all/disable_ipv6
```

---

### STEP 2. 호스트 스캔

```
돋보기 아이콘 클릭 → 호스트 목록 확인
```

---

### STEP 3. 타겟 지정

```
10.0.0.31  → Add to Target 1  (meta3)
10.0.0.178 → Add to Target 2  (w10)
```

---

### STEP 4. ARP Poisoning 시작

```
지구본 아이콘 → ARP Poisoning
→ Sniff remote connections ✅ 체크 → OK
```

---

### STEP 5. 연결 확인

```
View → Connections
```

---

### STEP 6. ARP 테이블 확인

```bash
# 각 머신에서 실행
arp -a
```

#### 결과 비교

| 머신 | ARP 테이블 상태 |
|---|---|
| meta3 | 10.0.0.178(w10) MAC → **칼리 MAC으로 변조** |
| w10 | 10.0.0.31(meta3) MAC → **칼리 MAC으로 변조** |
| kali | 두 머신의 **진짜 MAC 주소** 보유 (중간 전달용) |

> 피해자들은 정상 통신 중인 줄 알지만 모든 패킷이 칼리를 경유함

---

### STEP 7. 이미지 스니핑

```bash
driftnet -i eth0
```

> HTTP 사이트에서만 동작 (HTTPS는 암호화로 불가)

---

### 플래그 / 파일 복원

HEX 데이터를 PNG로 변환:

```bash
# %PNG 시작 부분부터만 남기고 앞부분 제거 후 변환
xxd -r -p hexfile.txt output.png
```

> `%PNG` 부터 시작하도록 앞부분을 제거한 뒤 변환

---

## DNS Spoofing 실습

### 실습 환경

| 머신 | IP | 역할 |
|---|---|---|
| Windows 10 | 10.10.34.131 | 피해자 |
| Metasploitable3 | 10.10.34.132 | 원래 웹서버 |
| DNS 서버 | 10.10.34.133 | DNS 서버 |
| Kali | 10.10.34.134 | 공격자 |

### 실습 목적

```
피해자가 웹서버(brk.local)에 접속할 때
칼리의 가짜 웹페이지로 리다이렉트 시키기
```

---

### 실습 구성도

```
피해자(131) → DNS 쿼리(brk.local) → DNS서버(133)
                                         ↑
                              칼리(134)가 중간에서 가로채
                              가짜 IP(134)로 응답
                                         ↓
                              피해자 → 칼리 웹페이지 접속
```

---

### 각 머신 역할

**DNS 서버 (10.10.34.133)**

```bash
# DNS 서비스 설치 및 실행
systemctl enable --now named
firewall-cmd --permanent --add-port=53/{tcp,udp}
firewall-cmd --reload
```

> brk.local 존 파일에서 A 레코드로 meta3 IP를 등록
> ns1에는 DNS 서버 IP를 등록

**Metasploitable3 (10.10.34.132)**

```
IIS 서비스로 실제 웹 서비스 구동 중
RDP 포트(3389) 오픈
```

**피해자 PC (10.10.34.131)**

```
DNS 서버 주소를 10.10.34.133으로 설정
brk.local 접속 시도
```

```
DNS 설정 전  : 10.10.34.132 로 직접 접속
DNS 설정 후  : brk.local 로 접속 (meta3 웹페이지)
스푸핑 성공 후: brk.local 로 접속 시 칼리 웹페이지 표시
```

**Kali (10.10.34.134)**

```bash
# 1. ettercap 실행
ettercap -G &

# 2. 타겟 지정
Target 1 : 10.10.34.131 (피해자)
Target 2 : 10.10.34.133 (DNS 서버)

# 3. ARP Poisoning 시작
지구본 → ARP Poisoning → Sniff remote connections ✅ → OK

# 4. etter.dns 설정
cat /etc/ettercap/etter.dns
```

```
# etter.dns 내용
brk.local    A    10.10.34.134
*.brk.local  A    10.10.34.134
```

```bash
# 5. dns_spoof 플러그인 활성화
Plugins → Manage Plugins → dns_spoof 더블클릭
```

---

### DNS 캐시 관련

```
DNS 캐시 저장 위치 : /etc/hosts
피해자 PC에서 DNS 캐시 초기화 : ipconfig /flushdns
```

---

## SSL 사용 이유

```
1. 데이터 암호화    → 중간자 공격(ARP Poisoning 등)으로 가로채도 내용 확인 불가
2. 종단 간 신뢰성  → 서버 인증서로 진짜 서버임을 검증
```

> HTTPS 사이트는 Ettercap으로 스니핑해도 내용을 볼 수 없는 이유

---

## 실습 과제

```
wireshark, winpcap 다운로드 후 설치
```

> 가급적 게이트웨이 주소는 **정적으로 설정**하는 것을 권장

---

## 팀별 IP 대역

| 팀 | IP 대역 |
|---|---|
| 1팀 | 10.10.34.101 ~ 110 |
| 2팀 | 10.10.34.111 ~ 120 |
| 3팀 | 10.10.34.121 ~ 130 |
| 4팀 | 10.10.34.131 ~ 140 **(나)** |

---

## 칼리 브릿지 모드 설정

```
칼리 VM → 네트워크 어댑터 → Bridged로 변경
→ 같은 네트워크 팀원들의 패킷 스니핑 가능
```

---

## 프로젝트

- **시스템 모의해킹** 수행
- 보고서 직접 작성
- 테라폼(Terraform) 활용 → Azure 자동화 추가 예정

> 참고: https://www.kali.org/tools
