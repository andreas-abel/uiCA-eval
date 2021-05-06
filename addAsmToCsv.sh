#!/bin/bash

echo "hex,asm,measurement_BHive"
sed 1d "$1" | while IFS= read -r line; do
   hex=`echo $line | cut -d, -f1`
   perl -e "print pack 'H*', \"$hex\"" > code
   asm=`objdump -b binary -Mintel,x86-64 -m i386 --no-show-raw-insn -D code | sed 1,7d |awk '{$1=""; print $0}' |tr '\n' ';' | cut -c2-`
   tp=`echo $line | cut -d, -f2`
   echo "$hex,\"${asm::-1}\",$tp"
done 
