===== Форенсика и incident response, винда =====
Цель — установить ход инцидента
Подход: смотрим на всё, записываем интересное, собираем в голове картинку
=== Монтирование и автосбор ===
Утилиты под Windows
FTK
FTK Imager
Block Device
File System
Запуск
Создать виртуалку, жёсткие диски всех типов

Утилиты под Kali
qemu-nbd
modprobe nbd

Примеры как можно примонтировать образ.
...
qemu-nbd -c /dev/nbd0 -r \[clean\]\ Windows\ 10\ x64\ LTSC\ 2019-cl1.vmdk #ЗАпускаем сервер QEMU и подключаем образ в формате read-only
file -Ls /dev/nbd0 #Определение типа содержимого в файле
qemu-nbd -d /dev/nbd0 #Отключение виртуального диска
...
kpartx -a /dev/nbd0 #используется для создания отображений разделов на диске
kpartx -d /dev/nbd0 #используется для удаления отображений разделов
...
mount -o ro /dev/mapper/nbd0p3 /opt/ #  используется для примонтирования файловых систем в Linux
umount /opt/ #Позволяет от монтровать образ
...

+++++++
После того как примонтировали, используем утилиты для сбора необходимой информации
fls -r -m C: /dev/mapper/nbd0p3 > fls.txt # fls - используется для вывода списка файлов и директорий на файловой системе (В данном примере мы записываем список всех файлов рекурсивно начиная с каталога C:) 
mactime -b fls.txt > mactime.txt # Данной утилитой мы можем создать timeline
###pv -d <PID> → смотреть прогресс доступа к файлам
icat /dev/mapper/nbd0p3 107922-128-3 > recovered.file # используется для извлечения содержимого файла из файловой системы

+++++++
regripper → запустить плагины для конкретного куста

SYSTEM: services сервисы, devclass mountdev usbdevices usbstor подключённые usb-девайсы, (network nic nic2 адаптеры и айпи, compname имя компа)
SOFTWARE: soft_run автозапуск, regback кеш тасков шедулера, removdev юзб-девайсы, (apppaths imagefile перехваты ехешников, installer msis product uninstall установленные проги, networklist vista_wireless вайфайки, winver версия винды)
NTUSER.DAT: user_run автозапуск, UserAssist запущенные ехешники, recentdocs открытые файлы

+++++++

photorec → карвинг из свободного пространства
log2timeline - https://code.google.com/archive/p/log2timeline/

log2timeline -r -p -o mactime -w l2t.txt /opt/

=== Где файлы ===

Юзера
C:\Users\
C:\Users\...\NTUSER.DAT — реестр
C:\Users\...\AppData\ — от софта
C:\Users\...\AppData\Local\Temp — временные

Системы
C:\$Recycle.Bin\ — корзина
C:\$IUKYRXB.conf ← метаданные
C:\$RUKYRXB.conf ← выкинутый файл
C:\ProgramData\ — от софта
C:\Windows\System32\config — реестр
C:\Windows\Temp — временные
C:\Windows\System32\winevt\Logs — логи

=== Ручной анализ ===

Как происходит инцидент:
Попадание малвари — действие извне (прозохали), либо действие изнутри (сам запустил)
Закрепление — прописывается в автозагрузку
Деятельность — следы на файловой системе
Последствия — что малварь сделала, что утекло
IOC — хеши (md5), пути к файлам, сетевая активность, ключи реестра

Файлы
автозагрузка и сервисы в реестре
автозагрузка в таймлайне (Startup, Tasks)
Users\user\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\*.lnk
Windows\System32\Tasks\*\*
Windows\SysWOW64\Tasks\*\*

.exe в таймлайне
Temp
Логи
запущенные ехешники
логи аутхов Security.evtx
4625 = неудачный вход
4624 = успешный вход
4634 = выход
логи psexec System.evtx
7045 = создан сервис

Артефакты

Internet Explorer
Кеш — AppData\Local\Microsoft\Windows\Temporary Internet Files, AppData\Local\Microsoft\Windows\INetCache\IE\
История — AppData\Local\Microsoft\Windows\History, AppData\Local\Microsoft\Windows\WebCache
Куки — Users\...\Cookies, AppData\Local\Microsoft\Windows\INetCookies

Firefox
Кеш — AppData\Local\Mozilla\Firefox\Profiles\*\cache2\entries
История — AppData\Roaming\Mozilla\Firefox\Profiles\*\places.sqlite (select * from moz_places;)
Куки — AppData\Roaming\Mozilla\Firefox\Profiles\*\cookies.sqlite (select * from moz_cookies;)

Chrome
Кеш — AppData\Local\Google\Chrome\User Data\Default\Cache
История — AppData\Local\Google\Chrome\User Data\Default\History (select * from urls;)
Куки — AppData\Local\Google\Chrome\User Data\Default\Cookies (select * from cookies;)

Thunderbird
AppData\Roaming\Thunderbird\Profiles\*\Mail ImapMail

Outlook
AppData\Local\Microsoft\Outlook (readpst)

=== Дополнительно ===

reglookup-timeline → таймлайн ключей реестра
reglookup-recover → удалённые записи в реестре
dir /s /r c:\ | find ":$DATA"



===== Линуховая форенсика =====

Всегда внешние заражения:

− вебчик → рце под www-data → php-шелл → подъём до рута → закрепление под рутом
− бажный софт
− брут паролей

=== Запуск ===
Под Kali
qemu-nbd
kpartx
mount
XFS: mount -o ro,norecovery /dev/mapper/centos-root /opt/
EXT: mount -o ro,noload
fls -r -m /
mac-robber
mactime
log2timeline - https://code.google.com/archive/p/log2timeline/
log2timeline_legacy -p -r -o mactime -w l2t.txt -z -0400 /opt/var/log/

=== Где файлы ===

Юзера

/home/, /root/
/home/.../.* — от софта ↔ C:\Users\...\AppData\

Системы
/var/lib/ — от софта ↔ C:\ProgramData\
/etc/ — конфиги
/tmp/ — временные ↔ C:\Windows\Temp\
/var/log/ — логи

=== Ручной анализ ===

Логи софта

аутхов — SSH
/var/log/wtmp
last -i -f ./wtmp
lastlog
lastlog -R /opt/

btmp
/var/log/auth.log, secure - Accepted
CentOS: /var/log/audit/audit.log
grep USER_LOGIN audit.log | grep res=success
journalctl (systemd)

Ошмётки: /tmp/, /var/tmp/, /tmp/.X11-unix

Закрепление

Веб-шелл (php) → eval assert
find -type f -iname '*.php' -ctime -1 -ls
find -type f -cmin -2400 -ls
ls -latrc
Cron: /etc/crontab, /etc/cron*/, /var/spool/cron/
Автозапуск: /etc/rc.local, /etc/init.d/, /etc/rc5.d/, /{etc,lib}/systemd/system/
/etc/systemd/system/*.target.wants/
.bashrc
/etc/passwd

Суидники
find / -type f -perm -04000 -ls 2>/dev/null

Подмена системных файлов
rpm -Va
debsums
md5sum -c /var/lib/dpkg/info/*.md5sums | pv | grep -v ': OK$'
Бекдор в sshd

=== Дополнительно ===

Карвинг логов
Таймстампы ctime
Анализ SSH-бекдора
Пропатчена функция сравнения пароля → флаг, что используется бекдор
Пропатчены функи логирования → работают, только если не стоит флаг
XREFы по строчке "Accepted"
