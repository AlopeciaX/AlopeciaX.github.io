---
title: "[요약] 시스템 모의해킹 프로젝트 — Metasploitable3 (Windows/Linux)"
date: 2026-05-22
categories:
  - project
comments: true
tags:
  - 모의해킹
  - 취약점진단
  - 요약
---
---
## 프로젝트 목표

PTES 방법론을 기반으로 Metasploitable3 (Windows/Linux) 2대를 대상으로 **정보 수집 → 취약점 진단 → 익스플로잇 → 권한 상승 → 플래그 수집**까지 전 과정을 수행하고, 검증된 취약점에 대한 보안 권고안을 도출한다.

**기술 스택**: Nmap · Nessus · OpenVAS · Metasploit Framework · Kali Linux

---

## 진단 결과 한눈에 보기

| 대상 | 발견 취약점 | 최종 결과 |
|---|---|---|
| Windows (10.0.0.31) | 272건 (Nessus+OpenVAS) | Administrator 권한 획득 |
| Linux (10.0.0.51) | 102건 (Nessus+OpenVAS) | root 권한 획득 |

> 🖼️ *사진 자리 — 위험도별 취약점 통계 그래프 (보고서 4p 요약 페이지)*

---

## 핵심 성과

- Windows 15개 / Linux 10개, 총 25개의 서로 다른 익스플로잇 경로로 침투 검증
- EternalBlue, BlueKeep, PwnKit 등 **Critical급 취약점을 실제로 익스플로잇까지 성공**
- 자동화 스캐너가 못 잡는 Jenkins Script Console, UnrealIRCd 백도어를 **수동 분석으로 추가 발견**
- 스테가노그래피, QR 코드 분할, Port Knocking 등 다양한 은닉 기법이 적용된 **플래그 25개 전량 수집**

---

## 트러블슈팅 / 어려웠던 점

| 이슈 | 대응 |
|---|---|
| Hard mode 플래그 4개를 일반 환경에서 찾을 수 없음 | GitHub에서 Metasploitable3 소스를 직접 클론, Vagrant/VirtualBox 환경을 새로 구성해 플래그 파일 경로 확인 |
| Windows/Linux 취약점이 상당수 겹쳐 우선순위 구분이 애매함 | 원격 접근·인증 여부·MSF 모듈 존재 여부 3가지 기준 + CVSS 점수로 8단계 우선순위 표 수립 |
| 자동화 도구만으로 놓치는 취약점 존재 | Nmap 결과를 수동으로 재분석해 자동 스캐너 미탐지 취약점 추가 발굴 |

---

## 느낀점

"관리자 권한을 뺏는 것만 위험하다"는 생각이 깨진 프로젝트였다. TrackPopupMenu, PwnKit 같은 권한 상승 취약점 하나만으로도 충분히 치명적이라는 걸 직접 확인했다. 아쉬운 점은 meterpreter 세션 획득 이후 상대 시스템에 남은 로그를 분석하지 못한 것과, 정리한 보안 권고사항을 실제로 적용해 재검증하지 못한 것 — 다음 프로젝트에서 보완하고 싶다.

---

## 상세 포스트

- [전체 보고서 요약 — 진단 개요부터 결론까지]({% post_url 2026-05-22-vuln-report-01 %})
- [Nmap 스캔 & 익스플로잇 상세 (Windows/Linux)]({% post_url 2026-05-25-nmap-portscan %})
