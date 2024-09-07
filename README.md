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
# Выполнение

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

Подключаюсь к [Grafana](http://51.250.36.253:3000) по порту 3000 Логин: admin Пароль: prom-operator, открываю дашборд Kubernetes / Compute Resources / Cluster

![image](https://github.com/user-attachments/assets/f8339769-54ba-49c9-ad76-e73a55b82164)

![image](https://github.com/user-attachments/assets/3b3673a7-9b76-4f19-b9e0-2f6f94fc066a)

## 4. Настроить и автоматизировать сборку тестового приложения с использованием Docker-контейнеров.

Скачиваею подготовленный репозиторий [Репозиторий с тестовым приложением](https://github.com/DrDavidN/diplom-test-app)

Собираю образ и отправляю его в Docker Hub [Ссылка на образ в Docker](https://hub.docker.com/repository/docker/drdavidn/diplom-test-app)

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

[Ссылка на приложение](http://84.201.147.207/)

## 5. Настроить CI для автоматической сборки и тестирования. + 6. Настроить CD для автоматического развёртывания приложения.

Ипортирую проект в Gitlab из Github [Репозиторий GitHub с тестовым приложением](https://github.com/DrDavidN/diplom-test-app)

Регистрирую Агента, записываю токен и параметры установки в манифест cicd.tf

Применяю манифест для установки агента в кластер ```terraform apply --auto-approve```

![image](https://github.com/user-attachments/assets/dfc1eefd-4d4e-4ecc-b1cf-2a7d7914ac1b)

![image](https://github.com/user-attachments/assets/825677a1-8b1c-4b50-b1a2-c50ab6479609)

Объявляю переменные REGISTRY_PASSWORD и REGISTRY_USER для DockerHub в GitLab - Settings - CI/CD - Variables

Настриваю [GitLab CI](https://gitlab.com/DrDavidN/diplom-test-app/-/blob/main/.gitlab-ci.yml?ref_type=heads) и добавляю в проект [HELM](https://gitlab.com/DrDavidN/diplom-test-app/-/tree/main/deploy?ref_type=heads)

Пример [build](https://gitlab.com/DrDavidN/diplom-test-app/-/jobs/7766375546)

Пример [build и deploy](https://gitlab.com/DrDavidN/diplom-test-app/-/pipelines/1444004105)

Приложение обновилось
![image](https://github.com/user-attachments/assets/655b9755-5b62-464f-b177-2f36b1d4eca0)

