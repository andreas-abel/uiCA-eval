#!/bin/bash

cp -R ../uiCA /tmp

run_uiCA() {
   line=$1
   arch=$2
   options=${@:3}
   codeFile=`mktemp --tmpdir code.XXXXXXXXXX`
   hex=`echo $line | awk -F, '{print $1$2$3}'`
   perl -e "print pack 'H*', \"$hex\"" > $codeFile
   tp_uica=`/tmp/uiCA/uiCA.py -TPonly -arch $arch $options -raw $codeFile 2>/dev/null | tr -d "."`
   rm $codeFile
   echo "$line,$tp_uica"
}
export -f run_uiCA

echo `head -n 1 "$1"`",uiCA"
sed 1d "$1" | parallel --keep-order run_uiCA {} $2 ${@:3}
