#!/bin/bash
echo  "##"
echo -e "\033[37;1;41m  version 0.5.1 \033[0m"

#Выполняем действие, если кол-во подключений к nginx больше connect в данный момент
connect="0"
#Выполняется действие (при соблюдении условия connect), если кол-во обращений на один хост больше больше banconnect (на основе лога nginx за последние 5 минут)
banconnect="0"
#Выполняется действие (при соблюдении условия connect), если кол-во обращений с одного IP больше n (на основе лога nginx за последние 5 минут)
n=0

#Путь до дирректории с логами nginx
logfiles=log

# Путь до дирректории со скриптом. В конце / не ставить.
home="/home/momai/test/banip/banip"
cd $home

# Путь до /etc/nginx/vhosts-resources
conf="/etc/nginx/vhosts-resources"
#conf="/home/momai/test/banip/banip/vhosts-resources"
realconnect=$(netstat -an | grep :443 | wc -l)


#имя файла с перечисленными заблокированными именами пользователей
userlist=userlist.txt

rm $userlist

FILE=blockUser
while read blockUser; do

        usr=$(echo $blockUser | awk -F "." '{print $1}')
#	echo $usr >> $userlist
	rm $conf/${usr}*/blackhole.conf
done < $FILE


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
#echo "$lo"
LANG=en_us_8859_1
logfile=$logfiles/$log

#вычесляем время последней записи. Берётся 5я строчка с конца файла
#t=$(tail -n1 $logfile | awk -F ":" '{print $2 $3}')

t=$(cat $logfile | tail -n 5 | head -1 | awk -F ":" '{print $2 $3}')

d=$(date -d "$t 5 minute ago" "+%H%M" )

#echo t= $t
#echo d= $d

#убираем дату (на проде убрать --date '-162 day')
dfix=$(date +"%d/%b/%Y:")
#echo dfix= $dfix

#выводить имена учетных записей ipsmanager в конечный файл
cat $logfile | awk -v lo="$lo" -v sp="	" -F "$dfix" '{print lo sp $1 $2}' | awk -F ":" '{print $1 $2}'  > log2.tmp
#cat log2.tmp
#сформировать список ип адресов в конечном файле
#cat $logfile | awk -F "$dfix" '{print $1 $2}' | awk -F ":" '{print $1 $2}'  > log2.tmp

#вырезаем отрезок из логов
sed -n -i "/${d}/,/${t}/{//!p}" log2.tmp
#cat log.tmp
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


#FILE=final
#while read IP; do
#     echo "IP: $IP"
#done < $FILE
	



#cat $logfile

done < $FILE


#cat final4 | awk '$0=$1' | uniq -c > final5
#sort -n final4 | awk ' {print $2} ' | uniq -c > final5
#FILE=final5
#while read test2; do

#blockid=$(echo $test2 | awk '{print $1}')
#blockuser=$(echo $test2 | awk '{print $2}')
#echo $blockid $blockuser

# если blockid больше banconnect - то блочим хост

#if [ $blockid -ge $banconnect ]; then
#fi

#test2=$(cat final5 | awk '{print $1}')
#test2=$(awk ' {print $1} ')
#echo "TEST2 = $test2"

#done < $FILE

#rm -rf final2 final3
	
FILE=final4
while read ban; do
#     echo "user: $ban"

#echo $ban >> vhosts/$ban/*site.conf

#если final4 со списокм пользователей, то: print $1 - user, print $2 - IP.
#если final4 только с IP то: print $1 - ip. user игнорируется
user=$(echo $ban | awk -F " " '{print $1}')
ip=$(echo $ban | awk -F " " '{print $2}')

#echo $user
#echo $ip

#echo $ip >> vhosts/$user/*site.conf

#awk 'NR==5{print "new line text"}7' file

#echo $ip | awk '{print $(NF-1)}'

ipdate=$(date +"%Y-%m-%dT%H:%M")
ipdatemin=$(date +"%Y-%m-%dT%H:%M" --date '+5 min')

#iptables -t filter -A INTPUT -s $ip/32 -m time --utc --datestart $ipdate --datestop $ipdatemin -j DROP

#iptables -I INPUT -s $ip/32 -m time --utc --datestart $ipdate --datestop $ipdatemin -j DROP

#echo "         if (`$remote_addr` ~ ($ip)) {         return 404;}" >> vhosts/$user/*site.conf


done < $FILE
function blockfunc {
cd $home
FILE=blockUser
while read blockUser; do

	usr=$(echo $blockUser | awk -F "." '{print $1}')
	echo $usr >> $home/$userlist
#	echo=$usr >> block

# создание отдельного файла конфигурации nginx
if [ -e $conf/${usr}*/blackhole.conf ]
then
# если файл существует
echo "block site"
else
# иначе — создать файл и сделать в нем новую запись
cd $conf/${usr}*
cp $home/blackhole.conf .
#cp $home/blackhole.conf $conf/${usr}*/blackhole.conf
echo "block only site"
fi

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
echo $blockid
echo $blockuser

# если blockid больше banconnect - то блочим хост



#test2=$(cat final5 | awk '{print $1}')
#test2=$(awk ' {print $1} ')
#echo "TEST2 = $test2"

done < $FILE

if [ $blockid -ge $banconnect ]; then
cd $home
FILE=final5
while read final5; do

        usr=$blockuser
        echo $usr >> $home/$userlist
#       echo=$usr >> block

# создание отдельного файла конфигурации nginx
#if [ -e $conf/${usr}*/blackhole.conf ]; then
# если файл существует
#echo "сайт $usr уже заблокирован"
#else
# иначе — создать файл и сделать в нем новую запись
cd $conf/${usr}*
cp $home/blackhole.conf .
#cp $home/blackhole.conf $conf/${usr}*/blackhole.conf
echo "сайт $usr заблокирован"
#fi

done < $FILE


else
echo not block1
fi

cd $home

else
echo quit script
fi

service nginx reload

#rm final2 final3 ip2.tmp log2.tmp log.id number2 user4.tmp user.id
