#!/bin/bash
echo  "##"
echo -e "\033[37;1;41m  version 0.4 \033[0m fix defining the last line "

#Выполняем действие, если кол-во подключений к nginx больше connect в данный момент
connect="0"

#Выполняется действие (при соблюдении условия connect), если кол-во обращений с одного IP больше n (на основе лога nginx за последние 5 минут)
n=30

#Путь до дирректории с логами nginx
logfiles=log

realconnect=$(netstat -an | grep :443 | wc -l)

#echo $realconnect
if [ $realconnect -ge $connect ]; then
#echo выполняем

touch user.id log.id log2.tmp ip2.tmp number2 final2 final3 final4
#ищем логи
find $logfiles/. -name "*access*" -type f -exec basename {} \; | cut -d "." -f 1 > user.id
find $logfiles/ -name "*access*"  -type f -exec basename {} \; > log.id



#FILE=user.id
#while read user; do
#     echo "user: $user"
#done < $FILE



FILE=log.id
while read log; do
     echo "log: $log"

	
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

echo t= $t
echo d= $d

#убираем дату (на проде убрать --date '-28 day')
dfix=$(date +"%d/%b/%Y:")
echo dfix= $dfix

#выводить имена учетных записей ipsmanager в конечный файл
cat $logfile | awk -v lo="$lo" -v sp="	" -F "$dfix" '{print lo sp $1 $2}' | awk -F ":" '{print $1 $2}'  > log2.tmp

#сформировать список ип адресов в конечном файле
#cat $logfile | awk -F "$dfix" '{print $1 $2}' | awk -F ":" '{print $1 $2}'  > log2.tmp
#echo log.tmp
#cat log.tmp

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

sed -e s,.access.log\,, final2 > final3
#удаляем дубли
sort -u final3 > final4

#rm -rf log.tmp ip.tmp


#FILE=final
#while read IP; do
#     echo "IP: $IP"
#done < $FILE
	



#cat $logfile

done < $FILE
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


else
echo не выполняем
fi

