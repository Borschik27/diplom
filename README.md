# Дипломный проект по специальности DevOps

## Задача дипломного проекта

1. Подготовить облачную инфраструктуру на базе облачного провайдера Яндекс.Облако.
2. Запустить и сконфигурировать Kubernetes кластер.
3. Установить и настроить систему мониторинга.
4. Настроить и автоматизировать сборку тестового приложения с использованием Docker-контейнеров.
5. Настроить CI для автоматической сборки и тестирования.
6. Настроить CD для автоматического развёртывания приложения.

## Пояснение

Дипломный проект состоит из 6 частей, каждая часть будет выведена в отдельном блоке.

Краткое пояснение по выполнения я приложу сразу и так-же пояснения будут по ходу выполнения задания

### Terraform

1. Все дефолтные переменные для проекта описанны в `default.auto.tfvars`
2. Персональные переменные (которые не стоит помещать в репоситорий) находяться в `personal.auto.tfvars` 
3. Бэкэдн использует `S3 YC бакет` для хранения `terraform.tfstate` (не помещен в репозиторий)
4. Виртуальные машины по большей части описаны в `terraform.tfvars`
5. Файл `outputs.tf` выводит параметры которые нужно быстро получить после выполнеия деплоя

### VPC/Subnet/IP

1. Создается одна сеть
2. В ней создаются 2 подсети (public,cluster) в каждой из зон доступности `ru-a` `ru-b` `ru-d`, зоны представленны как `list(string)` и вызываются с помощью `count=length()`
3. Для сервисных машин `nat` и `external-lb` резервируются статические публичные адреса, для `jump` адрес динамика

### VM resources

В ходе создания проекта создаются виртуальные машины, описывается рендер `cloud-init` для групп машин, iso-образы, таблица маршрутизации/группа безопастности (стоит учесть что используя внешний балансировщик нагруски нужно настроить разрешения ingress/egress, но в дальнейшем было просто открыты все порты так как с некоторыми сервисами я не смог разобраться) по ходу выполнения рабы возникали с этим проблемы и в файле `kuber.md` описаны решения. Автоматически рендериться `hosts.yaml` для `ansible`

Виртуальные машины:

1. 3 `NAT-instance` для выдачи доступа в интернет для подсети `cluster` из каждой зоны доступности
2. 3 `HA-Proxy` которые завязаны на внешний балансировщик нагрузки для создания `kubernetes` клаcтера высокой доступности
3. 3 `kubertenes-master` по 1 в каждой зоне
4. 6 `kubernetes-worker` по 2 в каждой зоне
5. 1 `Jump-Server` так как я решил что настройка всех серверов будет с помощью `ansible` и так как я очень ленив `:)` было решено поднять один такой узел через который с помощью ProxyJump я буду подключаться к хостам у которыз нет внешнего IP

### Ansible

Для настройки и подготовки всех узлов будет использоваться ansible, который через proxyjump будет раскатывать роли, jump работает через ssh ключ локальной машины который был установлен в машины через `cloud init`

Структура `Ansible` :

```

ansible/
├── ansible.cfg
├── ansible_log
├── inventory
│   └── hosts.yaml
├── playbooks
│   └── site.yaml
└── roles
    ├── jump
    │   ├── README.md
    │   ├── defaults
    │   │   └── main.yml
    │   ├── files
    │   ├── handlers
    │   │   └── main.yml
    │   ├── meta
    │   │   └── main.yml
    │   ├── tasks
    │   │   └── main.yml
    │   ├── templates
    │   ├── tests
    │   │   ├── inventory
    │   │   └── test.yml
    │   └── vars
    │       └── main.yml
    ├── keep-ha
    │   ├── defaults
    │   │   └── main.yml
    │   ├── files
    │   │   └── haproxy.cfg
    │   ├── handlers
    │   │   └── main.yml
    │   ├── tasks
    │   │   └── main.yml
    │   ├── templates
    │   └── vars
    │       └── main.yml
    ├── kuber
    │   ├── defaults
    │   │   └── main.yml
    │   ├── files
    │   │   ├── init-config-example.yaml
    │   │   └── metallb-confmap-example.yaml
    │   ├── handlers
    │   │   └── main.yml
    │   ├── tasks
    │   │   └── main.yml
    │   ├── templates
    │   └── vars
    │       └── main.yml
    └── worker
        ├── defaults
        │   └── main.yml
        ├── files
        ├── handlers
        │   └── main.yml
        ├── tasks
        │   └── main.yml
        ├── templates
        └── vars
            └── main.yml

```

# Часть 1

## Создание облачной инфраструктуры

После выполнения комады `terraform apply --auto-approve` получаем следующую структуру в облаке:

![image-1](https://github.com/user-attachments/assets/a769b0f3-1ccd-4080-942b-2d129be82975)


![image-2](https://github.com/user-attachments/assets/8edc6703-6e63-4452-9a25-c5872e99cd28)


### Почему столько машин и для чего это?
    
Моя попытка сделать кластер высокой доступности приближенный к кластеру реализованному на физическом железе. В данном случае есть по машине HAProxy в каждой из зон доступности.

![image-3](https://github.com/user-attachments/assets/c48da82d-dc09-46f5-a447-d90e613c7856)

Они образую группу к которой обращается внешний балансировщик нагрузки и проверяет что узлы HAProxy а следовательно и зоны не упали (на живом железе это имитация связки HAProxy + KeepAlived), NLB в данном случае выступает в виде выделенного виртуального адреса, так как сам keepalived не получается настроить в облаке.

![image-4](https://github.com/user-attachments/assets/917029e2-dabe-47eb-8ac1-cd5fae6720e1)

![image-5](https://github.com/user-attachments/assets/6f261fcb-7ad3-4d56-932a-02d4ae185845)

Дальше все давольно понятно по одному `мастер` узлу и по два `воркер` kubernetes в каждай зоне, `jump-server` через который происходит настройка каждого узла с помощью ansible он так же выступает в качестве nginx-proxy (т.е через конфиг файлы я проксирую порты на сервисы) для тестово отладочных работ с выведеными наружу сервисами kubernetes. И три NAT инстанса для выхода узлов в сеть.

### VPC/Subnet

![image-6](https://github.com/user-attachments/assets/54b1e8c6-dd89-4947-9d0d-f8771819cfae)

![image-7](https://github.com/user-attachments/assets/464af6b4-7c71-42cd-986a-cab3dd24e020)

### Список внешних IP

![image-8](https://github.com/user-attachments/assets/31c7ee79-6cd7-4d16-b8b7-c02bafc60f9d)

### Структура облочной сети

![image-9](https://github.com/user-attachments/assets/fb6c5c28-58a3-43fa-ad82-abe655b55833)

### Bucket.tf

![image-10](https://github.com/user-attachments/assets/9baaad65-d11b-481b-944d-bce806550973)

# Часть 2

## Создание Kubernetes кластера

Для настройки узлов как и говорилось раньше использовался ansible через jump-server, в нем описаны роли для каждого узла, так же в хоте выполнения terraform генерируются файлы для него, это `hosts.yaml` `ansible.cfg`

После отработки ansible мы получаем которые хосты с уже скачаными пакетами, установленными системными параметрами, сгенерированным конфигурационным файлом для kubeadm (установка кластера так же выполняется с его помощью), все что требуется от нас это подлючиться на мастер ноду, добавать в этот конфиг файл адрес узла с которого будет произвадиться развертывание `advertiseAddress:` если надо поменять сети `podSubnet:` `serviceSubnet:` и выполнить команду по миграции шаблона конфиг файла в "полный" конфиг файл после чего инициализацировать кластер.

```
kubeadm config migrate --old-config <path-to-old.yaml> --new-config <path-to-new.yaml>

sudo kubeadm init --config=<path-init.yaml> --upload-certs
```

После чего мы получаем готовый кластер с подключение через ControlPlaneEndpoint что говорит что нас кластер является кластером высокой доступности. После чего мы можем ввести в кластер остальные мастер узлы и узлы воркеры. В дальнейшем для простаты вывод будет через k9s.

### Вот мы и получили готовый кластер:

![image-11](https://github.com/user-attachments/assets/112ed197-3579-48e5-a0a8-a5014193e8d2)

Проверим ноды и поды соответствуют свои ip

![image-12](https://github.com/user-attachments/assets/6debb215-7e0a-407f-8586-b29555da9b04)


# Часть 3

## Создание тестового приложения

Для создания приложения использовался отдельный репозиторий `https://github.com/Borschik27/diplom-kube-svc`

Был создан простой проект со стартовой страницей NXING, с помощью Dockerfile был создан контейнер с отладочной целью и был загружен в этот же репозиторий

Вот что представляет из себя стартовая страница:

![image-13](https://github.com/user-attachments/assets/43b52605-daed-473b-987f-37f5024b4d3b)


# Часть 3

## Подготовка cистемы мониторинга и деплой приложения

### Monitoring

Система мониторинга будет разворачиваться с помощь Helm-charts'a 

Скачаем и установим:
```
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```


Добавим charts:
```
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
```

Для предварительного тестирования создадим values файл для запуска чарта, где укажем нужные нам параметры и что запустить надо на NodePort:

```
ubuntu@master-a:~/k8s_conf$ cat values-monitor.yaml
prometheus:
  prometheusSpec:
    serviceMonitorSelectorNilUsesHelmValues: false

grafana:
  adminPassword: "admin"
  service:
    type: NodePort
    nodePort: 32000
  ingress:
    enabled: false


alertmanager:
  enabled: true
  service:
    type: NodePort
    nodePort: 32001

nodeExporter:
  enabled: true

kubeStateMetrics:
  enabled: true
```

Запуск:

```
helm upgrade --install monitoring prometheus-community/kube-prometheus-stack -f values-monitor.yaml -n
 monitoring --create-namespace
```

Для проверки у нас поднят на jump-server nginx и сделаны два конфига на проксирование запросов:

```
root@jump:/etc/nginx/sites-enabled# cat grafana.conf
server {
  listen 8080;
  server_name _;

  location / {
      proxy_pass http://10.10.10.5:32000/;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Host $host;
            proxy_set_header        X-Real-IP $remote_addr;
            proxy_set_header        X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header        X-Forwarded-Proto https;
            add_header              Strict-Transport-Security max-age=63072000;
            add_header              X-Frame-Options "SAMEORIGIN";
            add_header              X-Content-Type-Options nosniff;
  }
}

root@jump:/etc/nginx/sites-enabled# cat alert.conf
server {
  listen 8081;
  server_name _;

location / {
      proxy_pass http://10.10.10.5:32001/;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Host $host;
            proxy_set_header        X-Real-IP $remote_addr;
            proxy_set_header        X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header        X-Forwarded-Proto https;
            add_header              Strict-Transport-Security max-age=63072000;
            add_header              X-Frame-Options "SAMEORIGIN";
            add_header              X-Content-Type-Options nosniff;
  }
}
root@jump:/etc/nginx/sites-enabled#
```

Применим чарт, запусти nginx на jump и проверим что имеем доступ к сервисам:

```
helm upgrade --install monitoring prometheus-community/kube-prometheus-stack   -f values-monitor.yaml -n monitoring --create-namespace

Release "monitoring" has been upgraded. Happy Helming!
NAME: monitoring
LAST DEPLOYED: Thu Feb 13 16:37:12 2025
NAMESPACE: monitoring
STATUS: deployed
REVISION: 3
NOTES:
kube-prometheus-stack has been installed. Check its status by running:
  kubectl --namespace monitoring get pods -l "release=monitoring"

Get Grafana 'admin' user password by running:

  kubectl --namespace monitoring get secrets monitoring-grafana -o jsonpath="{.data.admin-password}" | base64 -d ; echo

Access Grafana local instance:

  export POD_NAME=$(kubectl --namespace monitoring get pod -l "app.kubernetes.io/name=grafana,app.kubernetes.io/instance=monitoring" -oname)
  kubectl --namespace monitoring port-forward $POD_NAME 3000

Visit https://github.com/prometheus-operator/kube-prometheus for instructions on how to create & configure Alertmanager and Prometheus instances using the Operator.
```

В графане срузу выведим дашборд который нам покажет что есть метрики с node_exporter с узлов:

![image-14](https://github.com/user-attachments/assets/0277c598-8630-4c21-aa64-e84743b111bc)

В алертменеджере увидим что у нас есть правила:

![image-15](https://github.com/user-attachments/assets/d266cec6-fa7d-4849-98a6-cd462d38697e)

Как видим наши сервисы удачно запустились.

Теперь задеплоим в кубер наше прилодение из репозитория на github для проверки
Так как контейнер задеплоен в github и является приватным нужно сделать секрет для kubernetes и использовать его для загрузки

### Создание секрета:
```
kubectl create secret docker-registry ghcr-secret \
--docker-server=ghcr.io \
--docker-username=<user_name> \
--docker-password=<OA_token> \
--docker-email=<email>
```

## Cоздадим deploy/svc и конфиг для nginx

### Nginx

```
root@jump:/etc/nginx/sites-enabled# cat diplom.conf
server {
  listen 8082;
  server_name _;

location / {
      proxy_pass http://10.10.20.101:32002/;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Host $host;
            proxy_set_header        X-Real-IP $remote_addr;
            proxy_set_header        X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header        X-Forwarded-Proto https;
            add_header              Strict-Transport-Security max-age=63072000;
            add_header              X-Frame-Options "SAMEORIGIN";
            add_header              X-Content-Type-Options nosniff;
  }
}
```

### Deploy/svc:

```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: <meta_name> Совпадает с Service meta_name
  labels:
    app: <app_name> Совпадает с Service <app_name>
spec:
  replicas: 2
  selector:
    matchLabels:
      app: <app_name> Совпадает с Service <app_name>
  template:
    metadata:
      labels:
        app: <app_name> Совпадает с Service <app_name>
    spec:
      imagePullSecrets:
      - name: <you secret tocken name>
      containers:
      - name: <cont_name>
        image: <ghcr.io/<path to containter>>
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: <meta_name>
spec:
  selector:
    app: <app_name>
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
      nodePort: 32002
  type: NodePort
```


### Pods:

![image-16](https://github.com/user-attachments/assets/b7d4802c-671b-4fd8-872b-66695eadc99b)

### SVC:

![image-17](https://github.com/user-attachments/assets/b12ff6a4-b2c3-4557-95f5-6ead619c34d4)

### Browser:

![image-18](https://github.com/user-attachments/assets/5cd4adde-95a1-4204-b0bd-abc1aff2f854)

Как видно сервисы работаеют.

### Что делаем дальше

Теперь переведем все наши сервисы `grafana` `nginx` `alertmanager` на `ingress-nginx`. Так как мы работаем в облаке `svc` который создается при деплое будет указан как `NodePort`. Создадим с помощь terraform еще один внешний балансировщик (NLB), создамим группу из узлов `ingress-worker`
что бы получить доступ из внешней сети к нашему INGRESS

## Выбор воркеров

Для разделения `nodes` по зонам, что бы в дальнейшем можно было деплоить сервисы на разные зоны доступности стоит промаркеровать их, возьмем пример как советует YC для разделения по зонам `https://yandex.cloud/ru/docs/managed-kubernetes/concepts/usage-recommendations`, так же для начала укажем что каждая первая нода (kw01-<x>) это `ingress-worker` 

Так же в дальнейшем передеплоим наши сервисы так что бы они находились хотя бы в 2-х зонах доступности

### Установи метки на воркеры:

```
kubectl label nodes <node-name> topology.kubernetes.io/zone=ru-central1-<x>
kubectl label nodes <node-name> role=ingress-worker
```

### Ingess Nginx

Ingress мы так же будем деплоить черех helm.
Для начала напишем `values` с нужными нам параметрами:

```
controller:
  ingressClass: nginx
  replicaCount: 3
  service:
    type: NodePort
    nodePorts:
      http: 32080
      https: 32443
  nodeSelector:
    role: ingress-worker
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - key: topology.kubernetes.io/zone
            operator: In
            values:
            - ru-central1-a
            - ru-central1-b
            - ru-central1-d
```

Запустим и посмотри на результат.

```
helm upgrade --install nginx-ingress ingress-nginx/ingress-nginx -f values.yaml --create-namespace -n ingress-nginx
```


### Pods

![image-21](https://github.com/user-attachments/assets/5c46daf5-8868-47d2-9eb7-af101d26faea)

### SVC
Теперь переведем все наши сервисы на `ClusterIP` и напишем для них ingress манифесты:

![image-22](https://github.com/user-attachments/assets/0b214986-213d-49bf-a245-ca4ef8bda957)

## Проверка

### Первый Вариант:
   
После деплоя мы проверим сервисы на доступность через внешний ip, так как у нас нет DNS-домена который будет резолвить нам адреса воспользуемся `curl` и передадим загоовок `-H "Host: <svc_name>.sypchik.kuber"`

```
ubuntu@master-a:~/k8s_conf/nginx$ kubectl apply -f grafana-ingress.yaml
ingress.networking.k8s.io/monitoring-ingress configured

ubuntu@master-a:~/k8s_conf/nginx$ curl  -H "Host: grafana.sypchik.kuber" http://84.201.172.144
<a href="/login">Found</a>.

ubuntu@master-a:~/k8s_conf/nginx$ curl  -H "Host: prometnode.sypchik.kuber" http://84.201.172.144
<a href="/query">Found</a>.

ubuntu@master-a:~/k8s_conf/nginx$ curl  -H "Host: alertm.sypchik.kuber" http://84.201.172.144
<!DOCTYPE html>
<html lang="en">
    <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">
        <link rel="icon" type="image/x-icon" href="favicon.ico" />
        ...
            app.ports.persistFirstDayOfWeek.subscribe(function(firstDayOfWeek) {
                localStorage.setItem('firstDayOfWeek', JSON.stringify(firstDayOfWeek));
            });
        </script>
    </body>
</html>


ubuntu@master-a:~/k8s_conf/nginx$ curl  -H "Host: nginx.sypchik.kuber" http://84.201.172.144
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Welcome to My Web Server in Kubernetes cluster</title>
</head>
<body>
    <h1>Welcome Sypchik!</h1>
    <p>This is the default page served by the web server.</p>
    <p>Link on Diplom Project: <a href="https://github.com/Borschik27/diplom">Netology Diplom Proj</a></p>
    <p>Link on Diplom Kubernetes Services Project: <a href="https://github.com/Borschik27/diplom-kube-svc">Netology Kuber Proj</a></p>
</body>
</html>
ubuntu@master-a:~/k8s_conf/nginx$
```

### Второй вариант:

Для проверки доступности мы можем сделать следующее просто добавим в файл `C:\Windows\System32\drivers\etc\hosts` список наших адресов:

```
...
# End of section

84.201.172.144 nginx.sypchik.kuber
84.201.172.144 grafana.sypchik.kuber
84.201.172.144 prometnode.sypchik.kuber
84.201.172.144 alertm.sypchik.kuber
```

### Grafana

![image-23](https://github.com/user-attachments/assets/04e9eca1-02f7-4307-894a-88cc80926a49)

### AlertManager

![image-24](https://github.com/user-attachments/assets/3d551e05-b1bd-4048-a0be-33c40d097b5a)

### Prometheus

![image-25](https://github.com/user-attachments/assets/4213db59-e725-4c64-a180-cc67b795fa1f)

### MyAPP

![image-26](https://github.com/user-attachments/assets/fd9eb833-1b67-40ee-a55b-c18b39dcb11f)



# Часть 4

### CI/CD
