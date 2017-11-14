#!/bin/sh
let i=0
while [ "${i}" -le 50 ]
do
  arr[i]=`ectool motionsense|grep "^Sensor 0"`
  let i=i+1
done


   for((j=1; j<=50; j++))
   do

      if [[ ${arr[j]} != ${arr[0]} ]]
      then 
            echo "pass"
            rm /tmp/a.txt
            break
      else
            echo "fail" > /tmp/a.txt
            continue
      fi
   done
   [ -s "/tmp/a.txt" ]&&echo "fail"
   
      
