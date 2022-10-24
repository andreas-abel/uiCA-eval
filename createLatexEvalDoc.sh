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

cqaVersion=`cat addCQAToCsvLoop.sh | sed -n -e 's/^.*intel64\.\(.*\)\/maqao.*/\1/p'`

echo "\documentclass[sigconf,nonacm]{acmart}" > eval.tex
echo "\usepackage{booktabs}" >> eval.tex
echo "\usepackage{import}" >> eval.tex
echo "\usepackage{multirow}" >> eval.tex
echo "\usepackage{pgfplots}" >> eval.tex
echo "\pgfplotsset{compat=1.16}" >> eval.tex
echo "\usepackage{subcaption}" >> eval.tex
echo "\usepackage{xspace}" >> eval.tex
echo "\newcommand{\bhivel}{\emph{BHive\textsubscript{L}}\xspace}" >> eval.tex
echo "\newcommand{\bhiveu}{\emph{BHive\textsubscript{U}}\xspace}" >> eval.tex
echo "\newcommand{\uiCA}{uiCA\xspace}" >> eval.tex

echo "\begin{document}" >> eval.tex
echo "\title{}\title{}" >> eval.tex
echo "\thispagestyle{empty}" >> eval.tex

echo "" >> eval.tex
echo "\newcommand{\wrongDef}[1]{\textcolor{gray}{#1}}" >> eval.tex
echo "\begin{table}" >> eval.tex
echo "\caption{Comparison of different tools on \bhiveu and \bhivel}" >> eval.tex
echo "\begin{center}" >> eval.tex
echo "\resizebox*{!}{.975\textheight}{" >> eval.tex
echo "\begin{tabular}{llrcrc}" >> eval.tex
echo "\toprule" >> eval.tex
echo "& & \multicolumn{2}{c}{\textbf{\bhiveu}} & \multicolumn{2}{c}{\textbf{\bhivel}}\\\\  \cmidrule(lr){3-4}\cmidrule(lr){5-6}" >> eval.tex
echo "\textbf{{$\mu$}Arch}  & \textbf{Predictor} & \textbf{MAPE} & \textbf{Kendall} & \textbf{MAPE} & \textbf{Kendall} \\\\" >> eval.tex
echo "\midrule" >> eval.tex
echo "\multirow{2}{*}{RKL}  & \uiCA & `getEntries rkl '2 3'` & `getEntriesLoop rkl '5 6'` \\\\" >> eval.tex
echo "                      & Baseline & `getEntries rkl '2 -baselineUnroll -memWritePorts 2'` & `getEntriesLoop rkl '5 -baselineLoop -issueWidth 5 -memWritePorts 2'`\\\\" >> eval.tex
echo "\midrule" >> eval.tex
echo "\multirow{3}{*}{TGL}  & \uiCA & `getEntries tgl '3 4'` & `getEntriesLoop tgl '7 8'` \\\\" >> eval.tex
echo "                      & llvm-mca-10 & `getEntriesWrongDef tgl '3 2'` & `getEntriesLoop tgl '7 5'`\\\\" >> eval.tex
echo "                      & CQA ${cqaVersion} & & & `getEntriesLoop tgl '7 6'` \\\\" >> eval.tex
echo "                      & Baseline & `getEntries tgl '3 -baselineUnroll -memWritePorts 2'` & `getEntriesLoop tgl '7 -baselineLoop -issueWidth 5 -memWritePorts 2'`\\\\" >> eval.tex
echo "\midrule" >> eval.tex
echo "\multirow{5}{*}{ICL}  & \uiCA & `getEntries icl '4 5'` & `getEntriesLoop icl '8 9'` \\\\" >> eval.tex
echo "                      & OSACA & `getEntriesWrongDef icl '4 3'` & `getEntriesLoop icl '8 6'` \\\\" >> eval.tex
echo "                      & llvm-mca-10 & `getEntriesWrongDef icl '4 2'` & `getEntriesLoop icl '8 5'` \\\\" >> eval.tex
echo "                      & CQA ${cqaVersion} & & & `getEntriesLoop icl '8 7'` \\\\" >> eval.tex
echo "                      & Baseline & `getEntries icl '4 -baselineUnroll -memWritePorts 2'` & `getEntriesLoop icl '8 -baselineLoop -issueWidth 5 -memWritePorts 2'`\\\\" >> eval.tex
echo "\midrule" >> eval.tex
echo "\multirow{4}{*}{CLX}  & \uiCA & `getEntries clx '4 5'` & `getEntriesLoop clx '7 8'` \\\\" >> eval.tex
echo "                      & llvm-mca-10 & `getEntriesWrongDef clx '4 2'` & `getEntriesLoop clx '7 5'` \\\\" >> eval.tex
echo "                      & OSACA & `getEntriesWrongDef clx '4 3'` & `getEntriesLoop clx '7 6'` \\\\" >> eval.tex
echo "                      & Baseline & `getEntries clx '4 -baselineUnroll'` & `getEntriesLoop clx '7 -baselineLoop -issueWidth 4'`\\\\" >> eval.tex
echo "\midrule" >> eval.tex
echo "\multirow{11}{*}{SKL} & \uiCA & `getEntries skl '11 12'` & `getEntriesLoop skl '14 15'` \\\\" >> eval.tex
echo "                      & Ithemal & `getEntries skl '11 7'` & `getEntriesLoopWrongDef skl '14 9'` \\\\" >> eval.tex
echo "                      & IACA 3.0 & `getEntriesWrongDef skl '11 3'` & `getEntriesLoop skl '14 5'` \\\\" >> eval.tex
echo "                      & IACA 2.3 & `getEntriesWrongDef skl '11 4'` & `getEntriesLoop skl '14 6'` \\\\" >> eval.tex
echo "                      & OSACA & `getEntriesWrongDef skl '11 8'` & `getEntriesLoop skl '14 10'` \\\\" >> eval.tex
echo "                      & llvm-mca-10 & `getEntriesWrongDef skl '11 5'` & `getEntriesLoop skl '14 7'` \\\\" >> eval.tex
echo "                      & llvm-mca-8 & `getEntriesWrongDef skl '11 9'` & `getEntriesLoop skl '14 11'` \\\\" >> eval.tex
echo "                      & DiffTune & `getEntries skl '11 10'` & `getEntriesLoop skl '14 12'` \\\\" >> eval.tex
echo "                      & CQA ${cqaVersion} & & & `getEntriesLoop skl '14 13'` \\\\" >> eval.tex
echo "                      & \emph{Measured (orig.)} & `getEntries skl '11 2'` \\\\" >> eval.tex
echo "                      & Baseline & `getEntries skl '11 -baselineUnroll'` & `getEntriesLoop skl '14 -baselineLoop -issueWidth 4'`\\\\" >> eval.tex
echo "\midrule" >> eval.tex
echo "\multirow{7}{*}{BDW}  & \uiCA & `getEntries bdw '6 7'` & `getEntriesLoop bdw '10 11'` \\\\ " >> eval.tex
echo "                      & IACA 3.0 & `getEntriesWrongDef bdw '6 2'` & `getEntriesLoop bdw '10 5'` \\\\" >> eval.tex
echo "                      & IACA 2.3 & `getEntriesWrongDef bdw '6 3'` & `getEntriesLoop bdw '10 6'` \\\\" >> eval.tex
echo "                      & OSACA & `getEntriesWrongDef bdw '6 5'` & `getEntriesLoop bdw '10 8'` \\\\" >> eval.tex
echo "                      & llvm-mca-10 & `getEntriesWrongDef bdw '6 4'` & `getEntriesLoop bdw '10 7'` \\\\" >> eval.tex
echo "                      & CQA ${cqaVersion} & & & `getEntriesLoop bdw '10 9'` \\\\" >> eval.tex
echo "                      & Baseline & `getEntries bdw '6 -baselineUnroll'` & `getEntriesLoop bdw '10 -baselineLoop -issueWidth 4'`\\\\" >> eval.tex
echo "\midrule" >> eval.tex
echo "\multirow{11}{*}{HSW} & \uiCA & `getEntries hsw '11 12'` & `getEntriesLoop hsw '14 15'` \\\\ " >> eval.tex
echo "                      & Ithemal & `getEntries hsw '11 7'` & `getEntriesLoopWrongDef hsw '14 9'` \\\\" >> eval.tex
echo "                      & IACA 3.0 & `getEntriesWrongDef hsw '11 3'` & `getEntriesLoop hsw '14 5'` \\\\" >> eval.tex
echo "                      & IACA 2.3 & `getEntriesWrongDef hsw '11 4'` & `getEntriesLoop hsw '14 6'` \\\\" >> eval.tex
echo "                      & OSACA & `getEntriesWrongDef hsw '11 8'` & `getEntriesLoop hsw '14 10'` \\\\" >> eval.tex
echo "                      & llvm-mca-10 & `getEntriesWrongDef hsw '11 5'` & `getEntriesLoop hsw '14 7'` \\\\" >> eval.tex
echo "                      & llvm-mca-8 & `getEntriesWrongDef hsw '11 9'` & `getEntriesLoop hsw '14 11'` \\\\" >> eval.tex
echo "                      & DiffTune & `getEntries hsw '11 10'` & `getEntriesLoop hsw '14 12'` \\\\" >> eval.tex
echo "                      & CQA ${cqaVersion} & & & `getEntriesLoop hsw '14 13'` \\\\" >> eval.tex
echo "                      & \emph{Measured (orig.)} & `getEntries hsw '11 2'` \\\\" >> eval.tex
echo "                      & Baseline & `getEntries hsw '11 -baselineUnroll'` & `getEntriesLoop hsw '14 -baselineLoop -issueWidth 4'`\\\\" >> eval.tex
echo "\midrule" >> eval.tex
echo "\multirow{10}{*}{IVB} & \uiCA & `getEntries ivb '10 11'` & `getEntriesLoop ivb '13 14'` \\\\ " >> eval.tex
echo "                      & Ithemal & `getEntries ivb '10 6'` & `getEntriesLoopWrongDef ivb '13 8'` \\\\" >> eval.tex
echo "                      & IACA 2.3 & `getEntriesWrongDef ivb '10 3'` & `getEntriesLoop ivb '13 5'` \\\\" >> eval.tex
echo "                      & OSACA & `getEntriesWrongDef ivb '10 7'` & `getEntriesLoop ivb '13 9'` \\\\" >> eval.tex
echo "                      & llvm-mca-10 & `getEntriesWrongDef ivb '10 4'` & `getEntriesLoop ivb '13 6'` \\\\" >> eval.tex
echo "                      & llvm-mca-8 & `getEntriesWrongDef ivb '10 8'` & `getEntriesLoop ivb '13 10'` \\\\" >> eval.tex
echo "                      & DiffTune & `getEntries ivb '10 9'` & `getEntriesLoop ivb '13 11'` \\\\" >> eval.tex
echo "                      & CQA ${cqaVersion} & & & `getEntriesLoop ivb '13 12'` \\\\" >> eval.tex
echo "                      & \emph{Measured (orig.)} & `getEntries ivb '10 2'` \\\\" >> eval.tex
echo "                      & Baseline & `getEntries ivb '10 -baselineUnroll'` & `getEntriesLoop ivb '13 -baselineLoop -issueWidth 4'`\\\\" >> eval.tex
echo "\midrule" >> eval.tex
echo "\multirow{6}{*}{SNB}  & \uiCA & `getEntries snb '5 6'` & `getEntriesLoop snb '9 10'` \\\\" >> eval.tex
echo "                      & IACA 2.3 & `getEntriesWrongDef snb '5 2'` & `getEntriesLoop snb '9 5'` \\\\" >> eval.tex
echo "                      & OSACA & `getEntriesWrongDef snb '5 4'` & `getEntriesLoop snb '9 7'` \\\\" >> eval.tex
echo "                      & llvm-mca-10 & `getEntriesWrongDef snb '5 3'` & `getEntriesLoop snb '9 6'` \\\\" >> eval.tex
echo "                      & CQA ${cqaVersion} & & & `getEntriesLoop snb '9 8'` \\\\" >> eval.tex
echo "                      & Baseline & `getEntries snb '5 -baselineUnroll'` & `getEntriesLoop snb '9 -baselineLoop -issueWidth 4'`\\\\" >> eval.tex
echo "\bottomrule" >> eval.tex
echo "\end{tabular}}" >> eval.tex
echo "\end{center}" >> eval.tex
echo "\end{table}" >> eval.tex
echo "" >> eval.tex

echo "\begin{table*}" >> eval.tex
echo "\caption{Influence of the simulation of different microarchitectural components on the prediction accuracy}" >> eval.tex
echo "\begin{tabular}{llrcrc}" >> eval.tex
echo "\toprule" >> eval.tex
echo "& & \multicolumn{2}{c}{\textbf{\bhiveu}} & \multicolumn{2}{c}{\textbf{\bhivel}}\\\\  \cmidrule(lr){3-4}\cmidrule(lr){5-6}" >> eval.tex
echo "\textbf{{$\mu$}Arch} & \textbf{Predictor} & \textbf{MAPE} & \textbf{Kendall} & \textbf{MAPE} & \textbf{Kendall}\\\\" >> eval.tex
echo "\midrule" >> eval.tex
echo "\multirow{7}{*}{CLX (all benchmarks)} & \uiCA & `getEntries clx '4 5'` & `getEntriesLoop clx '7 8'` \\\\" >> eval.tex
echo "                      & \uiCA with simple front end & `getEntries clx '4 5' _simpleFE` & `getEntriesLoop clx '7 8' _simpleFE`\\\\" >> eval.tex
echo "                      & \uiCA with simple port assignment & `getEntries clx '4 5' _simplePorts` & `getEntriesLoop clx '7 8' _simplePorts`\\\\" >> eval.tex
echo "                      & \uiCA without micro fusion & `getEntries clx '4 5' _noMicroFusion` & `getEntriesLoop clx '7 8' _noMicroFusion`\\\\" >> eval.tex
echo "                      & \uiCA without macro fusion & `getEntries clx '4 5' _noMacroFusion` & `getEntriesLoop clx '7 8' _noMacroFusion`\\\\" >> eval.tex
echo "                      & \uiCA without LSD unrolling & `getEntries clx '4 5' _noLSDUnrolling` & `getEntriesLoop clx '7 8' _noLSDUnrolling`\\\\" >> eval.tex
echo "                      & Baseline & `getEntries clx '4 -baselineUnroll'` & `getEntriesLoop clx '7 -baselineLoop -issueWidth 4'`\\\\" >> eval.tex
echo "\midrule" >> eval.tex
echo "\multirow{4}{*}{CLX (benchmarks with moves)} & \uiCA & `getEntries clx '4 5' _moveElim` & `getEntriesLoop clx '7 8' _moveElim` \\\\" >> eval.tex
echo "                      & \uiCA without move elimination & `getEntries clx '4 5' _noMoveElim` & `getEntriesLoop clx '7 8' _noMoveElim`\\\\" >> eval.tex
echo "                      & \uiCA with full move elimination & `getEntries clx '4 5' _fullMoveElim` & `getEntriesLoop clx '7 8' _fullMoveElim`\\\\" >> eval.tex
echo "                      & Baseline & `getEntries clx '4 -baselineUnroll' _moveElim` & `getEntriesLoop clx '7 -baselineLoop -issueWidth 4' _moveElim`\\\\" >> eval.tex
echo "\bottomrule" >> eval.tex
echo "\end{tabular}" >> eval.tex
echo "\end{table*}" >> eval.tex
echo "" >> eval.tex

echo "\clearpage" >> eval.tex
echo "\appendix" >> eval.tex
echo "" >> eval.tex

./createHeatmaps.sh >> eval.tex

echo "\end{document}" >> eval.tex

pdflatex eval.tex
