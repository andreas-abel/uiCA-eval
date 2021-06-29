#!/bin/bash

codeFile=`mktemp --tmpdir code.XXXXXXXXXX`
trap "rm $codeFile" EXIT

echo `head -n 1 "$1"`",uiCA"
sed 1d "$1" | while IFS= read -r line; do
   hex=`echo $line | cut -d, -f1`
   perl -e "print pack 'H*', \"$hex\"" > $codeFile
   tp_uica=`../uiCA/uiCA.py -TPonly -arch "$2" $3 -raw $codeFile 2>/dev/null | tr -d "."`
   echo "$line,$tp_uica"
done
