# Ansible 실습 정리

## 1. 초기 세팅

### 1-1. 호스트네임 설정

```bash
hostnamectl set-hostname cont    # 컨트롤 노드
hostnamectl set-hostname node1
hostnamectl set-hostname node2
hostnamectl set-hostname node3
```

### 1-2. SSH 키 생성 및 배포 (cont에서 실행)

```bash
ssh-keygen -m PEM -t rsa -b 2048 -q -N ""

scp .ssh/id_rsa.pub root@10.0.0.11:/root/.ssh/authorized_keys
scp .ssh/id_rsa.pub root@10.0.0.12:/root/.ssh/authorized_keys
scp .ssh/id_rsa.pub root@10.0.0.13:/root/.ssh/authorized_keys
scp .ssh/id_rsa.pub root@10.0.0.14:/root/.ssh/authorized_keys
```

### 1-3. Ansible 설치

```bash
dnf install -y epel-release
dnf install -y ansible
ansible --version
```

---

## 2. 인벤토리 작성

경로: `/etc/ansible/hosts` (ansible 기본 인벤토리 경로 — `-i` 옵션 생략 가능)

```ini
[all]
10.0.0.[11:14]

[node]
10.0.0.12
10.0.0.13
10.0.0.14

[web]
10.0.0.12

[was]
10.0.0.13

[db]
10.0.0.14

[http:children]
web
was
```

> `[http:children]`는 그룹 상속 문법. `http` 그룹에 ping을 날리면 `web`, `was`에 속한 호스트 전체에 적용됨.

---

## 3. Ad-hoc 명령 테스트

```bash
ansible -i /etc/ansible/hosts all -m ping
ansible all -m ping          # -i 생략 가능 (기본 경로라서 동일 동작)
ansible http -m ping         # web + was 그룹
```

---

## 4. 파일/디렉토리 모듈 실습 — 역등성 확인

```bash
ansible node -m file -a "path=/test state=directory"
ansible node -m file -a "path=/test state=absent"
ansible node -m shell -a "ls -al /"
```

`file` 모듈로 삭제(`state=absent`)를 두 번 실행해보면:
- 1회차: `"changed": true` (실제로 삭제)
- 2회차: `"changed": false` (이미 없어서 skip) → **이것이 역등성**

---

## 5. 사용자 생성/삭제 — `shell` vs `user` 모듈 비교

### 5-1. shell로 useradd (역등성 X)

```bash
ansible node -m shell -a "useradd a"
ansible node -m shell -a "tail -5 /etc/passwd"
ansible node -m shell -a "userdel -r a"
ansible node -m shell -a "tail -5 /etc/passwd"
ansible node -m shell -a "ls -al /home"
ansible node -m shell -a "ls -al /var/spool/mail"
```

### 5-2. shell로 비밀번호까지 설정

```bash
ansible node -m shell -a "useradd a; echo 'It1' | passwd --stdin a"
ansible node -m shell -a "tail -5 /etc/passwd"
```

### 5-3. user 모듈 (역등성 O)

```bash
ansible node -m user -a "name=b"
ansible node -m shell -a "tail -5 /etc/passwd"

# 비밀번호까지 지정
ansible node -m user -a "name=n update_password=always password={{ 'It1' | password_hash('sha512') }}"
ansible node -m shell -a "tail -5 /etc/shadow"
```

> ⚠️ 필터명은 `sha512` (오타 주의: `sjha512` 아님)

---

## 6. 플레이북 실습

### 6-1. 디렉토리/파일 생성 플레이북

작업 디렉토리 생성:

```bash
mkdir /file
cd /file
vi test.yml
```

**`test.yml`**

```yaml
---
- name: make file /test
  hosts: node
  gather_facts: false
  ignore_errors: true
  tasks:
    - name: make file test
      file:
        path: /test
        state: touch
        mode: '0777'

    - name: make directory /tbabo
      file:
        path: /tbabo
        state: directory
        mode: '0777'
```

실행:

```bash
ansible-playbook test.yml

# alias 등록해서 사용 가능
alias ap='ansible-playbook'
ap test.yml
```

결과 확인:

```bash
ansible node -m shell -a "ls -al /"
```

### 6-2. 사용자 생성 플레이북

```bash
cd /file
vi user.yml
```

**`user.yml`**

```yaml
---
- name: create user a & password 'It1'
  hosts: web
  gather_facts: false
  ignore_errors: true
  tasks:
    - name: create user a
      user:
        name: a
        update_password: always
        password: "{{ 'It1' | password_hash('sha512') }}"
```

실행:

```bash
ap user.yml
ansible web -m shell -a "tail -5 /etc/shadow"
```

---

## 7. YAML 작성 시 자주 하는 실수 체크리스트

| 잘못된 표기 | 올바른 표기 | 비고 |
|---|---|---|
| `mame:` | `name:` | 오타 |
| `gather_facs` | `gather_facts` | 오타 |
| `ingore_errors: ture` | `ignore_errors: true` | 오타 |
| `ifle:` | `file:` | 오타 |
| `pasth:/etst` | `path: /test` | 오타 + 콜론 뒤 공백 누락 |
| `state:touch` | `state: touch` | 콜론 뒤 공백 필수 |
| `-name make directory` | `- name: make directory` | 하이픈 뒤 공백, `name:` 콜론 필요 |
| `directroy` / `0777` 단독 표기 | `state: directory` / `mode: '0777'` | key: value 형태로 명시 |
| `ansible playbook` | `ansible-playbook` | 하이픈 필수 (별도 명령어) |
| `sjha512` | `sha512` | 해시 알고리즘명 오타 |

---

## 8. 핵심 개념 정리

### 역등성 (Idempotency)
같은 작업을 여러 번 실행해도 시스템 상태가 동일하게 유지되는 성질.

- **보장되는 모듈**: `file`, `user`, `copy`, `template`, `service`, `yum` 등 → 현재 상태 확인 후 다르면 변경, 같으면 skip
- **보장 안 되는 것**: `command`, `shell`, `script` 모듈 → 매번 그대로 실행 (이미 적용된 상태인지 판단 안 함)

역등성이 없는 shell 작업을 흉내내려면:

```yaml
- name: 파일이 없을 때만 스크립트 실행
  shell: /root/setup.sh
  args:
    creates: /root/.setup_done
```

### 인벤토리 기본 경로
`/etc/ansible/hosts`가 기본 경로이므로 `-i` 옵션 생략 가능 (`ansible.cfg`의 `inventory` 값으로 변경 가능)

### 그룹 상속
`[groupname:children]` 문법으로 여러 그룹을 하나로 묶어서 관리 가능
