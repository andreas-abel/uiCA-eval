#!/usr/bin/python

import argparse
import os
import subprocess
import sys

sys.path.append('../XED-to-XML')
from disas import *

sys.path.append('../uiCA')
from x64_lib import *

def hasX87StackUnderOrOverflow(disas):
   stacksize = 0
   for instr in disas:
      for r in [r for n, r in instr.regOperands.items() if ('R' in instr.rw[n]) and ('ST(' in r)]:
         i = int(r[3])
         if stacksize - i <= 0:
            return True
      pop = instr.regOperands.values().count('X87POP')
      push = instr.regOperands.values().count('X87PUSH')
      stacksize = stacksize - pop + push
   return stacksize != 0

def main():
   parser = argparse.ArgumentParser(description='Filter')
   parser.add_argument('csv', help="csv file")
   parser.add_argument("-exclMemRW", help="exclude blocks that both read and write from/to memory", action='store_true')
   parser.add_argument("-exclMemRWDiffAddr", help="exclude blocks that write to memory, and read from a potentially different address", action='store_true')
   parser.add_argument("-exclNoMemRWDiffAddr", help="exclude blocks that do not write to memory, and read from a potentially different address", action='store_true')
   parser.add_argument("-exclMemWDiffAddr", help="exclude blocks that have writes to potentially different address", action='store_true')
   parser.add_argument("-exclNoMemRW", help="exclude blocks that do not both read and write from/to memory", action='store_true')
   parser.add_argument("-exclMem", help="exclude blocks that read or write from/to memory", action='store_true')
   parser.add_argument("-exclVarTP", help="exclude blocks with instructions with input-dependent TP", action='store_true')
   parser.add_argument("-exclNoVarTP", help="exclude blocks with no instructions with input-dependent TP", action='store_true')
   args = parser.parse_args()

   with open(args.csv, 'r') as f:
      lines = f.read().splitlines()

   xedBinary = os.path.join(os.path.dirname(__file__), '..', 'XED-to-XML', 'obj', 'wkit', 'bin', 'xed')

   print lines[0]
   for line in lines[1:]:
      code = line.split(',')[0]
      with open('code.hex', 'w') as f:
         f.write(code)
      output = subprocess.check_output([xedBinary, '-64', '-v', '4', '-ih', 'code.hex'])
      disas = parseXedOutput(output)

      if hasX87StackUnderOrOverflow(disas):
         #sys.stderr.write(line + '\n')
         continue

      memR = [m for instr in disas for n, m in instr.memOperands.items() if ('MEM' in n) and ('R' in instr.rw[n])]
      memW = [m for instr in disas for n, m in instr.memOperands.items() if ('MEM' in n) and ('W' in instr.rw[n])]
      allMem = memR + memW
      hasMem = len(allMem) > 0
      hasMemRW = (len(memR) > 0) and (len(memW) > 0)
      hasMemW = len(memW) > 0
      hasVarTPInstr = any(('div' in instr.asm or 'sqrt' in instr.asm or 'cpuid' in instr.asm) for instr in disas)
      modifiedRegs = {getCanonicalReg(r) for instr in disas for n, r in instr.regOperands.items() if 'W' in instr.rw[n]}

      if args.exclMem and hasMem:
         continue
      if args.exclMemRW and hasMemRW:
         continue

      hasMemRWDiffAddr = False
      if hasMemRW:
         if any((r in m) for m in allMem for r in modifiedRegs):
            hasMemRWDiffAddr = True
         firstAddr = allMem[0]
         if any(m != firstAddr for m in allMem):
            hasMemRWDiffAddr = True

      if args.exclMemRWDiffAddr and hasMemRWDiffAddr:
         continue
      if args.exclNoMemRWDiffAddr and (not hasMemRWDiffAddr):
         continue

      if args.exclMemWDiffAddr and hasMemW:
         if any((r in m) for m in memW for r in modifiedRegs):
            continue
         firstAddr = memW[0]
         if any(m != firstAddr for m in memW):
            continue
      if args.exclNoMemRW and (not hasMemRW):
         continue
      if args.exclVarTP and hasVarTPInstr:
         continue
      if args.exclNoVarTP and (not hasVarTPInstr):
         continue

      print line


if __name__ == "__main__":
    main()
