# banip
Скрипт ищет *access* логи nginx по заданному пути, отрезает от него последние 5 минут, формирует список IP адресов с сопоставлением имени файла лога (что соответствует имени пользователя).


Поместить файл в любую пустую директорию, указать путь до логов в переменной logs
указать кол-во совпадений ИП после которого будет блокироваться адрес.
Прописать в cron  выполнение скрипта на каждые 5 минут. 
По отработке скрипта сформируется файл final4 в той же дирректории

На данный момент команда iptables закомментирована! Для начала, на продакшн сервере проверим работоспособность скрипта на составление адресов и если все корректно - можно проверить блокировку.
