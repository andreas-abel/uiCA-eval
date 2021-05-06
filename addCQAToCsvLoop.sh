#!/bin/bash

codeFile=`mktemp --tmpdir code.XXXXXXXXXX`
asmFile=`mktemp --tmpdir asm.XXXXXXXXXX`
trap "rm $codeFile $asmFile" EXIT

echo `head -n 1 "$1"`",CQA"
sed 1d "$1" | while IFS= read -r line; do
   echo $line | awk -F, '{print $1$2$3}' | fold -w 2 | awk '{print ".byte 0x" $1}' > $asmFile
   as $asmFile -o $codeFile
   tp=`../../maqao.intel64.2.13.2/maqao.intel64 cqa $codeFile fct-loops=.* uarch=$2 --confidence-levels=expert | grep 'each iteration of the binary loop takes' | head -n 1 | sed -E 's/.*takes (.*) cycles.*/\1/' | tr -d "."`
   echo "$line,$tp"
done
