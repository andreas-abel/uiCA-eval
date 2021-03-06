#!/bin/bash

tmpFile=`mktemp --tmpdir tmp.XXXXXXXXXX`
trap "rm $tmpFile" EXIT

getEntries() {
   output=`./avgError.py "$1/$1""_uica""$3"".csv" $2 -metric MAPE,kendall -round`
   MAPE=`echo "$output" | grep MAPE | cut -d" "  -f2`
   kendall=`echo "$output" | grep Kendall | cut -d" "  -f2`
   echo "${MAPE}\% & ${kendall}"
}

getEntriesWrongDef() {
   output=`./avgError.py "$1/$1""_uica""$3"".csv" $2 -metric MAPE,kendall -round`
   MAPE=`echo "$output" | grep MAPE | cut -d" "  -f2`
   kendall=`echo "$output" | grep Kendall | cut -d" "  -f2`
   echo "\wrongDef{${MAPE}\%} & \wrongDef{${kendall}}"
}

getEntriesLoop() {
   cp "$1/$1""_loop_uica""$3"".csv" $tmpFile
   tail -n +2  "$1/$1""_loop5_uica""$3"".csv" >> $tmpFile
   output=`./avgError.py $tmpFile $2 -metric MAPE,kendall -round`
   MAPE=`echo "$output" | grep MAPE | cut -d" "  -f2`
   kendall=`echo "$output" | grep Kendall | cut -d" "  -f2`
   echo "${MAPE}\% & ${kendall}"
}

getEntriesLoopWrongDef() {
   cp "$1/$1""_loop_uica""$3"".csv" $tmpFile
   tail -n +2  "$1/$1""_loop5_uica""$3"".csv" >> $tmpFile
   output=`./avgError.py $tmpFile $2 -metric MAPE,kendall -round`
   MAPE=`echo "$output" | grep MAPE | cut -d" "  -f2`
   kendall=`echo "$output" | grep Kendall | cut -d" "  -f2`
   echo "\wrongDef{${MAPE}\%} & \wrongDef{${kendall}}"
}

echo "\newcommand{\wrongDef}[1]{\textcolor{gray}{#1}}"
echo "\begin{table}"
echo "\caption{Comparison of different tools on \bhiveu and \bhivel}"
echo "\labeltab{compBHive}"
echo "\begin{center}"
echo "\resizebox*{!}{.975\textheight}{"
echo "\begin{tabular}{llrcrc}"
echo "\toprule"
echo "& & \multicolumn{2}{c}{\textbf{\bhiveu}} & \multicolumn{2}{c}{\textbf{\bhivel}}\\\\  \cmidrule(lr){3-4}\cmidrule(lr){5-6}"
echo "\textbf{{$\mu$}Arch}  & \textbf{Predictor} & \textbf{MAPE} & \textbf{Kendall} & \textbf{MAPE} & \textbf{Kendall} \\\\"
echo "\midrule"
echo "\multirow{2}{*}{RKL}  & \uiCA & `getEntries rkl '2 3'` & `getEntriesLoop rkl '5 6'` \\\\"
echo "                      & Baseline & `getEntries rkl '2 -baselineUnroll -memWritePorts 2'` & `getEntriesLoop rkl '5 -baselineLoop -issueWidth 5 -memWritePorts 2'`\\\\"
echo "\midrule"
echo "\multirow{3}{*}{TGL}  & \uiCA & `getEntries tgl '3 4'` & `getEntriesLoop tgl '6 7'` \\\\"
echo "                      & llvm-mca-10 & `getEntriesWrongDef tgl '3 2'` & `getEntriesLoop tgl '6 5'`\\\\"
echo "                      & Baseline & `getEntries tgl '3 -baselineUnroll -memWritePorts 2'` & `getEntriesLoop tgl '6 -baselineLoop -issueWidth 5 -memWritePorts 2'`\\\\"
echo "\midrule"
echo "\multirow{5}{*}{ICL}  & \uiCA & `getEntries icl '4 5'` & `getEntriesLoop icl '8 9'` \\\\"
echo "                      & OSACA & `getEntriesWrongDef icl '4 3'` & `getEntriesLoop icl '8 6'` \\\\"
echo "                      & llvm-mca-10 & `getEntriesWrongDef icl '4 2'` & `getEntriesLoop icl '8 5'` \\\\"
echo "                      & CQA & & & `getEntriesLoop icl '8 7'` \\\\"
echo "                      & Baseline & `getEntries icl '4 -baselineUnroll -memWritePorts 2'` & `getEntriesLoop icl '8 -baselineLoop -issueWidth 5 -memWritePorts 2'`\\\\"
echo "\midrule"
echo "\multirow{4}{*}{CLX}  & \uiCA & `getEntries clx '4 5'` & `getEntriesLoop clx '7 8'` \\\\"
echo "                      & llvm-mca-10 & `getEntriesWrongDef clx '4 2'` & `getEntriesLoop clx '7 5'` \\\\"
echo "                      & OSACA & `getEntriesWrongDef clx '4 3'` & `getEntriesLoop clx '7 6'` \\\\"
echo "                      & Baseline & `getEntries clx '4 -baselineUnroll'` & `getEntriesLoop clx '7 -baselineLoop -issueWidth 4'`\\\\"
echo "\midrule"
echo "\multirow{11}{*}{SKL} & \uiCA & `getEntries skl '11 12'` & `getEntriesLoop skl '14 15'` \\\\"
echo "                      & Ithemal & `getEntries skl '11 7'` & `getEntriesLoopWrongDef skl '14 9'` \\\\"
echo "                      & IACA 3.0 & `getEntriesWrongDef skl '11 3'` & `getEntriesLoop skl '14 5'` \\\\"
echo "                      & IACA 2.3 & `getEntriesWrongDef skl '11 4'` & `getEntriesLoop skl '14 6'` \\\\"
echo "                      & OSACA & `getEntriesWrongDef skl '11 8'` & `getEntriesLoop skl '14 10'` \\\\"
echo "                      & llvm-mca-10 & `getEntriesWrongDef skl '11 5'` & `getEntriesLoop skl '14 7'` \\\\"
echo "                      & llvm-mca-8 & `getEntriesWrongDef skl '11 9'` & `getEntriesLoop skl '14 11'` \\\\"
echo "                      & DiffTune & `getEntries skl '11 10'` & `getEntriesLoop skl '14 12'` \\\\"
echo "                      & CQA & & & `getEntriesLoop skl '14 13'` \\\\"
echo "                      & \emph{Measured~\\cite{Chen19}} & `getEntries skl '11 2'` \\\\"
echo "                      & Baseline & `getEntries skl '11 -baselineUnroll'` & `getEntriesLoop skl '14 -baselineLoop -issueWidth 4'`\\\\"
echo "\midrule"
echo "\multirow{7}{*}{BDW}  & \uiCA & `getEntries bdw '6 7'` & `getEntriesLoop bdw '10 11'` \\\\ "
echo "                      & IACA 3.0 & `getEntriesWrongDef bdw '6 2'` & `getEntriesLoop bdw '10 5'` \\\\"
echo "                      & IACA 2.3 & `getEntriesWrongDef bdw '6 3'` & `getEntriesLoop bdw '10 6'` \\\\"
echo "                      & OSACA & `getEntriesWrongDef bdw '6 5'` & `getEntriesLoop bdw '10 8'` \\\\"
echo "                      & llvm-mca-10 & `getEntriesWrongDef bdw '6 4'` & `getEntriesLoop bdw '10 7'` \\\\"
echo "                      & CQA & & & `getEntriesLoop bdw '10 9'` \\\\"
echo "                      & Baseline & `getEntries bdw '6 -baselineUnroll'` & `getEntriesLoop bdw '10 -baselineLoop -issueWidth 4'`\\\\"
echo "\midrule"
echo "\multirow{11}{*}{HSW} & \uiCA & `getEntries hsw '11 12'` & `getEntriesLoop hsw '14 15'` \\\\ "
echo "                      & Ithemal & `getEntries hsw '11 7'` & `getEntriesLoopWrongDef hsw '14 9'` \\\\"
echo "                      & IACA 3.0 & `getEntriesWrongDef hsw '11 3'` & `getEntriesLoop hsw '14 5'` \\\\"
echo "                      & IACA 2.3 & `getEntriesWrongDef hsw '11 4'` & `getEntriesLoop hsw '14 6'` \\\\"
echo "                      & OSACA & `getEntriesWrongDef hsw '11 8'` & `getEntriesLoop hsw '14 10'` \\\\"
echo "                      & llvm-mca-10 & `getEntriesWrongDef hsw '11 5'` & `getEntriesLoop hsw '14 7'` \\\\"
echo "                      & llvm-mca-8 & `getEntriesWrongDef hsw '11 9'` & `getEntriesLoop hsw '14 11'` \\\\"
echo "                      & DiffTune & `getEntries hsw '11 10'` & `getEntriesLoop hsw '14 12'` \\\\"
echo "                      & CQA & & & `getEntriesLoop hsw '14 13'` \\\\"
echo "                      & \emph{Measured~\\cite{Chen19}} & `getEntries hsw '11 2'` \\\\"
echo "                      & Baseline & `getEntries hsw '11 -baselineUnroll'` & `getEntriesLoop hsw '14 -baselineLoop -issueWidth 4'`\\\\"
echo "\midrule"
echo "\multirow{10}{*}{IVB} & \uiCA & `getEntries ivb '10 11'` & `getEntriesLoop ivb '13 14'` \\\\ "
echo "                      & Ithemal & `getEntries ivb '10 6'` & `getEntriesLoopWrongDef ivb '13 8'` \\\\"
echo "                      & IACA 2.3 & `getEntriesWrongDef ivb '10 3'` & `getEntriesLoop ivb '13 5'` \\\\"
echo "                      & OSACA & `getEntriesWrongDef ivb '10 7'` & `getEntriesLoop ivb '13 9'` \\\\"
echo "                      & llvm-mca-10 & `getEntriesWrongDef ivb '10 4'` & `getEntriesLoop ivb '13 6'` \\\\"
echo "                      & llvm-mca-8 & `getEntriesWrongDef ivb '10 8'` & `getEntriesLoop ivb '13 10'` \\\\"
echo "                      & DiffTune & `getEntries ivb '10 9'` & `getEntriesLoop ivb '13 11'` \\\\"
echo "                      & CQA & & & `getEntriesLoop ivb '13 12'` \\\\"
echo "                      & \emph{Measured~\\cite{Chen19}} & `getEntries ivb '11 2'` \\\\"
echo "                      & Baseline & `getEntries ivb '10 -baselineUnroll'` & `getEntriesLoop ivb '13 -baselineLoop -issueWidth 4'`\\\\"
echo "\midrule"
echo "\multirow{6}{*}{SNB}  & \uiCA & `getEntries snb '5 6'` & `getEntriesLoop snb '9 10'` \\\\"
echo "                      & IACA 2.3 & `getEntriesWrongDef snb '5 2'` & `getEntriesLoop snb '9 5'` \\\\"
echo "                      & OSACA & `getEntriesWrongDef snb '5 4'` & `getEntriesLoop snb '9 7'` \\\\"
echo "                      & llvm-mca-10 & `getEntriesWrongDef snb '5 3'` & `getEntriesLoop snb '9 6'` \\\\"
echo "                      & CQA & & & `getEntriesLoop snb '9 8'` \\\\"
echo "                      & Baseline & `getEntries snb '5 -baselineUnroll'` & `getEntriesLoop snb '9 -baselineLoop -issueWidth 4'`\\\\"
echo "\bottomrule"
echo "\end{tabular}}"
echo "\end{center}"
echo "\end{table}"
echo ""

echo "\begin{table*}"
echo "\caption{Influence of the simulation of different microarchitectural components on the prediction accuracy}"
echo "\labeltab{evaluiCA}"
echo "\begin{tabular}{llrcrc}"
echo "\toprule"
echo "& & \multicolumn{2}{c}{\textbf{\bhiveu}} & \multicolumn{2}{c}{\textbf{\bhivel}}\\\\  \cmidrule(lr){3-4}\cmidrule(lr){5-6}"
echo "\textbf{{$\mu$}Arch} & \textbf{Predictor} & \textbf{MAPE} & \textbf{Kendall} & \textbf{MAPE} & \textbf{Kendall}\\\\"
echo "\midrule"
echo "\multirow{7}{*}{CLX (all benchmarks)} & \uiCA & `getEntries clx '4 5'` & `getEntriesLoop clx '7 8'` \\\\"
echo "                      & \uiCA with simple front end & `getEntries clx '4 5' _simpleFE` & `getEntriesLoop clx '7 8' _simpleFE`\\\\"
echo "                      & \uiCA with simple port assignment & `getEntries clx '4 5' _simplePorts` & `getEntriesLoop clx '7 8' _simplePorts`\\\\"
echo "                      & \uiCA without micro fusion & `getEntries clx '4 5' _noMicroFusion` & `getEntriesLoop clx '7 8' _noMicroFusion`\\\\"
echo "                      & \uiCA without macro fusion & `getEntries clx '4 5' _noMacroFusion` & `getEntriesLoop clx '7 8' _noMacroFusion`\\\\"
echo "                      & \uiCA without LSD unrolling & `getEntries clx '4 5' _noLSDUnrolling` & `getEntriesLoop clx '7 8' _noLSDUnrolling`\\\\"
echo "                      & Baseline & `getEntries clx '4 -baselineUnroll'` & `getEntriesLoop clx '7 -baselineLoop -issueWidth 4'`\\\\"
echo "\midrule"
echo "\multirow{4}{*}{CLX (benchmarks with moves)} & \uiCA & `getEntries clx '4 5' _moveElim` & `getEntriesLoop clx '7 8' _moveElim` \\\\"
echo "                      & \uiCA without move elimination & `getEntries clx '4 5' _noMoveElim` & `getEntriesLoop clx '7 8' _noMoveElim`\\\\"
echo "                      & \uiCA with full move elimination & `getEntries clx '4 5' _fullMoveElim` & `getEntriesLoop clx '7 8' _fullMoveElim`\\\\"
echo "                      & Baseline & `getEntries clx '4 -baselineUnroll' _moveElim` & `getEntriesLoop clx '7 -baselineLoop -issueWidth 4' _moveElim`\\\\"
echo "\bottomrule"
echo "\end{tabular}"
echo "\end{table*}"
echo ""

echo "\begin{table}"
echo "\caption{State of the art in basic block throughput prediction}"
echo "\labeltab{baseline}"
echo "\negvspacesmall"
echo "\begin{center}"
echo "\begin{tabular}{lrc}"
echo "\toprule"
echo "\textbf{Predictor} & \textbf{MAPE} & \textbf{Kendall's Tau} \\\\"
echo "\midrule"
echo "Ithemal & `getEntries skl_bhive '2 7'` \\\\"
echo "IACA 3.0 & `getEntries skl_bhive '2 3'` \\\\"
echo "DiffTune & `getEntries skl_bhive '2 10'` \\\\"
echo "llvm-mca-10 & `getEntries skl_bhive '2 5'` \\\\"
echo "OSACA & `getEntries skl_bhive '2 8'` \\\\"
echo "\midrule"
echo "Baseline & `getEntries skl_bhive '2 -baselineUnroll'` \\\\"
echo "\bottomrule"
echo "\end{tabular}"
echo "\end{center}"
echo "\negvspace"
echo "\end{table}"
echo ""
