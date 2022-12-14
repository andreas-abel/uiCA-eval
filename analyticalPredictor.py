#!/usr/bin/env python3

import os
import sys
from typing import List

sys.path.append(os.path.join(os.path.dirname(os.path.realpath(__file__)), '../uiCA'))
from uiCA import Instr, generateLatencyGraph, computeMaximumLatencyForGraph, computePortUsageLimit, computeIssueLimit, computeLSDLimit, computeDSBLimit, computeDecLimit, computePredecLimit
from microArchConfigs import MicroArchConfig


def computePredecLimitSimple(hex, instructions):
   codeLength = len(hex) // 2
   return codeLength/16


def computeDecLimitSimple(instructions):
   instructions = [i for i in instructions if not i.macroFusedWithPrevInstr]
   return max(len(instructions)/4, len([i for i in instructions if i.complexDecoder]))


def getAnalyticalPredictionForUnrolling(instructions: List[Instr], hex, xedDisas, uArchConfig: MicroArchConfig, components: List[str]):
   TPs = []
   if 'predec' in components:
      TPs.append(('predec', computePredecLimit(xedDisas)))
   if 'predecSimple' in components:
      TPs.append(('predec', computePredecLimitSimple(hex, instructions)))
   if 'dec' in components:
      TPs.append(('dec', computeDecLimit(instructions, uArchConfig)))
   if 'decSimple' in components:
      TPs.append(('decSimple', computeDecLimitSimple(instructions)))
   if 'issue' in components:
      TPs.append(('issue', computeIssueLimit(instructions, uArchConfig)))
   if 'portUsage' in components:
      TPs.append(('portUsage', computePortUsageLimit(instructions)))
   if 'lat' in components:
      nodesForInstr, edgesForNode = generateLatencyGraph(instructions, uArchConfig, 'stack')
      lat = computeMaximumLatencyForGraph(instructions, nodesForInstr, edgesForNode)[0]
      TPs.append(('lat', lat))

   return TPs


def getAnalyticalPredictionForLoop(instructions: List[Instr], hex, xedDisas, uArchConfig: MicroArchConfig, components: List[str]):
   nonMacroFusedInstructions = [instr for instr in instructions if not instr.macroFusedWithPrevInstr]
   if nonMacroFusedInstructions[-1].cannotBeInDSBDueToJCCErratum:
      uopSource = 'MITE'
   elif uArchConfig.LSDEnabled and sum(instr.uopsMITE for instr in nonMacroFusedInstructions) <= uArchConfig.IDQWidth:
      uopSource = 'LSD'
   else:
      uopSource = 'DSB'

   TPs = []
   if 'dsb' in components:
      TPs.append(('dsb', computeDSBLimit(instructions) if (uopSource == 'DSB') else 0))
   if 'lsd' in components:
      TPs.append(('lsd', computeLSDLimit(instructions, uArchConfig) if (uopSource == 'LSD') else 0))
   if 'predec' in components:
      TPs.append(('predec', computePredecLimit(xedDisas, loop=1) if (uopSource == 'MITE') else 0))
   if 'predecSimple' in components:
      TPs.append(('predec', computePredecLimitSimple(hex, instructions) if (uopSource == 'MITE') else 0))
   if 'dec' in components:
      TPs.append(('dec', computeDecLimit(instructions, uArchConfig) if (uopSource == 'MITE') else 0))
   if 'decSimple' in components:
      TPs.append(('decSimple', computeDecLimitSimple(instructions) if (uopSource == 'MITE') else 0))
   if 'issue' in components:
      TPs.append(('issue', computeIssueLimit(instructions, uArchConfig)))
   if 'lat' in components:
      nodesForInstr, edgesForNode = generateLatencyGraph(instructions, uArchConfig, 'stack')
      lat = computeMaximumLatencyForGraph(instructions, nodesForInstr, edgesForNode)[0]
      TPs.append(('lat', lat))
   if 'portUsage' in components:
      TPs.append(('portUsage', computePortUsageLimit(instructions)))

   return TPs
