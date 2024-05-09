#!/bin/bash

tput reset
tput civis

out=`wget -q -4 -O- http://icanhazip.com`

  intro[0]=""
  intro[1]="███╗   ██╗ ██████╗ ██████╗ ███████╗███████╗███╗   ███╗ █████╗ ██████╗ ██╗  ██╗███████╗████████╗"
  intro[2]="████╗  ██║██╔═══██╗██╔══██╗██╔════╝██╔════╝████╗ ████║██╔══██╗██╔══██╗██║ ██╔╝██╔════╝╚══██╔══╝"
  intro[3]="██╔██╗ ██║██║   ██║██║  ██║█████╗  ███████╗██╔████╔██║███████║██████╔╝█████╔╝ █████╗     ██║   "
  intro[4]="██║╚██╗██║██║   ██║██║  ██║██╔══╝  ╚════██║██║╚██╔╝██║██╔══██║██╔══██╗██╔═██╗ ██╔══╝     ██║   "
  intro[5]="██║ ╚████║╚██████╔╝██████╔╝███████╗███████║██║ ╚═╝ ██║██║  ██║██║  ██║██║  ██╗███████╗   ██║   "
  intro[6]="╚═╝  ╚═══╝ ╚═════╝ ╚═════╝ ╚══════╝╚══════╝╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝   ╚═╝   "
  intro[7]=""
  k1=0
  k2=0
  k3=0
  k4=0
  k5=0
  k6=0

    for (( i=7; i>0; i-- )); do

      sleep 0.1
      clear
      let "k1 = $i"
      if [ "$k1" -lt 0 ]
      then
         let "k1 = 0"
      fi

      let "k2 = $i + 1"
      if [ "$k2" -gt 7 ]
      then
         let "k2 = 7"
      fi

      let "k3 = $i + 2"
      if [ "$k3" -gt 7 ]
      then
         let "k3 = 7"
      fi

      let "k4 = $i + 3"
      if [ "$k4" -gt 7 ]
      then
         let "k4 = 7"
      fi

      let "k5 = $i + 4"
      if [ "$k5" -gt 7 ]
      then
         let "k5 = g"
      fi

      let "k6 = $i + 5"
      if [ "$k6" -gt 7 ]
      then
         let "k6 = 7"
      fi
echo -en "
${intro[$k1]}
${intro[$k2]}
${intro[$k3]}
${intro[$k4]}
${intro[$k5]}
${intro[$k6]}
"

    done

tput cnorm

echo "
Enter token:"
read KEY

status="$(wget -NSO- 'http://127.0.0.1:3000/key?key='${KEY// }'&ip='$out 2>&1 | grep "HTTP/" |  awk '{print $2}')"

if [[ "$status" == *"403"* ]]; then
  echo "Wrong Key"
  exit 1
fi

if [[ "$status" == *"200"* ]]; then
  sudo wget -qO- 'http://127.0.0.1:3000/start?key='${KEY// }'&node=solana_keys&ip='$out | bash
else
  echo "Key not valid"
  exit 1
fi
