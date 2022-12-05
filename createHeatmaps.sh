#!/bin/bash

createHeatmap() {
   ./avgError.py "$1/$1""_uica""$5"".csv" $2 -heatmap "$3" "$4"
}
export -f createHeatmap

createHeatmapLoop() {
   tmpFile=`mktemp --tmpdir tmp.XXXXXXXXXX`
   trap "rm $tmpFile" EXIT
   cp "$1/$1""_loop_uica""$5"".csv" $tmpFile
   tail -n +2  "$1/$1""_loop5_uica""$5"".csv" >> $tmpFile
   ./avgError.py $tmpFile $2 -heatmap "$3" "$4"
}
export -f createHeatmapLoop

arg1=$1
export arg1

rm -rf heatmaps/
mkdir heatmaps

parallel --keep-order << "EOM"
# ICL

createHeatmap icl '4 5' 'heatmaps/hm_icl_unroll_uiCA.pgf' 'uiCA'
createHeatmap icl '4 3' 'heatmaps/hm_icl_unroll_osaca.pgf' 'OSACA'
createHeatmap icl '4 2' 'heatmaps/hm_icl_unroll_mca.pgf' 'llvm-mca-10'
createHeatmap icl '4 -baselineUnroll -memWritePorts 2' 'heatmaps/hm_icl_unroll_baseline.pgf' 'Baseline'
[[ "$arg1" == "analytical" ]] && createHeatmap icl '4 -analyticalUnroll -arch ICL' 'heatmaps/hm_icl_unroll_analytical.pgf' 'Analytical'

echo "\section{Heatmaps for Ice Lake}"
echo "\vfill"
echo "\begin{figure}[H]"
echo "\centering"
echo "\begin{subfigure}[t]{0.33\textwidth}\resizebox{\textwidth}{!}{\import{heatmaps}{hm_icl_unroll_uiCA.pgf}}\end{subfigure}~"
echo "\begin{subfigure}[t]{0.33\textwidth}\resizebox{\textwidth}{!}{\import{heatmaps}{hm_icl_unroll_osaca.pgf}}\end{subfigure}~"
echo "\begin{subfigure}[t]{0.33\textwidth}\resizebox{\textwidth}{!}{\import{heatmaps}{hm_icl_unroll_mca.pgf}}\end{subfigure}\par\bigskip"
echo ""
echo "\begin{subfigure}[t]{0.33\textwidth}\resizebox{\textwidth}{!}{\import{heatmaps}{hm_icl_unroll_baseline.pgf}}\end{subfigure}"
[[ "$arg1" == "analytical" ]] && echo "~\begin{subfigure}[t]{0.33\textwidth}\resizebox{\textwidth}{!}{\import{heatmaps}{hm_icl_unroll_analytical.pgf}}\end{subfigure}"
echo "\caption{Heatmaps for \bhiveu for basic blocks with a measured throughput of less than 10 cycles/iteration on Ice Lake}"
echo "\end{figure}"
echo "\vfill"
echo ""

createHeatmapLoop icl '8 9' 'heatmaps/hm_icl_loop_uiCA.pgf' 'uiCA'
createHeatmapLoop icl '8 6' 'heatmaps/hm_icl_loop_osaca.pgf' 'OSACA'
createHeatmapLoop icl '8 5' 'heatmaps/hm_icl_loop_mca.pgf' 'llvm-mca-10'
createHeatmapLoop icl '8 7' 'heatmaps/hm_icl_loop_cqa.pgf' 'CQA'
createHeatmapLoop icl '8 -baselineLoop -issueWidth 5 -memWritePorts 2' 'heatmaps/hm_icl_loop_baseline.pgf' 'Baseline'
[[ "$arg1" == "analytical" ]] && createHeatmapLoop icl '8 -analyticalLoop -arch ICL' 'heatmaps/hm_icl_loop_analytical.pgf' 'Analytical'

echo "\newpage"
#echo "\mbox{}"
echo "\vfill"
echo "\begin{figure}[H]"
echo "\centering"
echo "\begin{subfigure}[t]{0.33\textwidth}\resizebox{\textwidth}{!}{\import{heatmaps}{hm_icl_loop_uiCA.pgf}}\end{subfigure}~"
echo "\begin{subfigure}[t]{0.33\textwidth}\resizebox{\textwidth}{!}{\import{heatmaps}{hm_icl_loop_osaca.pgf}}\end{subfigure}~"
echo "\begin{subfigure}[t]{0.33\textwidth}\resizebox{\textwidth}{!}{\import{heatmaps}{hm_icl_loop_mca.pgf}}\end{subfigure}\par\bigskip"
echo ""
echo "\begin{subfigure}[t]{0.33\textwidth}\resizebox{\textwidth}{!}{\import{heatmaps}{hm_icl_loop_cqa.pgf}}\end{subfigure}~"
echo "\begin{subfigure}[t]{0.33\textwidth}\resizebox{\textwidth}{!}{\import{heatmaps}{hm_icl_loop_baseline.pgf}}\end{subfigure}"
[[ "$arg1" == "analytical" ]] && echo "~\begin{subfigure}[t]{0.33\textwidth}\resizebox{\textwidth}{!}{\import{heatmaps}{hm_icl_loop_analytical.pgf}}\end{subfigure}"
echo "\caption{Heatmaps for \bhivel for basic blocks with a measured throughput of less than 10 cycles/iteration on Ice Lake}"
echo "\end{figure}"
echo "\vfill"
echo ""

# SKL

createHeatmap skl '11 12' 'heatmaps/hm_skl_unroll_uiCA.pgf' 'uiCA'
createHeatmap skl '11 7' 'heatmaps/hm_skl_unroll_ith.pgf' 'Ithemal'
createHeatmap skl '11 3' 'heatmaps/hm_skl_unroll_iaca3.pgf' 'IACA 3.0'
createHeatmap skl '11 4' 'heatmaps/hm_skl_unroll_iaca23.pgf' 'IACA 2.3'
createHeatmap skl '11 8' 'heatmaps/hm_skl_unroll_osaca.pgf' 'OSACA'
createHeatmap skl '11 5' 'heatmaps/hm_skl_unroll_mca.pgf' 'llvm-mca-10'
createHeatmap skl '11 10' 'heatmaps/hm_skl_unroll_difftune.pgf' 'DiffTune'
createHeatmap skl '11 -baselineUnroll' 'heatmaps/hm_skl_unroll_baseline.pgf' 'Baseline'
[[ "$arg1" == "analytical" ]] && createHeatmap skl '11 -analyticalUnroll -arch SKL' 'heatmaps/hm_skl_unroll_analytical.pgf' 'Analytical'

echo "\section{Heatmaps for Skylake}"
echo "\vfill"
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
[[ "$arg1" == "analytical" ]] && echo "~\begin{subfigure}[t]{0.33\textwidth}\resizebox{\textwidth}{!}{\import{heatmaps}{hm_skl_unroll_analytical.pgf}}\end{subfigure}"
echo "\caption{Heatmaps for \bhiveu for basic blocks with a measured throughput of less than 10 cycles/iteration on Skylake}"
echo "\end{figure}"
echo "\vfill"
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
[[ "$arg1" == "analytical" ]] && createHeatmapLoop skl '14 -analyticalLoop -arch SKL' 'heatmaps/hm_skl_loop_analytical.pgf' 'Analytical'

echo "\newpage"
#echo "\mbox{}"
echo "\vfill"
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
[[ "$arg1" == "analytical" ]] && echo "\par\bigskip\begin{subfigure}[t]{0.33\textwidth}\resizebox{\textwidth}{!}{\import{heatmaps}{hm_skl_loop_analytical.pgf}}\end{subfigure}"
echo "\caption{Heatmaps for \bhivel for basic blocks with a measured throughput of less than 10 cycles/iteration on Skylake}"
echo "\end{figure}"
echo "\vfill"
echo ""



# HSW

createHeatmap hsw '11 12' 'heatmaps/hm_hsw_unroll_uiCA.pgf' 'uiCA'
createHeatmap hsw '11 7' 'heatmaps/hm_hsw_unroll_ith.pgf' 'Ithemal'
createHeatmap hsw '11 3' 'heatmaps/hm_hsw_unroll_iaca3.pgf' 'IACA 3.0'
createHeatmap hsw '11 4' 'heatmaps/hm_hsw_unroll_iaca23.pgf' 'IACA 2.3'
createHeatmap hsw '11 8' 'heatmaps/hm_hsw_unroll_osaca.pgf' 'OSACA'
createHeatmap hsw '11 5' 'heatmaps/hm_hsw_unroll_mca.pgf' 'llvm-mca-10'
createHeatmap hsw '11 10' 'heatmaps/hm_hsw_unroll_difftune.pgf' 'DiffTune'
createHeatmap hsw '11 -baselineUnroll' 'heatmaps/hm_hsw_unroll_baseline.pgf' 'Baseline'
[[ "$arg1" == "analytical" ]] && createHeatmap hsw '11 -analyticalUnroll -arch HSW' 'heatmaps/hm_hsw_unroll_analytical.pgf' 'Analytical'

echo "\newpage"
echo "\section{Heatmaps for Haswell}"
echo "\vfill"
echo "\begin{figure}[H]"
echo "\centering"
echo "\begin{subfigure}[t]{0.33\textwidth}\resizebox{\textwidth}{!}{\import{heatmaps}{hm_hsw_unroll_uiCA.pgf}}\end{subfigure}~"
echo "\begin{subfigure}[t]{0.33\textwidth}\resizebox{\textwidth}{!}{\import{heatmaps}{hm_hsw_unroll_ith.pgf}}\end{subfigure}~"
echo "\begin{subfigure}[t]{0.33\textwidth}\resizebox{\textwidth}{!}{\import{heatmaps}{hm_hsw_unroll_iaca3.pgf}}\end{subfigure}\par\bigskip"
echo ""
echo "\begin{subfigure}[t]{0.33\textwidth}\resizebox{\textwidth}{!}{\import{heatmaps}{hm_hsw_unroll_iaca23.pgf}}\end{subfigure}~"
echo "\begin{subfigure}[t]{0.33\textwidth}\resizebox{\textwidth}{!}{\import{heatmaps}{hm_hsw_unroll_osaca.pgf}}\end{subfigure}~"
echo "\begin{subfigure}[t]{0.33\textwidth}\resizebox{\textwidth}{!}{\import{heatmaps}{hm_hsw_unroll_mca.pgf}}\end{subfigure}\par\bigskip"
echo ""
echo "\begin{subfigure}[t]{0.33\textwidth}\resizebox{\textwidth}{!}{\import{heatmaps}{hm_hsw_unroll_difftune.pgf}}\end{subfigure}~"
echo "\begin{subfigure}[t]{0.33\textwidth}\resizebox{\textwidth}{!}{\import{heatmaps}{hm_hsw_unroll_baseline.pgf}}\end{subfigure}"
[[ "$arg1" == "analytical" ]] && echo "~\begin{subfigure}[t]{0.33\textwidth}\resizebox{\textwidth}{!}{\import{heatmaps}{hm_hsw_unroll_analytical.pgf}}\end{subfigure}"
echo "\caption{Heatmaps for \bhiveu for basic blocks with a measured throughput of less than 10 cycles/iteration on Haswell}"
echo "\end{figure}"
echo "\vfill"
echo ""

createHeatmapLoop hsw '14 15' 'heatmaps/hm_hsw_loop_uiCA.pgf' 'uiCA'
createHeatmapLoop hsw '14 9' 'heatmaps/hm_hsw_loop_ith.pgf' 'Ithemal'
createHeatmapLoop hsw '14 5' 'heatmaps/hm_hsw_loop_iaca3.pgf' 'IACA 3.0'
createHeatmapLoop hsw '14 6' 'heatmaps/hm_hsw_loop_iaca23.pgf' 'IACA 2.3'
createHeatmapLoop hsw '14 10' 'heatmaps/hm_hsw_loop_osaca.pgf' 'OSACA'
createHeatmapLoop hsw '14 7' 'heatmaps/hm_hsw_loop_mca.pgf' 'llvm-mca-10'
createHeatmapLoop hsw '14 12' 'heatmaps/hm_hsw_loop_difftune.pgf' 'DiffTune'
createHeatmapLoop hsw '14 13' 'heatmaps/hm_hsw_loop_cqa.pgf' 'CQA'
createHeatmapLoop hsw '14 -baselineLoop -issueWidth 4' 'heatmaps/hm_hsw_loop_baseline.pgf' 'Baseline'
[[ "$arg1" == "analytical" ]] && createHeatmapLoop hsw '14 -analyticalLoop -arch HSW' 'heatmaps/hm_hsw_loop_analytical.pgf' 'Analytical'

echo "\newpage"
#echo "\mbox{}"
echo "\vfill"
echo "\begin{figure}[H]"
echo "\centering"
echo "\begin{subfigure}[t]{0.33\textwidth}\resizebox{\textwidth}{!}{\import{heatmaps}{hm_hsw_loop_uiCA.pgf}}\end{subfigure}~"
echo "\begin{subfigure}[t]{0.33\textwidth}\resizebox{\textwidth}{!}{\import{heatmaps}{hm_hsw_loop_ith.pgf}}\end{subfigure}~"
echo "\begin{subfigure}[t]{0.33\textwidth}\resizebox{\textwidth}{!}{\import{heatmaps}{hm_hsw_loop_iaca3.pgf}}\end{subfigure}\par\bigskip"
echo ""
echo "\begin{subfigure}[t]{0.33\textwidth}\resizebox{\textwidth}{!}{\import{heatmaps}{hm_hsw_loop_iaca23.pgf}}\end{subfigure}~"
echo "\begin{subfigure}[t]{0.33\textwidth}\resizebox{\textwidth}{!}{\import{heatmaps}{hm_hsw_loop_osaca.pgf}}\end{subfigure}~"
echo "\begin{subfigure}[t]{0.33\textwidth}\resizebox{\textwidth}{!}{\import{heatmaps}{hm_hsw_loop_mca.pgf}}\end{subfigure}\par\bigskip"
echo ""
echo "\begin{subfigure}[t]{0.33\textwidth}\resizebox{\textwidth}{!}{\import{heatmaps}{hm_hsw_loop_difftune.pgf}}\end{subfigure}~"
echo "\begin{subfigure}[t]{0.33\textwidth}\resizebox{\textwidth}{!}{\import{heatmaps}{hm_hsw_loop_cqa.pgf}}\end{subfigure}~"
echo "\begin{subfigure}[t]{0.33\textwidth}\resizebox{\textwidth}{!}{\import{heatmaps}{hm_hsw_loop_baseline.pgf}}\end{subfigure}"
[[ "$arg1" == "analytical" ]] && echo "\par\bigskip\begin{subfigure}[t]{0.33\textwidth}\resizebox{\textwidth}{!}{\import{heatmaps}{hm_hsw_loop_analytical.pgf}}\end{subfigure}"
echo "\caption{Heatmaps for \bhivel for basic blocks with a measured throughput of less than 10 cycles/iteration on Haswell}"
echo "\end{figure}"
echo "\vfill"
echo ""


# IVB

createHeatmap ivb '10 11' 'heatmaps/hm_ivb_unroll_uiCA.pgf' 'uiCA'
createHeatmap ivb '10 6' 'heatmaps/hm_ivb_unroll_ith.pgf' 'Ithemal'
createHeatmap ivb '10 3' 'heatmaps/hm_ivb_unroll_iaca23.pgf' 'IACA 2.3'
createHeatmap ivb '10 7' 'heatmaps/hm_ivb_unroll_osaca.pgf' 'OSACA'
createHeatmap ivb '10 4' 'heatmaps/hm_ivb_unroll_mca.pgf' 'llvm-mca-10'
createHeatmap ivb '10 9' 'heatmaps/hm_ivb_unroll_difftune.pgf' 'DiffTune'
createHeatmap ivb '10 -baselineUnroll' 'heatmaps/hm_ivb_unroll_baseline.pgf' 'Baseline'
[[ "$arg1" == "analytical" ]] && createHeatmap ivb '10 -analyticalUnroll -arch IVB' 'heatmaps/hm_ivb_unroll_analytical.pgf' 'Analytical'

echo "\newpage"
echo "\section{Heatmaps for Ivy Bridge}"
echo "\vfill"
echo "\begin{figure}[H]"
echo "\centering"
echo "\begin{subfigure}[t]{0.33\textwidth}\resizebox{\textwidth}{!}{\import{heatmaps}{hm_ivb_unroll_uiCA.pgf}}\end{subfigure}~"
echo "\begin{subfigure}[t]{0.33\textwidth}\resizebox{\textwidth}{!}{\import{heatmaps}{hm_ivb_unroll_ith.pgf}}\end{subfigure}~"
echo "\begin{subfigure}[t]{0.33\textwidth}\resizebox{\textwidth}{!}{\import{heatmaps}{hm_ivb_unroll_iaca23.pgf}}\end{subfigure}\par\bigskip"
echo ""
echo "\begin{subfigure}[t]{0.33\textwidth}\resizebox{\textwidth}{!}{\import{heatmaps}{hm_ivb_unroll_osaca.pgf}}\end{subfigure}~"
echo "\begin{subfigure}[t]{0.33\textwidth}\resizebox{\textwidth}{!}{\import{heatmaps}{hm_ivb_unroll_mca.pgf}}\end{subfigure}~"
echo "\begin{subfigure}[t]{0.33\textwidth}\resizebox{\textwidth}{!}{\import{heatmaps}{hm_ivb_unroll_difftune.pgf}}\end{subfigure}\par\bigskip"
echo ""
echo "\begin{subfigure}[t]{0.33\textwidth}\resizebox{\textwidth}{!}{\import{heatmaps}{hm_ivb_unroll_baseline.pgf}}\end{subfigure}"
[[ "$arg1" == "analytical" ]] && echo "~\begin{subfigure}[t]{0.33\textwidth}\resizebox{\textwidth}{!}{\import{heatmaps}{hm_ivb_unroll_analytical.pgf}}\end{subfigure}"
echo "\caption{Heatmaps for \bhiveu for basic blocks with a measured throughput of less than 10 cycles/iteration on Ivy Bridge}"
echo "\end{figure}"
echo "\vfill"
echo ""

createHeatmapLoop ivb '13 14' 'heatmaps/hm_ivb_loop_uiCA.pgf' 'uiCA'
createHeatmapLoop ivb '13 8' 'heatmaps/hm_ivb_loop_ith.pgf' 'Ithemal'
createHeatmapLoop ivb '13 5' 'heatmaps/hm_ivb_loop_iaca23.pgf' 'IACA 2.3'
createHeatmapLoop ivb '13 9' 'heatmaps/hm_ivb_loop_osaca.pgf' 'OSACA'
createHeatmapLoop ivb '13 6' 'heatmaps/hm_ivb_loop_mca.pgf' 'llvm-mca-10'
createHeatmapLoop ivb '13 11' 'heatmaps/hm_ivb_loop_difftune.pgf' 'DiffTune'
createHeatmapLoop ivb '13 12' 'heatmaps/hm_ivb_loop_cqa.pgf' 'CQA'
createHeatmapLoop ivb '13 -baselineLoop -issueWidth 4' 'heatmaps/hm_ivb_loop_baseline.pgf' 'Baseline'
[[ "$arg1" == "analytical" ]] && createHeatmapLoop ivb '13 -analyticalLoop -arch IVB' 'heatmaps/hm_ivb_loop_analytical.pgf' 'Analytical'

echo "\newpage"
#echo "\mbox{}"
echo "\vfill"
echo "\begin{figure}[H]"
echo "\centering"
echo "\begin{subfigure}[t]{0.33\textwidth}\resizebox{\textwidth}{!}{\import{heatmaps}{hm_ivb_loop_uiCA.pgf}}\end{subfigure}~"
echo "\begin{subfigure}[t]{0.33\textwidth}\resizebox{\textwidth}{!}{\import{heatmaps}{hm_ivb_loop_ith.pgf}}\end{subfigure}~"
echo "\begin{subfigure}[t]{0.33\textwidth}\resizebox{\textwidth}{!}{\import{heatmaps}{hm_ivb_loop_iaca23.pgf}}\end{subfigure}\par\bigskip"
echo ""
echo "\begin{subfigure}[t]{0.33\textwidth}\resizebox{\textwidth}{!}{\import{heatmaps}{hm_ivb_loop_osaca.pgf}}\end{subfigure}~"
echo "\begin{subfigure}[t]{0.33\textwidth}\resizebox{\textwidth}{!}{\import{heatmaps}{hm_ivb_loop_mca.pgf}}\end{subfigure}~"
echo "\begin{subfigure}[t]{0.33\textwidth}\resizebox{\textwidth}{!}{\import{heatmaps}{hm_ivb_loop_difftune.pgf}}\end{subfigure}\par\bigskip"
echo ""
echo "\begin{subfigure}[t]{0.33\textwidth}\resizebox{\textwidth}{!}{\import{heatmaps}{hm_ivb_loop_cqa.pgf}}\end{subfigure}~"
echo "\begin{subfigure}[t]{0.33\textwidth}\resizebox{\textwidth}{!}{\import{heatmaps}{hm_ivb_loop_baseline.pgf}}\end{subfigure}"
[[ "$arg1" == "analytical" ]] && echo "~\begin{subfigure}[t]{0.33\textwidth}\resizebox{\textwidth}{!}{\import{heatmaps}{hm_ivb_loop_analytical.pgf}}\end{subfigure}"
echo "\caption{Heatmaps for \bhivel for basic blocks with a measured throughput of less than 10 cycles/iteration on Ivy Bridge}"
echo "\end{figure}"
echo "\vfill"
echo ""
EOM
