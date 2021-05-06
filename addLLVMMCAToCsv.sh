#!/bin/bash

codeFile=`mktemp --tmpdir code.XXXXXXXXXX`
elfFile=`mktemp --tmpdir code.elf.XXXXXXXXXX`
asmFile=`mktemp --tmpdir asm.XXXXXXXXXX`

trap "rm $codeFile $elfFile $asmFile " EXIT

echo `head -n 1 "$2"`",LLVM-MCA-$1"
sed 1d "$2" | while IFS= read -r line; do   
   hex=`echo $line | cut -d, -f1`
   perl -e "print pack 'H*', \"$hex\"" > $codeFile
   llvm-objcopy-10 -I binary -O elf64-x86-64 --rename-section=.data=.text,code $codeFile $elfFile
   llvm-objdump-10 -d --no-leading-addr --no-show-raw-insn $elfFile | sed 1,7d | cut -f2- > $asmFile
   if [ "$1" == "8" ]; then
      output=`../../DiffTune/llvm-mca-8 --mcpu=$3 $asmFile`
   else
      output=`llvm-mca-$1 --mcpu=$3 $asmFile`
   fi
   it=`echo "$output" | grep "Iterations:" | tr -s ' ' | cut -d' ' -f2`
   if [ "$it" != "100" ]; then
      echo "Error: Unexpected iteration count"
      exit 1
   fi
   TP=`echo "$output" | grep "Total Cycles:" | tr -s ' ' | cut -d' ' -f3`
   echo "$line,$TP"
done
