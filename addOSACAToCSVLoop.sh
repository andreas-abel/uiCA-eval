#!/bin/bash

codeFile=`mktemp --tmpdir code.XXXXXXXXXX`
asmFile=`mktemp --tmpdir asm.XXXXXXXXXX`
osacaFile=`mktemp --tmpdir code.XXXXXXXXXX`
trap "rm $codeFile $asmFile $osacaFile" EXIT

echo `head -n 1 "$1"`",OSACA"
sed 1d "$1" | while IFS= read -r line; do
   hex=`echo $line | awk -F, '{print $1$2}'`
   perl -e "print pack 'H*', \"$hex\"" > $codeFile
   echo "# OSACA-BEGIN" > $asmFile
   echo ".loop:" >> $asmFile
   objdump -b binary -m i386 -M x86-64 --no-show-raw-insn -D $codeFile | sed 1,7d | cut -f2- >> $asmFile
   echo "jnz .loop" >> $asmFile
   echo "# OSACA-END" >> $asmFile
   timeout 1h osaca --arch $2 --ignore-unknown $asmFile > $osacaFile
   EXIT_STATUS=$?
   
   if [ $EXIT_STATUS -eq 0 ]; then
      # based on https://github.com/RRZE-HPC/OSACA-Artifact-Appendix/blob/master/run_evaluation.sh
      LCD_LINE=`grep -n "Loop-Carried Dependencies Analysis Report" $osacaFile | awk 'BEGIN {FS=":"}{print $1}'`
      RESULT_LINE=`echo "$LCD_LINE - 3" | bc -l`
      TPS_LCD=`sed -n -e ${RESULT_LINE}p $osacaFile | awk '{$(NF-1)=""; print $0}'`
      TP=`echo $TPS_LCD | tr " " "\n" | sort -gr | head -n 1`
      TP100=`echo 100*$TP | bc | sed 's/\.00$//g'`
   elif [ $EXIT_STATUS -eq 124 ]; then
      TP100="timeout"
   else
      TP100="error"
   fi
   echo "$line,$TP100"
done
