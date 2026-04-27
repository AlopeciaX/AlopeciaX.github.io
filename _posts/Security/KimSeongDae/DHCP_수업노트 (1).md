# 네트워크 서비스 수업 정리 (2026-04-27)

> 📌 **교수님 강조 사항**: 기본 명령어(`ls`, `cd`), 설정 파일 위치, VI 편집기

---

## 1. 포트 (Port)

| 범위 | 구분 |
|---|---|
| 0 ~ 1023 | Well-known Port |
| 1024 ~ 49151 | 등록된 포트 |
| 49152 ~ 65535 | 동적 포트 (임의로 사용 가능) |

### Well-known Port 목록

| 포트 | 서비스 | 비고 |
|---|---|---|
| 20 | FTP (데이터) | Active mode일 때만 사용 |
| 21 | FTP (제어) | |
| 22 | SSH | |
| 23 | Telnet | |
| 25 | SMTP | |
| 53 | DNS | 기본 UDP / 특정 경우 TCP 사용 |
| 110 | POP3 | |
| 143 | IMAP | |
| 990~995 | SSL | |

> **DNS가 TCP를 사용하는 경우**
> 1. 전송 데이터가 512byte 초과
> 2. 영역 전송 (Zone Transfer)

---

## 2. DHCP (Dynamic Host Configuration Protocol)

### 2-1. 개념

- **IP 자동 할당** 프로토콜
- IP 자원의 효율적 관리
  - 회사 PC가 10,000대인 경우 고정 IP를 사용하면 10,000개의 IP Address 필요
  - 휴가 등의 사유로 출근하지 않는 직원들의 PC는 DHCP를 사용하면 IP 자원 낭비 없음
- **Protocol**: UDP
- **Port**: Server 67 / Client 68

### 2-2. 초기 동작 구조 (4-way Handshake, Broadcast)

```
Client                        DHCP Server
  |                                |
  |---[1. Discover, Broadcast]--->|   DHCP 서버를 찾는 메시지를 Network 전체에 전송
  |                                |
  |<--[2. Offer, Broadcast]--------|   IP Address, Subnetmask, 서버주소, 임대시간, DNS, Gateway 제안
  |                                |
  |---[3. Request, Broadcast]---->|   해당 IP 사용여부를 다시 한 번 확인
  |                                |
  |<--[4. ACK, Unicast]------------|   최종 서비스 IP Address, Subnetmask, 서버주소, 임대시간, DNS, Gateway 전달
```

> - **1/2 번**: Broadcast
> - **3/4 번**: Unicast
> - 임대 시간 **1/2** 시점에 재갱신 시도 → 실패 시 **7/8** 시점에 재시도 → 만료(Expire) 시 APIPA 할당

![](Pasted%20image%2020260427094046.png)
![525](Pasted%20image%2020260427094443.png)

### 2-3. APIPA (Automatic Private IP Addressing)

- DHCP 서버로부터 IP를 받지 못한 경우 자동 할당되는 주소
- 대역: `169.254.x.x`

### 2-4. 브로드캐스트 vs 다이렉트 브로드캐스트

- **다이렉트 브로드캐스트**: 서브넷 외부에서 해당 서브넷의 브로드캐스트 주소로 전송 가능
  - 네트워크 범위를 넘어서기 때문에 **Smurf Attack** 발생 가능
  - 예) `10.0.0.0/24`의 전체 범위: `10.0.0.0 ~ 10.0.0.255` → `10.0.0.255`가 브로드캐스트 (Smurf Attack 대상)

---

## 3. Linux DHCP 서버 설정 실습

### 3-1. 실습 조건

| 항목 | 값 |
|---|---|
| 네트워크 | `10.0.0.0/24` |
| 사용 가능 범위 | `10.0.0.1 ~ 10.0.0.254` |
| 서버 운영 대수 | 30대, 고정 IP, 앞쪽부터 순차 사용 (`10.0.0.1 ~ 10.0.0.30`) |
| Gateway | 네트워크 마지막 IP → `10.0.0.254` |
| DHCP 서버 위치 | 11번째 서버 → `10.0.0.11` |
| 기본 임대시간 | 2시간 → `7200` |
| 최대 임대시간 | 4시간 → `14400` (최대 임대시간 ≥ 기본 임대시간) |
| DNS 1차 | KT(kornet) → `168.126.63.1` |
| DNS 2차 | Google → `8.8.8.8` |

### 3-2. 설치 및 설정

```bash
# 설치
dnf install dhcp-server

# 설정 파일 편집
vi /etc/dhcp/dhcpd.conf
```

**VI 편집기 내에서 예시 파일 불러오기**

```vim
:$r /usr/share/doc/dhcp-server/dhcpd.conf.example
```

![](Pasted%20image%2020260427102117.png)

**example 파일 내용 확인**

![](Pasted%20image%2020260427102128.png)

```vim
:1,51d      " 1번째 줄부터 51번째 줄까지 삭제
:10,28d     " 10번째 줄부터 28번째 줄까지 삭제
:14,$d      " 14번째 줄부터 마지막 줄까지 삭제
```

### 3-3. dhcpd.conf 설정 예시

```apache
subnet 10.0.0.0 netmask 255.255.255.0 {
    range 10.0.0.31 10.0.0.253;
    option domain-name-servers 168.126.63.1, 8.8.8.8;
    option domain-name "example.local";
    option routers 10.0.0.254;
    default-lease-time 7200;
    max-lease-time 14400;
}
```

> 참고 — example 파일에서 남긴 기본 구조

![](Pasted%20image%2020260427112505.png)

> 실습 완성본 (jhjang.local 기준)

![](Pasted%20image%2020260427112505.png)

```bash
# 시작 + 자동실행 동시 설정
systemctl enable --now dhcpd

# 상태 확인
systemctl status dhcpd

# 오류 발생 시 로그 확인
journalctl -xe
```

### 3-5. Windows 클라이언트에서 확인

```cmd
ipconfig /release    :: IP 강제 해제
ipconfig /renew      :: IP 재할당
ipconfig /all        :: IP 정보 전체 확인
```

**W10-1 결과**
![](Pasted%20image%2020260427115718.png)

**W11-1 결과**
![](Pasted%20image%2020260427120042.png)

### 3-6. DHCP 서버 완전 제거

```bash
dnf autoremove -y dhcp-server    # 의존성까지 삭제
rm -rf /etc/dhcp/                # 설정 파일 삭제
rm -rf /var/lib/dhcpd/           # 임대 정보 삭제
```

---

## 4. DHCP 예약 기능 (MAC 주소 고정 IP 할당)

- 특정 MAC 주소를 가진 장비에 항상 동일한 IP를 할당

### 4-1. MAC 주소 확인 및 변경

- **MAC 주소 구성**: 제조회사 고유번호 / 제조사 일련번호
- VMware에서 MAC 주소 변경 가능 (Virtual Network 설정)
- Windows: 네트워크 어댑터 → 고급 → **Locally Administered Address** 에서 변경

![[1777274052818_image.png]]

> MAC 주소 변경 후 ipconfig /all 확인

![[1777274055513_image.png]]

### 4-2. dhcpd.conf 예약 설정

```apache
host w10 {
    hardware ethernet 00:0C:29:A0:1E:0A;
    fixed-address 10.0.0.101;
}

host w11 {
    hardware ethernet 00:0C:29:65:C3:42;
    fixed-address 10.0.0.201;
}
```

> 실제 MAC 주소 사용 버전

![[1777274050970_image.png]]

> 테스트용 단순 MAC 주소 버전 (00:00:00:00:00:01/02)

![[1777274057718_image.png]]

**VI에서 MAC 주소 형식 변환 (- → :)**

```vim
:11s/-/:/g          " 11번째 줄의 - 를 : 로 전부 교체
:10,13co$           " 10~13번째 줄을 복사해서 맨 끝에 붙여넣기
```

---

## 5. VI 편집기 정리

### 5-1. 편집 모드 진입 키

| 키 | 동작 |
|---|---|
| `a` | 커서 뒤에서 편집 시작 |
| `i` | 커서 앞에서 편집 시작 |
| `o` | 아래 줄 추가 후 편집 |
| `s` | 한 글자 지우고 편집 |
| `A` | 줄 끝으로 이동 후 편집 |
| `I` | 줄 맨 앞으로 이동 후 편집 |
| `O` | 위에 줄 추가 후 편집 |
| `S` | 해당 줄 전체 삭제 후 편집 |

### 5-2. 명령 모드 주요 명령어

| 명령어 | 설명 |
|---|---|
| `:wq` | 저장 후 종료 |
| `:q!` | 저장하지 않고 강제 종료 |
| `u` | 실행 취소 (Undo) |
| `Ctrl + r` | 다시 실행 (Redo) |
| `:se nu` | 줄 번호 표시 |
| `:se nonu` | 줄 번호 숨기기 |
| `:1,Nd` | 1번 줄부터 N번 줄까지 삭제 |
| `:Ns/찾기/바꾸기/g` | N번 줄에서 전체 치환 |
| `:N,Mco$` | N~M번 줄 복사하여 맨 끝에 붙여넣기 |
| `!명령어` | VI 안에서 쉘 명령어 실행 |
| `:!bash` | VI에서 쉘로 이동 (`exit`으로 복귀) |
| `$r !ls -al` | ls -al 결과를 파일 끝에 추가 |
| `Ctrl + l` | 터미널 화면 정리 |

---

## 6. Windows Server DHCP 설정 실습

### 6-1. 실습 조건

![[1777274037842_image.png]]
![[1777274069492_image.png]]

| 항목 | 값 |
|---|---|
| 네트워크 | `10.0.0.0/24` |
| 서버 운영 대수 | 40대, 고정 IP (`10.0.0.1 ~ 10.0.0.41`) |
| Gateway | `10.0.0.254` |
| DHCP 서버 위치 | 12번째 서버 → `10.0.0.12` |
| 기본 임대시간 | 1시간 → `3600` |
| 최대 임대시간 | 1시간 → `3600` |
| DNS 1차 | Google → `8.8.8.8` |
| DNS 2차 | KT(kornet) → `168.126.63.1` |
| Domain Name | `이니셜.local` |
| 예약 | w10-1 → 백한 번째 IP (`10.0.0.101`) / w11-1 → 이백일 번째 IP (`10.0.0.201`) |

### 6-2. 설치 방법

```
관리 → 역할 및 기능 추가 → 역할(DHCP 서버) 선택 → 설치
```

> - **역할**: 실질적 기능 (DHCP, DNS, AD 등)
> - **기능**: 역할을 보조하는 서브 기능

### 6-3. DHCP 범위 설정 순서

```
도구 → DHCP → IPv4 우클릭 → 새 범위
→ 범위 이름 설정 (예: DHCP_Test)
→ IP 범위 설정 (1 ~ 254)
→ 제외 범위 설정 (고정 IP 사용 구간)
→ 임대 기간 설정
→ 도메인 이름, DNS 서버 설정
→ WINS 사용 안 함
→ 예약 설정
```

> **서브넷 지연 시간**: 초 단위. 다른 DHCP 서버들이 우선적으로 응답하도록 지연 설정

### 6-4. DHCP 제거 방법

```
DHCP 관리자 → 범위 우선 삭제
→ 서버 관리자 → 역할 및 기능 제거 → DHCP 체크 해제 → 제거
```

> Windows DHCP 관리자 화면 (예약 포함)

![[1777274066551_image.png]]

> 예약 후 W10-1 ipconfig /all 결과 (10.0.0.101 고정 할당 확인)

![[1777274072077_image.png]]

---

## 7. Windows Server 초기 설정 (5가지 필수)

1. **서버 호스트네임** 설정
2. **가상 드라이버** 설치
3. **전원 옵션** 설정 (`control`)
4. **Windows 업데이트 비활성화** (`services.msc` → Windows Update 서비스 중지/사용 안 함)
5. **IP 설정**

> Azure에서는 가상머신 이름 = 호스트 이름 (default)

---

## 8. Sysprep (하드웨어 초기화)

- VM 복제 시 하드웨어 정보가 동일해지는 문제 해결
- `sysprep` 실행 → **일반화** 체크 → 재부팅 → 하드웨어 정보 초기화
- 애플리케이션 영역은 변경되지 않음

> **템플릿(Template)에서는**: 종료 옵션을 **시스템 종료**로 설정

```
whoami /all  → SID 확인 (sysprep 전후로 SID가 달라짐)
```

**Sysprep 전 (복제 직후 — SID 동일)**
![[1777274062558_image.png]]

**Sysprep 후 (일반화 완료 — SID 변경됨)**
![[1777274064610_image.png]]

---

## 9. 모의해킹 환경 구성 (예고)

- Windows 2008 취약점 활용 예정
- Ubuntu 기반 Metasploitable 2 필요 (다운로드 필요)
- `.vmx` 파일 더블클릭 → VMware 자동 등록

### Windows Server Standard vs Datacenter

| 구분 | Standard | Datacenter |
|---|---|---|
| Hyper-V 가상머신 수 | 제한 있음 | 무제한 |
| 데스크톱 환경 | 선택 가능 | 선택 가능 |

> 데스크톱 환경 미선택 시 GUI 없이 텍스트 모드로만 동작

---

## 📌 자격증 추천

- **AZ-104** (Microsoft Azure Administrator)
- **AZ-700** (Azure Network Engineer)
- **정보보안기사**
