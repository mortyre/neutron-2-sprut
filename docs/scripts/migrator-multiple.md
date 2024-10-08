## Скрипт для миграции нескольких виртуальных машин между SDN

[migrator-multiple.sh](./migrator-multiple.md)

Для миграции виртуальных машин используется скрипт migrator-multiple.sh, который работает по следующему алгоритму:

<img src="./images/port_migration.png" width="600">

Сценарий предполагает выполнение последовательности действий, которая позволит переключить сетевой интерфейс ВМ в новый SDN. При этом важно помнить, что данная операция выполняется с разрывом сетевой связности.

**ВАЖНО!** У мигрируемых вм должно быть одно подключение к сети, для миграции вм с несколькими портами необходимо использовать другой скрипт.

**ВАЖНО!** Скрипт выполняет все действия (инспекция, создание, переключение портов) в рамках одной итерации. На одну вм уходит ~45 секунд.  В случае если техокно необходимо сократить, можно использовать связку из скриптов audit-create-sprut-ports.sh (создание портов) и audit-replace-neutron-to-sprut.sh (переключение). В таком случае на вм будет уходить ~15 секунд.

**ВАЖНО!** Скрипт копирует секьюрити группы с портов и вешает на новые порты, но группы должны быть заранее созданы на sprut и иметь исходное имя группы на нейтроне + постфикс -sprut. Например: на нейтроновском порте вести группа web, значит нужно заранее создать для спрута секьюрити группу web-sprut. Для этого можно использовать скрипт в этом репозитории copy-security-group.

**ВАЖНО!** Перед выполнением скрипта убедиться, что **ВМ активна**, а сеть и подсеть в SDN Sprut с повторяющейся адресацией по отношению к сети и подсети Neutron созданы.


```shell
./migrator-multiple.sh <имя .csv файла>
```

формат csv файла:

```
Имя_вм_1,имя_новой_сети_на_sprut,имя_новой_подсети_на_sprut
Имя_вм_1,имя_новой_сети_на_sprut,имя_новой_подсети_на_sprut,id_плавающего_ip_sprut
...
```
id_плавающего_ip_sprut - опциональный параметр, позваляют сразу навесить на новый порт плавающий ip в сети sprut.

**ВАЖНО!** Разделителем в csv файле должна быть запятая

#### Пост-миграционные шаги

ВАЖНО! На уровне ОС следует выполнить опрос DHCP сервера для получения IP адреса на вновь добавленный сетевой интерфейс.

Для Windows:

```
ipconfig /release
ipconfig /renew
```

Для Lunix:
```bash
dhclient
```
