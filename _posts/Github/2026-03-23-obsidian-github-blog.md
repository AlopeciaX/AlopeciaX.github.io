---
title: Obsidian + GitHub 블로그 연동 가이드
date: 2026-03-23
categories:
  - github
comments: true
tags:
  - obsidian
  - git
---
---
## 개요

Obsidian을 GitHub 블로그와 연동해서 글을 작성하고 자동으로 업로드하는 설정 가이드다.
에러 없이 처음부터 끝까지 따라할 수 있도록 순서대로 정리했다.

---

## STEP 1 — Git 설치

**1. Git 설치 확인**

```bash
git --version
```

버전 번호가 나오면 OK. 없으면 [git-scm.com](https://git-scm.com)에서 설치 후 다시 확인.

**2. Git 사용자 정보 등록 (최초 1회)**

```bash
git config --global user.name "GitHub아이디"
git config --global user.email "GitHub이메일"
```

---

## STEP 2 — GitHub 레포 클론

**1. 저장할 폴더로 이동**

```bash
cd C:\Users\본인이름\원하는폴더
```

**2. 레포 클론**

```bash
git clone https://github.com/GitHub아이디/GitHub아이디.github.io
```

**3. 클론 확인**

```bash
cd GitHub아이디.github.io
git status
```

> `nothing to commit, working tree clean` 이 뜨면 정상

---

## STEP 3 — Obsidian 설정

**1. Obsidian 실행 후 보관함 열기**
- Obsidian 실행
- 보관함 선택 화면에서 [보관함 폴더 열기] → [열기] 클릭
- 방금 클론한 폴더 선택

**2. .obsidian 폴더 gitignore 처리**

```bash
echo .obsidian/ >> .gitignore
git add .gitignore
git commit -m "Add .obsidian to gitignore"
git push
```

**3. Obsidian Git 플러그인 설치**
- 설정(⚙️) → 커뮤니티 플러그인 → 탐색
- `Git` 검색 (개발자: Vinzent)
- 설치 → 활성화

---

## STEP 4 — Git 플러그인 설정

설정(⚙️) → 커뮤니티 플러그인 → Git 옆 ⚙️ 클릭

| 설정 항목 | 값 |
|---|---|
| Auto commit-and-sync interval | 20 (분) |
| Auto pull interval | 10 (분) |
| Pull on startup | 켜기 ✅ |
| Author name for commit | GitHub 아이디 |
| Author email for commit | GitHub 이메일 |

---

## STEP 5 — 블로그 글 작성

**1. 파일 위치 및 이름 규칙**

```
_posts/카테고리/YYYY-MM-DD-제목.md
```

**2. Front Matter 작성**

모든 포스트 파일 맨 위에 아래 내용을 반드시 넣어야 한다.

```yaml
---
title: "글 제목"
date: 2026-03-23
categories: [카테고리명]
comments: true
---
```

---

## STEP 6 — 깃허브에 올리기

**자동 업로드**

설정한 대로 20분마다 자동으로 커밋 + 푸시된다.

**수동 즉시 업로드**

```
Ctrl + P → Git: Commit-and-sync → Enter
```

> GitHub Actions가 빌드하는 데 1~2분 소요. 바로 반영 안 되면 잠깐 기다릴 것.

---

## 트러블슈팅

| 증상 | 해결 방법 |
|---|---|
| Git is not ready | 보관함이 Git 레포가 아님 → 클론 폴더를 보관함으로 열기 |
| push 오류 | git config로 이름/이메일 등록됐는지 확인 |
| 블로그에 글이 안 보임 | 파일명 날짜 형식 확인 (YYYY-MM-DD), Front Matter 확인 |
| 자동 푸시 안 됨 | Auto commit-and-sync interval 값이 0인지 확인 |
