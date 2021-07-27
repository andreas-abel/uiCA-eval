#!/bin/bash

tmpFile=`mktemp --tmpdir tmp.XXXXXXXXXX`
trap "rm $tmpFile" EXIT

createHeatmap() {
   ./avgError.py "$1/$1""_uica""$5"".csv" $2 -heatmap "$3" "$4"
}

createHeatmapLoop() {
   cp "$1/$1""_loop_uica""$5"".csv" $tmpFile
   tail -n +2  "$1/$1""_loop5_uica""$5"".csv" >> $tmpFile
   ./avgError.py $tmpFile $2 -heatmap "$3" "$4"
}

rm -rf heatmaps/
mkdir heatmaps

createHeatmap skl '11 12' 'heatmaps/hm_skl_unroll_uiCA.pgf' 'uiCA'
createHeatmap skl '11 7' 'heatmaps/hm_skl_unroll_ith.pgf' 'Ithemal'
createHeatmap skl '11 3' 'heatmaps/hm_skl_unroll_iaca3.pgf' 'IACA 3.0'
createHeatmap skl '11 4' 'heatmaps/hm_skl_unroll_iaca23.pgf' 'IACA 2.3'
createHeatmap skl '11 8' 'heatmaps/hm_skl_unroll_osaca.pgf' 'OSACA'
createHeatmap skl '11 5' 'heatmaps/hm_skl_unroll_mca.pgf' 'llvm-mca-10'
createHeatmap skl '11 10' 'heatmaps/hm_skl_unroll_difftune.pgf' 'DiffTune'
createHeatmap skl '11 -baselineUnroll' 'heatmaps/hm_skl_unroll_baseline.pgf' 'Baseline'

echo "\begin{figure}[H]"
echo "\centering"
echo "\begin{subfigure}[t]{0.33\textwidth}\resizebox{\textwidth}{!}{\import{heatmaps}{hm_skl_unroll_uiCA.pgf}}\end{subfigure}~"
echo "\begin{subfigure}[t]{0.33\textwidth}\resizebox{\textwidth}{!}{\import{heatmaps}{hm_skl_unroll_ith.pgf}}\end{subfigure}~"
echo "\begin{subfigure}[t]{0.33\textwidth}\resizebox{\textwidth}{!}{\import{heatmaps}{hm_skl_unroll_iaca3.pgf}}\end{subfigure}\par\bigskip"
echo ""
echo "\begin{subfigure}[t]{0.33\textwidth}\resizebox{\textwidth}{!}{\import{heatmaps}{hm_skl_unroll_iaca23.pgf}}\end{subfigure}~"
echo "\begin{subfigure}[t]{0.33\textwidth}\resizebox{\textwidth}{!}{\import{heatmaps}{hm_skl_unroll_osaca.pgf}}\end{subfigure}~"
echo "\begin{subfigure}[t]{0.33\textwidth}\resizebox{\textwidth}{!}{\import{heatmaps}{hm_skl_unroll_mca.pgf}}\end{subfigure}\par\bigskip"
echo ""
echo "\begin{subfigure}[t]{0.33\textwidth}\resizebox{\textwidth}{!}{\import{heatmaps}{hm_skl_unroll_difftune.pgf}}\end{subfigure}~"
echo "\begin{subfigure}[t]{0.33\textwidth}\resizebox{\textwidth}{!}{\import{heatmaps}{hm_skl_unroll_baseline.pgf}}\end{subfigure}"
echo "\caption{Heatmaps for Bhiveu for basic blocks with a measured throughput of less than 10 cycles/iteration on Skylake}"
echo "\end{figure}"
echo ""

createHeatmapLoop skl '14 15' 'heatmaps/hm_skl_loop_uiCA.pgf' 'uiCA'
createHeatmapLoop skl '14 9' 'heatmaps/hm_skl_loop_ith.pgf' 'Ithemal'
createHeatmapLoop skl '14 5' 'heatmaps/hm_skl_loop_iaca3.pgf' 'IACA 3.0'
createHeatmapLoop skl '14 6' 'heatmaps/hm_skl_loop_iaca23.pgf' 'IACA 2.3'
createHeatmapLoop skl '14 10' 'heatmaps/hm_skl_loop_osaca.pgf' 'OSACA'
createHeatmapLoop skl '14 7' 'heatmaps/hm_skl_loop_mca.pgf' 'llvm-mca-10'
createHeatmapLoop skl '14 12' 'heatmaps/hm_skl_loop_difftune.pgf' 'DiffTune'
createHeatmapLoop skl '14 13' 'heatmaps/hm_skl_loop_cqa.pgf' 'CQA'
createHeatmapLoop skl '14 -baselineLoop -issueWidth 4' 'heatmaps/hm_skl_loop_baseline.pgf' 'Baseline'

echo "\begin{figure}[H]"
echo "\centering"
echo "\begin{subfigure}[t]{0.33\textwidth}\resizebox{\textwidth}{!}{\import{heatmaps}{hm_skl_loop_uiCA.pgf}}\end{subfigure}~"
echo "\begin{subfigure}[t]{0.33\textwidth}\resizebox{\textwidth}{!}{\import{heatmaps}{hm_skl_loop_ith.pgf}}\end{subfigure}~"
echo "\begin{subfigure}[t]{0.33\textwidth}\resizebox{\textwidth}{!}{\import{heatmaps}{hm_skl_loop_iaca3.pgf}}\end{subfigure}\par\bigskip"
echo ""
echo "\begin{subfigure}[t]{0.33\textwidth}\resizebox{\textwidth}{!}{\import{heatmaps}{hm_skl_loop_iaca23.pgf}}\end{subfigure}~"
echo "\begin{subfigure}[t]{0.33\textwidth}\resizebox{\textwidth}{!}{\import{heatmaps}{hm_skl_loop_osaca.pgf}}\end{subfigure}~"
echo "\begin{subfigure}[t]{0.33\textwidth}\resizebox{\textwidth}{!}{\import{heatmaps}{hm_skl_loop_mca.pgf}}\end{subfigure}\par\bigskip"
echo ""
echo "\begin{subfigure}[t]{0.33\textwidth}\resizebox{\textwidth}{!}{\import{heatmaps}{hm_skl_loop_difftune.pgf}}\end{subfigure}~"
echo "\begin{subfigure}[t]{0.33\textwidth}\resizebox{\textwidth}{!}{\import{heatmaps}{hm_skl_loop_cqa.pgf}}\end{subfigure}~"
echo "\begin{subfigure}[t]{0.33\textwidth}\resizebox{\textwidth}{!}{\import{heatmaps}{hm_skl_loop_baseline.pgf}}\end{subfigure}"
echo "\caption{Heatmaps for Bhivel for basic blocks with a measured throughput of less than 10 cycles/iteration on Skylake}"
echo "\end{figure}"
echo ""

