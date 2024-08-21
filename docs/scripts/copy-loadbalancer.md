# Миграция балансировщиков нагрузки

Балансировщик и его правила состоят из следующих сущностей:
1. Балансировщик
1. listener
1. pool
1. healthmonitor
1. members

### Схема данных

На данной схеме изображены пример json описания каждого объекта и связей между ними, который может копировать скрипт. 
В контуре указаны сущности балансировщика, за контуром зависимые сущности.
![alt text](../images/loadbalancer-datamodel.png)

Для вывода подробной информации о конкретном экземпляре сущности какого-то типа используется команда **show**.

(Для вывода в формате json необходимо после list добавить **-f json**)

### Loadbalancer

```bash
openstack loadbalancer show nginx-lb -f json
```

```json
{
  "admin_state_up": true,
  "availability_zone": "ME1",
  "created_at": "2024-08-20T22:18:18",
  "description": "",
  "flavor_id": null,
  "id": "9233f697-9aa8-4f61-ad85-a5f4d761c888",
  "listeners": "d0be060a-6922-4807-bdba-cc7a3a795a0c\na77a6963-d75c-4819-918a-b947803dbd1a",
  "name": "nginx-lb",
  "operating_status": "ERROR",
  "pools": "03dabf47-00e7-401e-92c3-8e36c69f7f7d\nb5ed2458-72eb-4ae8-a272-0a4e7155913b",
  "project_id": "5f44bfcdee6045249c9c839d1052077b",
  "provider": "amphora",
  "provisioning_status": "ACTIVE",
  "updated_at": "2024-08-20T22:29:21",
  "vip_address": "10.0.2.32",
  "vip_network_id": "df401718-7918-4bb5-9401-fcd4cd1943ac",
  "vip_port_id": "a302a809-f6e6-480c-ba34-983afb4dd7c2",
  "vip_qos_policy_id": null,
  "vip_subnet_id": "7b0e958a-90e8-4ff3-8318-f2c3080977d6",
  "vip_vnic_type": "normal",
  "tags": "",
  "additional_vips": ""
}
```

### Listeners

```bash
openstack loadbalancer listener show d0be060a-6922-4807-bdba-cc7a3a795a0c -f json
```

```json
{
  "admin_state_up": true,
  "connection_limit": -1,
  "created_at": "2024-08-20T22:20:34",
  "default_pool_id": "03dabf47-00e7-401e-92c3-8e36c69f7f7d",
  "default_tls_container_ref": null,
  "description": "",
  "id": "d0be060a-6922-4807-bdba-cc7a3a795a0c",
  "insert_headers": "X-Forwarded-For=true",
  "l7policies": "",
  "loadbalancers": "9233f697-9aa8-4f61-ad85-a5f4d761c888",
  "name": "",
  "operating_status": "ONLINE",
  "project_id": "5f44bfcdee6045249c9c839d1052077b",
  "protocol": "HTTP",
  "protocol_port": 80,
  "provisioning_status": "ACTIVE",
  "sni_container_refs": [],
  "timeout_client_data": 40001,
  "timeout_member_connect": 4001,
  "timeout_member_data": 40001,
  "timeout_tcp_inspect": 1,
  "updated_at": "2024-08-20T22:21:12",
  "client_ca_tls_container_ref": null,
  "client_authentication": "NONE",
  "client_crl_container_ref": null,
  "allowed_cidrs": null,
  "tls_ciphers": "",
  "tls_versions": "",
  "alpn_protocols": "",
  "tags": "",
  "hsts_max_age": "",
  "hsts_include_subdomains": "",
  "hsts_preload": ""
}
```

### Pools

```bash
openstack loadbalancer pool show 03dabf47-00e7-401e-92c3-8e36c69f7f7d -f json
```

```json
{
  "admin_state_up": true,
  "created_at": "2024-08-20T22:20:48",
  "description": "",
  "healthmonitor_id": "ed80259e-6727-4845-915a-68aa9d0e576d",
  "id": "03dabf47-00e7-401e-92c3-8e36c69f7f7d",
  "lb_algorithm": "LEAST_CONNECTIONS",
  "listeners": "d0be060a-6922-4807-bdba-cc7a3a795a0c",
  "loadbalancers": "9233f697-9aa8-4f61-ad85-a5f4d761c888",
  "members": "0a243c26-e667-4d1a-a4ee-47cdcd8ca5ab\n67a44a79-824e-40f9-b7b4-afb480548ff5",
  "name": "",
  "operating_status": "ONLINE",
  "project_id": "5f44bfcdee6045249c9c839d1052077b",
  "protocol": "HTTP",
  "provisioning_status": "ACTIVE",
  "session_persistence": null,
  "updated_at": "2024-08-20T22:21:11",
  "tls_container_ref": null,
  "ca_tls_container_ref": null,
  "crl_container_ref": null,
  "tls_enabled": false,
  "tls_ciphers": "",
  "tls_versions": "",
  "tags": "",
  "alpn_protocols": ""
}
```

### Member

```bash
openstack loadbalancer member show 03dabf47-00e7-401e-92c3-8e36c69f7f7d 0a243c26-e667-4d1a-a4ee-47cdcd8ca5ab -f json
```

```json
{
  "address": "10.0.2.5",
  "admin_state_up": true,
  "created_at": "2024-08-20T22:20:56",
  "id": "0a243c26-e667-4d1a-a4ee-47cdcd8ca5ab",
  "name": "",
  "operating_status": "ONLINE",
  "project_id": "5f44bfcdee6045249c9c839d1052077b",
  "protocol_port": 80,
  "provisioning_status": "ACTIVE",
  "subnet_id": "7b0e958a-90e8-4ff3-8318-f2c3080977d6",
  "updated_at": "2024-08-20T22:21:21",
  "weight": 10,
  "monitor_port": null,
  "monitor_address": null,
  "backup": false,
  "tags": ""
}
```

### Healthmonitor

```bash
openstack loadbalancer healthmonitor show ed80259e-6727-4845-915a-68aa9d0e576d -f json
```

```json
{
  "project_id": "5f44bfcdee6045249c9c839d1052077b",
  "name": "",
  "admin_state_up": true,
  "pools": "03dabf47-00e7-401e-92c3-8e36c69f7f7d",
  "created_at": "2024-08-20T22:21:10",
  "provisioning_status": "ACTIVE",
  "updated_at": "2024-08-20T22:21:11",
  "delay": 6,
  "expected_codes": null,
  "max_retries": 4,
  "http_method": null,
  "timeout": 3,
  "max_retries_down": 3,
  "url_path": null,
  "type": "TCP",
  "id": "ed80259e-6727-4845-915a-68aa9d0e576d",
  "operating_status": "ONLINE",
  "http_version": null,
  "domain_name": null,
  "tags": ""
}
```

### Миграция при помощи скриптов

Для миграции балансировщиков написан скрипт [copy-loadbalancer.sh](../../copy-loadbalancer.sh). Этот скрипт не требует изменения целевой инфраструктуры, поэтому техокно не нужно.

Для миграции правил балансировки написан скрипт [copy-loadbalancer-rules.sh](../../copy-loadbalancer-rules.sh). Для данного скрипта требуется техническое окно, так как виртуальные машины, которые ранее были на neutron вместе с балансировщиком, должны быть перенесены уже на sprut. 
Виртуальные машины можно перенести при помощи скрипта [migrator-multiple.sh](../../migrator-multiple.sh). [Инструкция по скрипту](../scripts/migrator-multiple.md). 

Базовый сценарий миграции виртуальной машины описан в [инструкции на главной странице](../../readme.md).

### Алгоритм работы скриптов
![alt text](../images/loadbalancer-copy-script-algorith.png)

### Шаг 0

Имеется исходная сетевая инфраструктура с виртуальными машинами и балансировщиками:

![alt text](../images/copy-loadbalancer-stage0.png)

### Шаг 1
![alt text](../images/copy-loadbalancer-stage1.png)

Необходимо скопировать сетевую инфраструктуру на sprut, для этого можно воспользоваться скриптом.[copy-router-and-networks.sh](./copy-router-and-networks.md)

### Шаг 2

**ВАЖНО!** На момент написания инструкции (22 августа 2024) нет возможности переносить плавающие (внешние) ip между neutron и sprut, поэтому при использовании внешнего ip для балансировщика, нужно быть готовым что он изменится после миграции.

**ВАЖНО!** Создание копии балансировщика в sprut сети никак не затрагивает работоспособность исходной инфраструктуры, поэтому для запуска скрипта [copy-loadbalancer.sh](../../copy-loadbalancer.sh) не нужно техническое окно. Техническое окно понадобится на следующих шагах при переносе виртуальных машин и правил балансировки.
 
![alt text](../images/copy-loadbalancer-stage2.png)

У балансировщиков openstack octavia нельзя изменить сеть подключения, поэтому создадим копию балансировщика в аналогичной сети на sprut.

Для этого воспользуемся скиптом [copy-loadbalancer.sh](../../copy-loadbalancer.sh).

Формат конфиг файла для скрипта **config.csv**:
```shell
<имя балансировщика в сети neutron 1>,<сеть sprut>,<подсеть sprut>,<опционально: id плавающего ip на спрут>
<имя балансировщика в сети neutron 2>,<сеть sprut>,<подсеть sprut>,<опционально: id плавающего ip на спрут>
...
```

Для запуска скрипта выполняем команду:

```bash
./copy-loadbalancer.sh config.csv
```

В результате работы скрипта, будет создан новый конфиг файл: **copy-loadbalancer-script-output-config.csv**. Данный файл будет использоваться скриптом [copy-loadbalancer-rules.sh](../../copy-loadbalancer-rules.sh) для копирования правил балансировки.

### Шаг 3

**ВАЖНО!** Для данного шага уже понадобится техническое окно, так как переключение портов у виртуальных машин подразумевает временную потерю сетевой связности.

![alt text](../images/copy-loadbalancer-stage3.png)

Мигрируем виртуальные машины при помощи скрипта [migrator-multiple.sh](../../migrator-multiple.sh).

[Инструкция по скрипту](../scripts/migrator-multiple.md). 

Базовый сценарий миграции виртуальной машины описан в [инструкции на главной странице](../../readme.md).

### Шаг 4

**ВАЖНО!** Для данного шага также требуется техническое окно, так как назначение правил балансировки занимает некоторое время, без правил балансировщик не будет направлять трафик в виртуальные машины.

![alt text](../images/copy-loadbalancer-stage4.png)

**ВАЖНО!** Для данного шага нам понадобится файл **copy-loadbalancer-script-output-config.csv**, сгенерированный на 2 шаге скриптом [copy-loadbalancer.sh](../../copy-loadbalancer.sh). Его мы подаём на вход скрипту [copy-loadbalancer-rules.sh](../../copy-loadbalancer-rules.sh).

Для запуска скрипта выполняем команду:

```bash
./copy-loadbalancer.sh copy-loadbalancer-script-output-config.csv
```

### Шаг 5

Проверяем работоспособность балансировщиков, отправляя необходимые запросы в приложения.