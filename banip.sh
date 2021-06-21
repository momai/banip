#!/bin/bash

connect=$(netstat -an | grep :443 | wc -l)
echo $connect
if [ $connect -ge 500 ]; then
echo выполняем


#ищем логи
find log/. -name "*access*" -type f -exec basename {} \; | cut -d "." -f 1 > user.id
find log/ -name "*access*"  -type f -exec basename {} \; > log.id



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
n=3
LANG=en_us_8859_1
logfile=log/$log
#logfile=logs
#очищаем старый вывод
#echo -n > final

#вычесляем время последней записи
t=$(tail -n1 $logfile | awk -F ":" '{print $2 $3}')

d=$(date -d "$t 5 minute ago" "+%H%M" )

echo t= $t
echo d= $d

#убираем дату (на проде убрать --date -3 day)
dfix=$(date +"%d/%b/%Y:" --date '-28 day')
echo dfix= $dfix

#выводить имена учетных записей ipsmanager в конечный файл
#cat $logfile | awk -v lo="$lo" -v sp="	" -F "$dfix" '{print lo sp $1 $2}' | awk -F ":" '{print $1 $2}'  > log2.tmp

#сформировать список ип адресов в конечном файле
cat $logfile | awk -F "$dfix" '{print $1 $2}' | awk -F ":" '{print $1 $2}'  > log2.tmp
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


else
echo не выполняем
fi

