#!/bin/bash

codeFile=`mktemp --tmpdir code.XXXXXXXXXX`
trap "rm $codeFile" EXIT

echo `head -n 1 "$1"`",IACA3.0"
sed 1d "$1" | while IFS= read -r line; do
   hex=`echo $line | awk -F, '{print $1$2$3}'`
   perl -e "print pack 'H*', \"BB6F000000646790${hex}BBDE000000646790\"" > $codeFile
   tp_iaca=`../iaca/iaca-version-3.0/iaca -reduceout -arch $2 $codeFile | head -n 4 | tail -n 1 | cut -d " " -f3 | tr -d "."`
   echo "$line,$tp_iaca"
done
