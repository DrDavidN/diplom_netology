# Дипломный практикум в Yandex.Cloud - Дрибноход Давид
  * [Цели:](#цели)
  * [Этапы выполнения:](#этапы-выполнения)
     * [Создание облачной инфраструктуры](#создание-облачной-инфраструктуры)
     * [Создание Kubernetes кластера](#создание-kubernetes-кластера)
     * [Создание тестового приложения](#создание-тестового-приложения)
     * [Подготовка cистемы мониторинга и деплой приложения](#подготовка-cистемы-мониторинга-и-деплой-приложения)
     * [Установка и настройка CI/CD](#установка-и-настройка-cicd)
  * [Что необходимо для сдачи задания?](#что-необходимо-для-сдачи-задания)
  * [Как правильно задавать вопросы дипломному руководителю?](#как-правильно-задавать-вопросы-дипломному-руководителю)

**Перед началом работы над дипломным заданием изучите [Инструкция по экономии облачных ресурсов](https://github.com/netology-code/devops-materials/blob/master/cloudwork.MD).**

---
## Цели:

1. Подготовить облачную инфраструктуру на базе облачного провайдера Яндекс.Облако.
2. Запустить и сконфигурировать Kubernetes кластер.
3. Установить и настроить систему мониторинга.
4. Настроить и автоматизировать сборку тестового приложения с использованием Docker-контейнеров.
5. Настроить CI для автоматической сборки и тестирования.
6. Настроить CD для автоматического развёртывания приложения.

---
## Этапы выполнения:


### Создание облачной инфраструктуры

Для начала необходимо подготовить облачную инфраструктуру в ЯО при помощи [Terraform](https://www.terraform.io/).

Особенности выполнения:

- Бюджет купона ограничен, что следует иметь в виду при проектировании инфраструктуры и использовании ресурсов;
Для облачного k8s используйте региональный мастер(неотказоустойчивый). Для self-hosted k8s минимизируйте ресурсы ВМ и долю ЦПУ. В обоих вариантах используйте прерываемые ВМ для worker nodes.

Предварительная подготовка к установке и запуску Kubernetes кластера.

1. Создайте сервисный аккаунт, который будет в дальнейшем использоваться Terraform для работы с инфраструктурой с необходимыми и достаточными правами. Не стоит использовать права суперпользователя
2. Подготовьте [backend](https://www.terraform.io/docs/language/settings/backends/index.html) для Terraform:  
   а. Рекомендуемый вариант: S3 bucket в созданном ЯО аккаунте(создание бакета через TF)
   б. Альтернативный вариант:  [Terraform Cloud](https://app.terraform.io/)  
3. Создайте VPC с подсетями в разных зонах доступности.
4. Убедитесь, что теперь вы можете выполнить команды `terraform destroy` и `terraform apply` без дополнительных ручных действий.
5. В случае использования [Terraform Cloud](https://app.terraform.io/) в качестве [backend](https://www.terraform.io/docs/language/settings/backends/index.html) убедитесь, что применение изменений успешно проходит, используя web-интерфейс Terraform cloud.

Ожидаемые результаты:

1. Terraform сконфигурирован и создание инфраструктуры посредством Terraform возможно без дополнительных ручных действий.
2. Полученная конфигурация инфраструктуры является предварительной, поэтому в ходе дальнейшего выполнения задания возможны изменения.

---
### Создание Kubernetes кластера

На этом этапе необходимо создать [Kubernetes](https://kubernetes.io/ru/docs/concepts/overview/what-is-kubernetes/) кластер на базе предварительно созданной инфраструктуры.   Требуется обеспечить доступ к ресурсам из Интернета.

Это можно сделать двумя способами:

1. Рекомендуемый вариант: самостоятельная установка Kubernetes кластера.  
   а. При помощи Terraform подготовить как минимум 3 виртуальных машины Compute Cloud для создания Kubernetes-кластера. Тип виртуальной машины следует выбрать самостоятельно с учётом требовании к производительности и стоимости. Если в дальнейшем поймете, что необходимо сменить тип инстанса, используйте Terraform для внесения изменений.  
   б. Подготовить [ansible](https://www.ansible.com/) конфигурации, можно воспользоваться, например [Kubespray](https://kubernetes.io/docs/setup/production-environment/tools/kubespray/)  
   в. Задеплоить Kubernetes на подготовленные ранее инстансы, в случае нехватки каких-либо ресурсов вы всегда можете создать их при помощи Terraform.
2. Альтернативный вариант: воспользуйтесь сервисом [Yandex Managed Service for Kubernetes](https://cloud.yandex.ru/services/managed-kubernetes)  
  а. С помощью terraform resource для [kubernetes](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/kubernetes_cluster) создать **региональный** мастер kubernetes с размещением нод в разных 3 подсетях      
  б. С помощью terraform resource для [kubernetes node group](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/kubernetes_node_group)
  
Ожидаемый результат:

1. Работоспособный Kubernetes кластер.
2. В файле `~/.kube/config` находятся данные для доступа к кластеру.
3. Команда `kubectl get pods --all-namespaces` отрабатывает без ошибок.

---
### Создание тестового приложения

Для перехода к следующему этапу необходимо подготовить тестовое приложение, эмулирующее основное приложение разрабатываемое вашей компанией.

Способ подготовки:

1. Рекомендуемый вариант:  
   а. Создайте отдельный git репозиторий с простым nginx конфигом, который будет отдавать статические данные.  
   б. Подготовьте Dockerfile для создания образа приложения.  
2. Альтернативный вариант:  
   а. Используйте любой другой код, главное, чтобы был самостоятельно создан Dockerfile.

Ожидаемый результат:

1. Git репозиторий с тестовым приложением и Dockerfile.
2. Регистри с собранным docker image. В качестве регистри может быть DockerHub или [Yandex Container Registry](https://cloud.yandex.ru/services/container-registry), созданный также с помощью terraform.

---
### Подготовка cистемы мониторинга и деплой приложения

Уже должны быть готовы конфигурации для автоматического создания облачной инфраструктуры и поднятия Kubernetes кластера.  
Теперь необходимо подготовить конфигурационные файлы для настройки нашего Kubernetes кластера.

Цель:
1. Задеплоить в кластер [prometheus](https://prometheus.io/), [grafana](https://grafana.com/), [alertmanager](https://github.com/prometheus/alertmanager), [экспортер](https://github.com/prometheus/node_exporter) основных метрик Kubernetes.
2. Задеплоить тестовое приложение, например, [nginx](https://www.nginx.com/) сервер отдающий статическую страницу.

Способ выполнения:
1. Воспользоваться пакетом [kube-prometheus](https://github.com/prometheus-operator/kube-prometheus), который уже включает в себя [Kubernetes оператор](https://operatorhub.io/) для [grafana](https://grafana.com/), [prometheus](https://prometheus.io/), [alertmanager](https://github.com/prometheus/alertmanager) и [node_exporter](https://github.com/prometheus/node_exporter). Альтернативный вариант - использовать набор helm чартов от [bitnami](https://github.com/bitnami/charts/tree/main/bitnami).

2. Если на первом этапе вы не воспользовались [Terraform Cloud](https://app.terraform.io/), то задеплойте и настройте в кластере [atlantis](https://www.runatlantis.io/) для отслеживания изменений инфраструктуры. Альтернативный вариант 3 задания: вместо Terraform Cloud или atlantis настройте на автоматический запуск и применение конфигурации terraform из вашего git-репозитория в выбранной вами CI-CD системе при любом комите в main ветку. Предоставьте скриншоты работы пайплайна из CI/CD системы.

Ожидаемый результат:
1. Git репозиторий с конфигурационными файлами для настройки Kubernetes.
2. Http доступ к web интерфейсу grafana.
3. Дашборды в grafana отображающие состояние Kubernetes кластера.
4. Http доступ к тестовому приложению.

---
### Установка и настройка CI/CD

Осталось настроить ci/cd систему для автоматической сборки docker image и деплоя приложения при изменении кода.

Цель:

1. Автоматическая сборка docker образа при коммите в репозиторий с тестовым приложением.
2. Автоматический деплой нового docker образа.

Можно использовать [teamcity](https://www.jetbrains.com/ru-ru/teamcity/), [jenkins](https://www.jenkins.io/), [GitLab CI](https://about.gitlab.com/stages-devops-lifecycle/continuous-integration/) или GitHub Actions.

Ожидаемый результат:

1. Интерфейс ci/cd сервиса доступен по http.
2. При любом коммите в репозиторие с тестовым приложением происходит сборка и отправка в регистр Docker образа.
3. При создании тега (например, v1.0.0) происходит сборка и отправка с соответствующим label в регистри, а также деплой соответствующего Docker образа в кластер Kubernetes.

---
## Что необходимо для сдачи задания?

1. Репозиторий с конфигурационными файлами Terraform и готовность продемонстрировать создание всех ресурсов с нуля.
2. Пример pull request с комментариями созданными atlantis'ом или снимки экрана из Terraform Cloud или вашего CI-CD-terraform pipeline.
3. Репозиторий с конфигурацией ansible, если был выбран способ создания Kubernetes кластера при помощи ansible.
4. Репозиторий с Dockerfile тестового приложения и ссылка на собранный docker image.
5. Репозиторий с конфигурацией Kubernetes кластера.
6. Ссылка на тестовое приложение и веб интерфейс Grafana с данными доступа.
7. Все репозитории рекомендуется хранить на одном ресурсе (github, gitlab)

## Выполнение

Хост, на котором выполняется работа, содержит утилиты следующих версий:

```
Terraform v1.9.2
Ansible 2.10.8
Python 2.7.18
Docker 27.1.1, build 6312585
Git 2.30.2
Kubectl v1.30.0
Helm v3.15.1
Yandex Cloud CLI 0.128.0
```

![image](https://github.com/user-attachments/assets/e27e2605-135f-40d0-9afc-9ec80dd4c81d)


## 1. Подготовить облачную инфраструктуру на базе облачного провайдера Яндекс.Облако.

1. Создаею сервисный аккаунт в Yandex Cloud с именем ```diploma-sa```в каталоге ```diplom```. Создаю папку ```yc resource-manager folder create --name diplom``` Создаем аккаунт ```yc iam service-account create --name diplom-sa --folder-name diplom``` и назначаем права ```yc resource-manager folder add-access-binding diplom --role admin --subject serviceAccount:aje*``` получаем ключ ```yc iam key create --folder-name diplom --service-account-name diplom-sa --output key.json```
2. Запускаю ```terraform apply --auto-approve``` в папке preparation, который создаст специальную сервисную учетку tf-sa и S3 бакет для terraform backend в основном проекте.
![image](https://github.com/user-attachments/assets/8b78ae83-db4b-45c3-aa6a-72ecd3c45599)
![image](https://github.com/user-attachments/assets/66bc38de-c48a-4829-9164-22afcb206019)

4. Подготавливаю основновной манифест в папке terraform с VPC и запускаю его используя ключи из backend.key, которые получил на прошлом шаге:

```terraform init -backend-config="access_key=***" -backend-config="secret_key=***"```

```terraform apply --auto-approve```

![image](https://github.com/user-attachments/assets/ffba0057-675f-4eeb-9360-c51957e1685c)
![image](https://github.com/user-attachments/assets/fcb566d3-b91a-4f81-9825-82442c058c7c)

## 2. Запустить и сконфигурировать Kubernetes кластер.

Установлю kubespray, он будет находится в ```./ansible/kubespray```

```
wget https://github.com/kubernetes-sigs/kubespray/archive/refs/tags/v2.24.0.tar.gz
tar -xvzf v2.24.0.tar.gz
mv kubespray-2.24.0/ ./ansible/kubespray
sudo python3 -m pip install --upgrade pip
sudo pip3 install -r ansible/kubespray/requirements.txt
```

Создам k8s-кластер состоящий из 3-ех master и worker нод, размещенных в разных подсетях.

Использую манифесты ./terraform/k8s-masters.tf и ./terraform/k8s-workers.tf ./terraform/ansible.tf. Которые поднимут ВМ и через kubespray развернут кластер.

```terraform apply --auto-approve```

![image](https://github.com/user-attachments/assets/94a5f30d-2f48-479e-8a5d-592b0e23b6b8)
![image](https://github.com/user-attachments/assets/5e5cee21-19ae-4995-aece-b746be8e7cf5)

```kubectl get nodes -A -owide```

```kubectl get pods -A -owide```

![image](https://github.com/user-attachments/assets/33186333-1076-4431-9f11-9cf5adbd7d80)

## 3. Установить и настроить систему мониторинга.

Используя манифест ```./terraform/monitoring.tf``` и ```./k8s/service-grafana.yaml``` сконфигурирую мониторинг и сервис grafana. 

Подготовлю network_load_balancer для доступа к grafana и diplom-test-app ```./terraform/nlb.tf```

```terraform apply --auto-approve```

![image](https://github.com/user-attachments/assets/b1683e81-8c1e-4e1b-9bad-4457fcd073b8)

![image](https://github.com/user-attachments/assets/926cda5f-5560-4fb4-860a-dc39cba4cfa9)

Подключаюсь к Grafana по порту 3000 Логин: admin Пароль: prom-operator, открываю дашборд Kubernetes / Compute Resources / Cluster

![image](https://github.com/user-attachments/assets/f8339769-54ba-49c9-ad76-e73a55b82164)

![image](https://github.com/user-attachments/assets/3b3673a7-9b76-4f19-b9e0-2f6f94fc066a)

## 4. Настроить и автоматизировать сборку тестового приложения с использованием Docker-контейнеров.

Скачиваею подготовленный репозиторий [Репозиторий с тестовым приложением](https://github.com/DrDavidN/diplom-test-app)

Собираю образ и отправляю его в Docker Hub

<details>
```
dribnokhod@debian11:~$ git clone https://github.com/DrDavidN/diplom-test-app.git
Клонирование в «diplom-test-app»…
remote: Enumerating objects: 11, done.
remote: Counting objects: 100% (11/11), done.
remote: Compressing objects: 100% (7/7), done.
remote: Total 11 (delta 0), reused 0 (delta 0), pack-reused 0 (from 0)
Получение объектов: 100% (11/11), готово.
dribnokhod@debian11:~$ cd diplom-test-app/
dribnokhod@debian11:~/diplom-test-app$sudo docker login
Authenticating with existing credentials...
WARNING! Your password will be stored unencrypted in /home/dribnokhod/.docker/config.json.
Configure a credential helper to remove this warning. See
https://docs.docker.com/engine/reference/commandline/login/#credential-stores

Login Succeeded
dribnokhod@debian11:~/diplom-test-app$ sudo docker build -t drdavidn/diplom-test-app:v1.0.0 .
[sudo] пароль для dribnokhod:
[+] Building 68.5s (7/7) FINISHED                                                                                                                                                docker:default
 => [internal] load build definition from Dockerfile                                                                                                                                       0.5s
 => => transferring dockerfile: 89B                                                                                                                                                        0.0s
 => [internal] load metadata for docker.io/library/nginx:latest                                                                                                                            2.9s
 => [internal] load .dockerignore                                                                                                                                                          0.3s
 => => transferring context: 2B                                                                                                                                                            0.0s
 => [internal] load build context                                                                                                                                                          0.4s
 => => transferring context: 828B                                                                                                                                                          0.0s
 => [1/2] FROM docker.io/library/nginx:latest@sha256:04ba374043ccd2fc5c593885c0eacddebabd5ca375f9323666f28dfd5a9710e3                                                                     61.3s
 => => resolve docker.io/library/nginx:latest@sha256:04ba374043ccd2fc5c593885c0eacddebabd5ca375f9323666f28dfd5a9710e3                                                                      0.4s
 => => sha256:88a0a069d5e9865fcaaf8c1e53ba6bf3d8d987b0fdc5e0135fec8ce8567d673e 2.29kB / 2.29kB                                                                                             0.0s
 => => sha256:39286ab8a5e14aeaf5fdd6e2fac76e0c8d31a0c07224f0ee5e6be502f12e93f3 7.47kB / 7.47kB                                                                                             0.0s
 => => sha256:04ba374043ccd2fc5c593885c0eacddebabd5ca375f9323666f28dfd5a9710e3 10.27kB / 10.27kB                                                                                           0.0s
 => => sha256:a2318d6c47ec9cac5acc500c47c79602bcf953cec711a18bc898911a0984365b 29.13MB / 29.13MB                                                                                          25.7s
 => => sha256:095d327c79ae6eb03406dd754eb917fbe7009c6a9aa6c0db558f9dea599db8ea 41.88MB / 41.88MB                                                                                          30.6s
 => => sha256:bbfaa25db775e54ec75dabe7986451cb99911b082d63bbf983ab20fc6f7faaf4 628B / 628B                                                                                                 1.6s
 => => sha256:7bb6fb0cfb2b319dee79e476c11620e7fa47f22ecdedc999e207984f62a4554c 956B / 956B                                                                                                 3.0s
 => => sha256:0723edc10c178df9245f49c9b8e503c4223a959ee5a072f043d71669132bc5e9 394B / 394B                                                                                                 4.2s
 => => sha256:24b3fdc4d1e3b419643068364b3d4e1b7e280f5a8a3c1e3651e9e67363e6434b 1.21kB / 1.21kB                                                                                             5.2s
 => => sha256:3122471704d5d924d1f7daac334252487e3c35bfb23163b840954aff355c4a6b 1.40kB / 1.40kB                                                                                             6.2s
 => => extracting sha256:a2318d6c47ec9cac5acc500c47c79602bcf953cec711a18bc898911a0984365b                                                                                                 17.0s
 => => extracting sha256:095d327c79ae6eb03406dd754eb917fbe7009c6a9aa6c0db558f9dea599db8ea                                                                                                 13.9s
 => => extracting sha256:bbfaa25db775e54ec75dabe7986451cb99911b082d63bbf983ab20fc6f7faaf4                                                                                                  0.0s
 => => extracting sha256:7bb6fb0cfb2b319dee79e476c11620e7fa47f22ecdedc999e207984f62a4554c                                                                                                  0.0s
 => => extracting sha256:0723edc10c178df9245f49c9b8e503c4223a959ee5a072f043d71669132bc5e9                                                                                                  0.0s
 => => extracting sha256:24b3fdc4d1e3b419643068364b3d4e1b7e280f5a8a3c1e3651e9e67363e6434b                                                                                                  0.0s
 => => extracting sha256:3122471704d5d924d1f7daac334252487e3c35bfb23163b840954aff355c4a6b                                                                                                  0.0s
 => [2/2] COPY content /usr/share/nginx/html                                                                                                                                               2.7s
 => exporting to image                                                                                                                                                                     0.3s
 => => exporting layers                                                                                                                                                                    0.2s
 => => writing image sha256:ea9416ac49b3cb30315545665841dde6af63ba6b4797c6ba79dd186e61605e19                                                                                               0.0s
 => => naming to docker.io/drdavidn/diplom-test-app:v1.0.0                                                                                                                                 0.0s
dribnokhod@debian11:~/diplom-test-app$ sudo docker tag drdavidn/diplom-test-app:v1.0.0 drdavidn/diplom-test-app:latest
dribnokhod@debian11:~/diplom-test-app$ sudo docker push drdavidn/diplom-test-app:latest
The push refers to repository [docker.io/drdavidn/diplom-test-app]
d138f21af234: Pushed
11de3d47036d: Mounted from library/nginx
16907864a2d0: Mounted from library/nginx
2bdf51597158: Mounted from library/nginx
0fc6bb94eec5: Mounted from library/nginx
eda13eb24d4c: Mounted from library/nginx
67796e30ff04: Mounted from library/nginx
8e2ab394fabf: Mounted from library/nginx
latest: digest: sha256:988a1666e10e9fa634799ad35f664cf0a29130383c6d3beb424fca6de4232b4a size: 1985
```
</details>

Используя манифест app.tf и yaml файлы ../k8s/deployment-testapp.yaml и ../k8s/service-testapp.yaml разворачиваю приложение на ВМ

```terraform apply --auto-approve```

![image](https://github.com/user-attachments/assets/de90bc7a-1cff-4090-b0cf-103988372e5a)

![image](https://github.com/user-attachments/assets/a8ebc3a3-09ba-41b2-b79a-86592148e652)

---
