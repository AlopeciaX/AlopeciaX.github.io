---
title: kubectl 실습 - emptyDir 볼륨
date: 2026-07-08
categories:
  - cloud
comments: true
tags:
  - kubernetes
---
---
### 1단계. MySQL용 ConfigMap 생성 (환경변수 파일 방식)

bash

```bash
mkdir /conf
cd /conf
vi mysqlconf
```

bash

```bash
MYSQL_ROOT_PASSWORD=It12345!
MYSQL_DATABASE=word
MYSQL_USER=jhjang
MYSQL_PASSWORD=It12345!
```

`--from-env-file`로 ConfigMap 생성:

bash

```bash
kubectl create configmap mysqlenv --from-env-file=mysqlconf
kubectl get configmaps
kubectl get configmap mysqlenv -o yaml
```

**참고:** 이 방식은 파일을 `key=value` 형태로 읽어서 ConfigMap의 `data` 필드로 그대로 넣어줍니다. YAML을 직접 쓸 필요 없이 간단하게 만들 수 있는 방법입니다.

---

### 2단계. MySQL Pod 배포

bash

```bash
vi mysql.yml
```

yaml

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: mysql
  labels:
    app: mysql
    env: devel
spec:
  containers:
  - name: m1
    image: mysql:8.0
    imagePullPolicy: IfNotPresent
    ports:
    - containerPort: 3306
    envFrom:
    - configMapRef:
        name: mysqlenv
```

bash

```bash
kubectl apply -f mysql.yml --dry-run=server   # 문법/검증만, 실제 생성 안 됨
kubectl apply -f mysql.yml                    # 실제 생성 (이 명령이 빠지면 안 됨!)
kubectl get pods -o wide
```

MySQL 접속 테스트 (Pod IP로 직접):

bash

```bash
mysql -uroot -pIt12345! -h [Pod IP주소]
```

---

### 3단계. MySQL Pod를 Service로 노출

Pod IP는 재시작하면 바뀌기 때문에, 다른 Pod(WordPress)가 안정적으로 접근하려면 Service가 필요합니다.

bash

```bash
kubectl expose pod mysql --name svc-mysql --port 3306
```

**주의:** 옵션 순서는 `--name svc-mysql`이 먼저, 그 다음 `pod mysql`이 와야 합니다.

확인:

bash

```bash
kubectl get pods,svc
kubectl get pods -A
```

---

### 4단계. 클러스터 내부 DNS 동작 확인

bash

```bash
kubectl run alpine --image alpine
kubectl get pods    # alpine, mysql 모두 Running/Ready 확인
kubectl exec mysql -- nslookup svc-mysql
```

**참고:** `nslookup svc-mysql`이 정상 응답하면, 클러스터 내부에서 `svc-mysql`이라는 이름만으로 MySQL Pod에 접근 가능하다는 뜻입니다. WordPress가 DB 주소로 이 이름을 쓸 수 있게 됩니다.

---

### 5단계. WordPress용 ConfigMap 생성

bash

```bash
vi wordconf
```

bash

```bash
MYSQL_DB_HOST=svc-mysql
MYSQL_DB_USER=jhjang
MYSQL_DB_PASSWORD=It12345!
MYSQL_NAME=word
```

bash

```bash
kubectl create configmap wordenv --from-env-file=wordconf
kubectl get configmaps
```

**주의:** `MYSQL_DB_HOST` 값은 앞에서 만든 Service 이름(`svc-mysql`)과 정확히 일치해야 합니다. 오타가 있으면(`svcmysql` 등) WordPress가 DB를 못 찾아서 계속 install 화면이 뜨거나 접속 에러가 납니다.

---

### 6단계. WordPress Pod 배포

bash

```bash
vi word.yml
```

yaml

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: word
  labels:
    app: wordpress
    env: devel
spec:
  containers:
  - name: w1
    image: wordpress
    imagePullPolicy: IfNotPresent
    ports:
    - containerPort: 80
    envFrom:
    - configMapRef:
        name: wordenv
```

bash

```bash
kubectl apply -f word.yml
kubectl get pods -o wide
```

---

### 7단계. WordPress Pod도 Service로 노출

브라우저에서 접속하려면 NodePort로 열어야 합니다.

bash

```bash
kubectl expose pod word --name svc-word --port 80 --type NodePort
kubectl get svc
```

`PORT(S)` 항목에서 `80:3XXXX/TCP` 형태로 나오는 포트 번호를 확인하고, 브라우저에서 아래 주소로 접속합니다.

```
http://[워커노드IP]:3XXXX
```

---

1.configmap 파일 2개를 작성합니다. yaml
  1.1 wordnev(wordpress 환경변수), mysqlenv(mysql환경변수)를 각각 작성합니다.
2.mysql pod를 생성해서 clusterip로 노출합니다.
3.wordpress를 deployment로 복제본을 5개 생성합니다.
4.wordpress는 nodeport로 외부에 공개합니다. 30000
5.실제 PC에서 각각의 hostip:nodeport로 접속해 봅니다.

![](../../../assets/images/Cloud/KimSeongDae/2026-07-08-kubenetes-emptydir%202/file-20260708110149359.png)

![](../../../assets/images/Cloud/KimSeongDae/2026-07-08-kubenetes-emptydir%202/file-20260708110207079.png)

![](../../../assets/images/Cloud/KimSeongDae/2026-07-08-kubenetes-emptydir%202/file-20260708110126387.png)

