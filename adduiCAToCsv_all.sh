#!/bin/bash

./adduiCAToCsv.sh snb/snb_m.csv SNB > snb/snb_uica.csv &
./adduiCAToCsvLoop.sh snb/snb_loop_m.csv SNB > snb/snb_loop_uica.csv &
./adduiCAToCsvLoop.sh snb/snb_loop5_m.csv SNB > snb/snb_loop5_uica.csv &

./adduiCAToCsv.sh ivb/ivb_m.csv IVB > ivb/ivb_uica.csv &
./adduiCAToCsvLoop.sh ivb/ivb_loop_m.csv IVB > ivb/ivb_loop_uica.csv &
./adduiCAToCsvLoop.sh ivb/ivb_loop5_m.csv IVB > ivb/ivb_loop5_uica.csv &

./adduiCAToCsv.sh hsw/hsw_m.csv HSW > hsw/hsw_uica.csv &
./adduiCAToCsvLoop.sh hsw/hsw_loop_m.csv HSW > hsw/hsw_loop_uica.csv &
./adduiCAToCsvLoop.sh hsw/hsw_loop5_m.csv HSW > hsw/hsw_loop5_uica.csv &

./adduiCAToCsv.sh bdw/bdw_m.csv BDW > bdw/bdw_uica.csv &
./adduiCAToCsvLoop.sh bdw/bdw_loop_m.csv BDW > bdw/bdw_loop_uica.csv &
./adduiCAToCsvLoop.sh bdw/bdw_loop5_m.csv BDW > bdw/bdw_loop5_uica.csv &

./adduiCAToCsv.sh skl/skl_m.csv SKL > skl/skl_uica.csv &
./adduiCAToCsvLoop.sh skl/skl_loop_m.csv SKL > skl/skl_loop_uica.csv &
./adduiCAToCsvLoop.sh skl/skl_loop5_m.csv SKL > skl/skl_loop5_uica.csv &

./adduiCAToCsv.sh clx/clx_m.csv CLX > clx/clx_uica.csv &
./adduiCAToCsvLoop.sh clx/clx_loop_m.csv CLX > clx/clx_loop_uica.csv &
./adduiCAToCsvLoop.sh clx/clx_loop5_m.csv CLX > clx/clx_loop5_uica.csv &

./adduiCAToCsv.sh icl/icl_m.csv ICL > icl/icl_uica.csv &
./adduiCAToCsvLoop.sh icl/icl_loop_m.csv ICL > icl/icl_loop_uica.csv &
./adduiCAToCsvLoop.sh icl/icl_loop5_m.csv ICL > icl/icl_loop5_uica.csv &

./adduiCAToCsv.sh tgl/tgl_m.csv TGL > tgl/tgl_uica.csv &
./adduiCAToCsvLoop.sh tgl/tgl_loop_m.csv TGL > tgl/tgl_loop_uica.csv &
./adduiCAToCsvLoop.sh tgl/tgl_loop5_m.csv TGL > tgl/tgl_loop5_uica.csv &

./adduiCAToCsv.sh rkl/rkl_m.csv RKL > rkl/rkl_uica.csv &
./adduiCAToCsvLoop.sh rkl/rkl_loop_m.csv RKL > rkl/rkl_loop_uica.csv &
./adduiCAToCsvLoop.sh rkl/rkl_loop5_m.csv RKL > rkl/rkl_loop5_uica.csv &


./adduiCAToCsv.sh clx/clx_m.csv CLX -simpleFrontEnd > clx/clx_uica_simpleFE.csv &
./adduiCAToCsvLoop.sh clx/clx_loop_m.csv CLX -simpleFrontEnd > clx/clx_loop_uica_simpleFE.csv &
./adduiCAToCsvLoop.sh clx/clx_loop5_m.csv CLX -simpleFrontEnd > clx/clx_loop5_uica_simpleFE.csv &

./adduiCAToCsv.sh clx/clx_m.csv CLX_SimplePorts > clx/clx_uica_simplePorts.csv &
./adduiCAToCsvLoop.sh clx/clx_loop_m.csv CLX_SimplePorts > clx/clx_loop_uica_simplePorts.csv &
./adduiCAToCsvLoop.sh clx/clx_loop5_m.csv CLX_SimplePorts > clx/clx_loop5_uica_simplePorts.csv &

./adduiCAToCsv.sh clx/clx_m.csv CLX -noMicroFusion > clx/clx_uica_noMicroFusion.csv &
./adduiCAToCsvLoop.sh clx/clx_loop_m.csv CLX -noMicroFusion > clx/clx_loop_uica_noMicroFusion.csv &
./adduiCAToCsvLoop.sh clx/clx_loop5_m.csv CLX -noMicroFusion > clx/clx_loop5_uica_noMicroFusion.csv &

./adduiCAToCsv.sh clx/clx_m.csv CLX -noMacroFusion > clx/clx_uica_noMacroFusion.csv &
./adduiCAToCsvLoop.sh clx/clx_loop_m.csv CLX -noMacroFusion > clx/clx_loop_uica_noMacroFusion.csv &
./adduiCAToCsvLoop.sh clx/clx_loop5_m.csv CLX -noMacroFusion > clx/clx_loop5_uica_noMacroFusion.csv &

./adduiCAToCsv.sh clx/clx_m.csv CLX_noLSDUnrolling > clx/clx_uica_noLSDUnrolling.csv &
./adduiCAToCsvLoop.sh clx/clx_loop_m.csv CLX_noLSDUnrolling > clx/clx_loop_uica_noLSDUnrolling.csv &
./adduiCAToCsvLoop.sh clx/clx_loop5_m.csv CLX_noLSDUnrolling > clx/clx_loop5_uica_noLSDUnrolling.csv &

./adduiCAToCsv.sh clx/clx_m_moveElimCandidates.csv CLX > clx/clx_uica_moveElim.csv &
./adduiCAToCsvLoop.sh clx/clx_loop_m_moveElimCandidates.csv CLX > clx/clx_loop_uica_moveElim.csv &
./adduiCAToCsvLoop.sh clx/clx_loop5_m_moveElimCandidates.csv CLX > clx/clx_loop5_uica_moveElim.csv &

./adduiCAToCsv.sh clx/clx_m_moveElimCandidates.csv CLX_noMoveElim > clx/clx_uica_noMoveElim.csv &
./adduiCAToCsvLoop.sh clx/clx_loop_m_moveElimCandidates.csv CLX_noMoveElim > clx/clx_loop_uica_noMoveElim.csv &
./adduiCAToCsvLoop.sh clx/clx_loop5_m_moveElimCandidates.csv CLX_noMoveElim > clx/clx_loop5_uica_noMoveElim.csv &

./adduiCAToCsv.sh clx/clx_m_moveElimCandidates.csv CLX_fullMoveElim > clx/clx_uica_fullMoveElim.csv &
./adduiCAToCsvLoop.sh clx/clx_loop_m_moveElimCandidates.csv CLX_fullMoveElim > clx/clx_loop_uica_fullMoveElim.csv &
./adduiCAToCsvLoop.sh clx/clx_loop5_m_moveElimCandidates.csv CLX_fullMoveElim > clx/clx_loop5_uica_fullMoveElim.csv &

./adduiCAToCsv.sh clx/clx_m.csv CLX_SimplePorts_noMoveElim -simpleFrontEnd -noMicroFusion -noMacroFusion > clx/clx_uica_maxSimplified.csv &
./adduiCAToCsvLoop.sh clx/clx_loop_m.csv CLX_SimplePorts_noMoveElim -simpleFrontEnd -noMicroFusion -noMacroFusion > clx/clx_loop_uica_maxSimplified.csv &
./adduiCAToCsvLoop.sh clx/clx_loop5_m.csv CLX_SimplePorts_noMoveElim -simpleFrontEnd -noMicroFusion -noMacroFusion > clx/clx_loop5_uica_maxSimplified.csv &

wait
