#!/usr/bin/env python3

import math
import os
import sys
from itertools import count
from typing import List

sys.path.append(os.path.join(os.path.dirname(os.path.realpath(__file__)), '../uiCA'))
from uiCA import Instr, generateLatencyGraph, computeMaximumLatencyForGraph, computePortUsageLimit, computeIssueLimit
from microArchConfigs import MicroArchConfig


def getPredecLimit(hex, disas, loop=False):
   codeLength = len(hex) // 2
   unroll = 1 if loop else (16 // math.gcd(codeLength, 16))
   nB16Blocks = int(math.ceil((unroll * codeLength) / 16))
   L = [0 for _ in range(0, nB16Blocks)] # number of instr. instances whose last byte is in the given block
   O = [0 for _ in range(0, nB16Blocks)] # number of instr. instances whose nominal opcode starts in the given block but whose last byte is in the next block
   LCP = [0 for _ in range(0, nB16Blocks)] # number of instr. instances whose nominal opcode starts in the given block, and which have a length-changing prefix
   curAddr = 0
   for _ in range(0, unroll):
      for i in disas:
         instrLen = len(i['opcode']) // 2
         nextAddr = curAddr + instrLen
         endBlock = (nextAddr-1) // 16 # 16-Byte block in which the last Byte of the instruction is stored
         posNominalOpcode = i['pos_nominal_opcode']
         nominalOpcodeBlock = (curAddr + posNominalOpcode) // 16
         L[endBlock] += 1
         if nominalOpcodeBlock != endBlock:
            O[nominalOpcodeBlock] += 1
         if hasLCP(i):
            LCP[nominalOpcodeBlock] += 1
         curAddr = nextAddr

   cycles = 0
   for bi in range(0, nB16Blocks):
      cycles += math.ceil((L[bi]+O[bi])/5)
      cycles += max(0, 3 * LCP[bi] - (math.ceil((L[bi-1]+O[bi-1])/5) - 1))
   return cycles / unroll


def getPredecLimitSimple(hex, instructions):
   codeLength = len(hex) // 2
   return codeLength/16


def hasLCP(instrD):
   return (instrD['prefix66'] != '0') and (instrD.get('IMM_WIDTH', 0) == 16)


def getDecLimit(instructions, uArchConfig):
   instructions = [i for i in instructions if not i.macroFusedWithPrevInstr]
   firstInstrOnDecInRound = {}
   nAvailSimpleDec = 0
   curDec = uArchConfig.nDecoders - 1
   nComplexDecInRound = {}
   for round in count(0):
      nComplexDecInRound[round] = 0
      for ii, instr in enumerate(instructions):
         if instr.complexDecoder:
            curDec = 0
            nAvailSimpleDec = instr.nAvailableSimpleDecoders
         else:
            if ((nAvailSimpleDec == 0)
                  or (curDec+1 == uArchConfig.nDecoders-1 and instr.macroFusibleWith and (not uArchConfig.macroFusibleInstrCanBeDecodedAsLastInstr))):
               curDec = 0
               nAvailSimpleDec = uArchConfig.nDecoders - 1
            else:
               curDec += 1
               nAvailSimpleDec -= 1
         if instr.isBranchInstr or instr.macroFusedWithNextInstr:
            nAvailSimpleDec = 0

         if curDec == 0:
            nComplexDecInRound[round] += 1

         if ii == 0:
            if curDec in firstInstrOnDecInRound:
               firstRound = firstInstrOnDecInRound[curDec]
               return sum(nComplexDecInRound[r] for r in range(firstRound, round)) / (round - firstRound)
            else:
               firstInstrOnDecInRound[curDec] = round


def getDecLimitSimple(instructions):
   instructions = [i for i in instructions if not i.macroFusedWithPrevInstr]
   return max(len(instructions)/4, len([i for i in instructions if i.complexDecoder]))


def getLSDLimit(instructions, uArchConfig):
   nUops = sum(i.uopsMITE + i.uopsMS for i in instructions if not i.macroFusedWithPrevInstr)
   LSDUnrollCount = uArchConfig.LSDUnrolling.get(nUops, 1)
   return math.ceil((nUops * LSDUnrollCount) / uArchConfig.issueWidth) / LSDUnrollCount


def getDSBLimit(hex, disas, instructions, uArchConfig):
   nUops = sum(i.uopsMITE + i.uopsMS  for i in instructions if not i.macroFusedWithPrevInstr)
   codeLength = sum(len(i.opcode) // 2 for i in instructions[:-1])

   if codeLength <= 32:
      return math.ceil(nUops/6)
   else:
      return nUops/6


def getAnalyticalPredictionForUnrolling(instructions: List[Instr], hex, xedDisas, uArchConfig: MicroArchConfig, components: List[str]):
   TPs = []
   if 'predec' in components:
      TPs.append(('predec', getPredecLimit(hex, xedDisas)))
   if 'predecSimple' in components:
      TPs.append(('predec', getPredecLimitSimple(hex, instructions)))
   if 'dec' in components:
      TPs.append(('dec', getDecLimit(instructions, uArchConfig)))
   if 'decSimple' in components:
      TPs.append(('decSimple', getDecLimitSimple(instructions)))
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
      TPs.append(('dsb', getDSBLimit(hex, xedDisas, instructions, uArchConfig) if (uopSource == 'DSB') else 0))
   if 'lsd' in components:
      TPs.append(('lsd', getLSDLimit(instructions, uArchConfig) if (uopSource == 'LSD') else 0))
   if 'predec' in components:
      TPs.append(('predec', getPredecLimit(hex, xedDisas, loop=1) if (uopSource == 'MITE') else 0))
   if 'predecSimple' in components:
      TPs.append(('predec', getPredecLimitSimple(hex, instructions) if (uopSource == 'MITE') else 0))
   if 'dec' in components:
      TPs.append(('dec', getDecLimit(instructions, uArchConfig) if (uopSource == 'MITE') else 0))
   if 'decSimple' in components:
      TPs.append(('decSimple', getDecLimitSimple(instructions) if (uopSource == 'MITE') else 0))
   if 'issue' in components:
      TPs.append(('issue', computeIssueLimit(instructions, uArchConfig)))
   if 'lat' in components:
      nodesForInstr, edgesForNode = generateLatencyGraph(instructions, uArchConfig, 'stack')
      lat = computeMaximumLatencyForGraph(instructions, nodesForInstr, edgesForNode)[0]
      TPs.append(('lat', lat))
   if 'portUsage' in components:
      TPs.append(('portUsage', computePortUsageLimit(instructions)))

   return TPs
