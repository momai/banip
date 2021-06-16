#!/bin/bash

#Скрипт добавить в cron на каждые 5 минут. После отработки скрипта, создается файл final4
#Путь до логов
logs='log'

#кол-во совпадений по IP
n=3

#ищем логи
find $logs/. -name "*access*" -type f -exec basename {} \; | cut -d "." -f 1 > user.id
find $logs/ -name "*access*"  -type f -exec basename {} \; > log.id



FILE=user.id
while read user; do
     echo "user: $user"
done < $FILE



FILE=log.id
while read log; do
     echo "log: $log"

	
lo="$log"
LANG=en_us_8859_1
logfile=$logs/$log

#вычесляем время последней записи
t=$(tail -n1 $logfile | awk -F ":" '{print $2 $3}')

d=$(date -d "$t 5 minute ago" "+%H%M" )

#echo t= $t
#echo d= $d

#убираем дату (на проде убрать --date -3 day)
dfix=$(date +"%d/%b/%Y:" --date '-23 day')
#echo dfix= $dfix
cat $logfile | awk -v lo="$lo" -v sp="	" -F "$dfix" '{print lo sp $1 $2}' | awk -F ":" '{print $1 $2}'  > log2.tmp

sed -n -i "/${d}/,/${t}/{//!p}" log2.tmp
cat log2.tmp | awk -F '- -' '{print $1}' > ip2.tmp
sort -n ip2.tmp | uniq -c > number2
sort -nr -o number2 number2
cat number2 | awk -v n="$n" '{ if ($1>n) print $2 " ", $3 >> "final2"; }'
sed -e s,.access.log\,, final2 > final3
sort -u final3 > final4
rm -rf log2.tmp ip2.tmp log.id user.id

done < $FILE
rm -rf final2 final3 number2


FILE=final4
while read ban; do
#     echo "user: $ban"

#echo $ban >> vhosts/$ban/*site.conf


user=$(echo $ban | awk -F " " '{print $1}')
ip=$(echo $ban | awk -F " " '{print $2}')

#echo $user
#echo $ip

#echo $ip >> vhosts/$user/*site.conf

#awk 'NR==5{print "new line text"}7' file

#echo $ip | awk '{print $(NF-1)}'

ipdate=$(date +"%Y-%m-%dT%H:%M")
ipdatemin=$(date +"%Y-%m-%dT%H:%M" --date '+5 min')

iptables -t filter -A INTPUT -s $ip/32 -m time --utc --datestart $ipdate --datestop $ipdatemin -j DROP

#echo "         if (`$remote_addr` ~ ($ip)) {         return 404;}" >> vhosts/$user/*site.conf
done < $FILE


