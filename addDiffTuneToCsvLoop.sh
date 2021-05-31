#!/bin/bash

codeFile=`mktemp --tmpdir code.XXXXXXXXXX`
elfFile=`mktemp --tmpdir code.elf.XXXXXXXXXX`
asmFile=`mktemp --tmpdir asm.XXXXXXXXXX`

trap "rm $codeFile $elfFile $asmFile " EXIT

echo `head -n 1 "$1"`",DiffTune"
sed 1d "$1" | while IFS= read -r line; do
   hex=`echo $line | awk -F, '{print $1$2}'`
   perl -e "print pack 'H*', \"$hex\"" > $codeFile
   llvm-objcopy-10 -I binary -O elf64-x86-64 --rename-section=.data=.text,code $codeFile $elfFile
   echo ".loop:" > $asmFile
   llvm-objdump-10 -d --no-leading-addr --no-show-raw-insn $elfFile | sed 1,7d | cut -f2- >> $asmFile
   echo "jnz .loop" >> $asmFile
   output=`../DiffTune/llvm-mca -parameters ../DiffTune/$2 -mtriple=x86_64-unknown-unknown -march=x86-64 -mcpu=haswell --all-views=0 --summary-view $asmFile`
   it=`echo "$output" | grep "Iterations:" | tr -s ' ' | cut -d' ' -f2`
   if [ "$it" != "100" ]; then
      echo "Error: Unexpected iteration count"
      exit 1
   fi
   TP=`echo "$output" | grep "Total Cycles:" | tr -s ' ' | cut -d' ' -f3`
   echo "$line,$TP"
done
