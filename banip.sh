#!/bin/bash
echo  "##"
echo -e "\033[37;1;41m  version 0.6.2 \033[0m"

#Выполняем действие, если кол-во подключений к nginx больше connect в данный момент
connect="0"
#Выполняется действие (при соблюдении условия connect), если кол-во обращений на один хост больше больше banconnect (на основе лога nginx за последние 5 минут)
banconnect="1"
#Выполняется действие (при соблюдении условия connect), если кол-во обращений с одного IP больше n (на основе лога nginx за последние 5 минут)
n=0

#Путь до дирректории с логами nginx
logfiles=log

# Путь до дирректории со скриптом. В конце / не ставить.
home="/home/momai/test/banip/banip"
cd $home

# Путь до /etc/nginx/vhosts-resources
#conf="/etc/nginx/vhosts-resources"
conf="/home/momai/test/banip/banip/vhosts-resources"
realconnect=$(netstat -an | grep :443 | wc -l)


#имя файла с перечисленными заблокированными именами пользователей
usertempblock=usertempblock.txt

usertemplist=usertemplist.txt

userlist=userlist.txt

rm $usertempblock
rm $usertemplist
rm $userlist
FILE=blockUser
while read blockUser; do

        usr=$(echo $blockUser | awk -F "." '{print $1}')
#	echo $usr >> $usertempblock
	rm $conf/${usr}*/blackhole.conf
done < $FILE

touch $home/userlist.txt
#echo $realconnect
if [ $realconnect -ge $connect ]; then
echo run

#rm -rf user.id log.id log2.tmp ip2.tmp number2 final2 final3 final4
#ищем логи
find $logfiles/. -name "*access*" -type f -exec basename {} \; | cut -d "." -f 1 > user.id
find $logfiles/ -name "*access*"  -type f -exec basename {} \; > log.id

FILE=log.id
while read log; do
#     echo "log: $log"

	
lo="$log"
#lo=$(cat '$log' | awk -F "." '{print $1}')
#lo=$(cat '$log' | cut -d "." -f 1)
#lo=$(cat '$log' | cut -d "." -f 2)
#echo "$lo"
LANG=en_us_8859_1
logfile=$logfiles/$log
logfile3=$logfiles/$log

#вычесляем время последней записи. Берётся 5я строчка с конца файла
#t=$(tail -n1 $logfile | awk -F ":" '{print $2 $3}')
t=$(cat $logfile | tail -n 5 | head -1 | awk -F ":" '{print $2 $3}')

d=$(date -d "$t 5 minute ago" "+%H%M" )

#echo t= $t
#echo d= $d

#убираем дату (на проде убрать --date '-184 day')
dfix=$(date +"%d/%b/%Y:")
#echo dfix= $dfix

#выводить имена учетных записей ipsmanager в конечный файл
cat $logfile | awk -v lo="$lo" -v sp="	" -F "$dfix" '{print lo sp $1 $2}' | awk -F ":" '{print $1 $2}'  > log2.tmp
#вырезаем отрезок из логов
sed -n -i "/${d}/,/${t}/{//!p}" log2.tmp

#парсим адреса
cat log2.tmp | awk -F '- -' '{print $1}' > ip2.tmp

#считаем дубли
sort -n ip2.tmp | uniq -c > number2

#сортируем в обратном порядке
sort -nr -o number2 number2

#отсекаем лишние адреса на основе $n
cat number2 | awk -v n="$n" '{ if ($1>n) print $2 " ", $3 >> "final2"; }'
# Список юзеров на блокировку
cat number2 | awk -v n="$n" '{ if ($1>n) print $2 >> "user4.tmp"; }'
sort -u user4.tmp > blockUser


sed -e s,.access.log\,, final2 > final3
#удаляем дубли
sort -u final3 > final4


done < $FILE

function blockfunc {
cd $home
FILE=blockUser
while read blockUser; do

	usr=$(echo $blockUser | awk -F "." '{print $1}')
	echo $usr >> $home/$usertempblock
#	echo=$usr >> block

#Определение юзера
nametmp=$conf/${usr}.*/*.conf
#echo name = $nametmp
name=$(echo $nametmp | awk -F "/" '{print $NF}' | sed 's/.conf$//')
#echo name - $name
echo $name >> $home/$usertemplist

# создание отдельного файла конфигурации nginx
#if [ -e $conf/${usr}*/blackhole.conf ]
#then
# если файл существует
#echo "сайт $usr пользователя $name уже заблокирован"
#else
# иначе — создать файл и сделать в нем новую запись
cd $conf/${usr}*
cp $home/blackhole.conf .
#cp $home/blackhole.conf $conf/${usr}*/blackhole.conf
echo "сайт $usr пользователя $name заблокирован"
#fi

done < $FILE
}
blockfunc

cd $home
cat final4 | awk '$0=$1' | uniq -c > final5
#sort -n final4 | awk ' {print $2} ' | uniq -c > final5

FILE=final5
while read test2; do

blockid=$(echo $test2 | awk '{print $1}')
blockuser=$(echo $test2 | awk '{print $2}')
#echo blockid = $blockid
#echo $blockuser

# если blockid больше banconnect - то блочим хост


done < $FILE

if [ $blockid -ge $banconnect ]; then
cd $home
FILE=final5
while read final5; do

        usr=$blockuser
        echo $usr >> $home/$usertempblock
#       echo=$usr >> block

#Определение юзера
nametmp=$conf/${usr}.*/*.conf
#echo name = $nametmp
name=$(echo $nametmp | awk -F "/" '{print $NF}' | sed 's/.conf$//')
#echo name - $name
echo $name >> $home/$usertemplist

# создание отдельного файла конфигурации nginx
if [ -e $conf/${usr}*/blackhole.conf ]; then
# если файл существует
echo "сайт1 $usr пользователя $name уже заблокирован"
else
# иначе — создать файл и сделать в нем новую запись
cd $conf/${usr}*
cp $home/blackhole.conf .
#cp $home/blackhole.conf $conf/${usr}*/blackhole.conf
echo "сайт1 $usr пользователя $name заблокирован"
fi

done < $FILE


uniq $home/$usertemplist > $home/$userlist


else
echo not block1
fi

cd $home

else
echo quit script
fi

service nginx reload
cd $home
rm final2 final3 ip2.tmp log2.tmp log.id user4.tmp user.id usertempblock.txt usertemplist.txt final4

# Вставить описание в созданные файлы

sed -i '1s/^/# Таблица ИП и кол-во обращений с него к хосту. за последние 5 минут, на основе лога nginx\n/' $home/number2

sed -i '1s/^/# Кол-во обращений на определенный хост за последние 5 минут\n/' $home/final5

sed -i '1s/^/# Список заблокированных пользователей\n/' $home/$userlist
