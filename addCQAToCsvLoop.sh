#!/bin/bash

run_CQA() {
   line=$1
   uarch=$2
   codeFile=`mktemp --tmpdir code.XXXXXXXXXX`
   asmFile=`mktemp --tmpdir asm.XXXXXXXXXX`
   echo $line | awk -F, '{print $1$2$3}' | fold -w 2 | awk '{print ".byte 0x" $1}' > $asmFile
   as $asmFile -o $codeFile
   tp=`../maqao.intel64.2.15.0/maqao.intel64 cqa $codeFile fct-loops=.* uarch=$uarch --confidence-levels=expert | grep 'each iteration of the binary loop takes' | head -n 1 | sed -E 's/.*takes (.*) cycles.*/\1/' | tr -d "."`
   rm $codeFile $asmFile
   echo "$line,$tp"
}
export -f run_CQA

echo `head -n 1 "$1"`",CQA"
sed 1d "$1" | parallel --keep-order run_CQA {} $2
