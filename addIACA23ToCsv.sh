#!/bin/bash

codeFile=`mktemp --tmpdir code.XXXXXXXXXX`
trap "rm $codeFile" EXIT

echo `head -n 1 "$1"`",IACA2.3"
sed 1d "$1" | while IFS= read -r line; do
   hex=`echo $line | cut -d, -f1`
   perl -e "print pack 'H*', \"BB6F000000646790${hex}BBDE00000064679090\"" > $codeFile
   iaca_out=`~/code/iaca/iaca-version-2.3/bin/iaca.sh -reduceout -arch $2 $codeFile`
   if [ $? -eq 0 ]; then
      tp_iaca=`echo "$iaca_out" | head -n 4 | tail -n 1 | cut -d " " -f3 | tr -d "."`
   else
      tp_iaca="error"
   fi
   echo "$line,$tp_iaca"
done
