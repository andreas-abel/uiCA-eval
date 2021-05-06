#!/usr/bin/env python3

import argparse
import binascii
import math
import os
import subprocess
import sys

sys.path.append(os.path.join(os.path.dirname(__file__), '../../XED-to-XML'))
from disas import *

sys.path.append(os.path.join(os.path.dirname(__file__), '../../uiCA'))
from x64_lib import *

def getAssemblerCode(filename):
   output = subprocess.check_output(['objdump', '-b', 'binary', '-Mintel,x86-64', '-m', 'i386', '--no-show-raw-insn', '-D', filename]).decode()
   lines = output.split('\n')[7:-1]
   lines = [line.split('\t')[1] for line in lines]
   lines = [' '.join(line.split()) for line in lines]
   return '; '.join(lines)


def assemble(assemblerCode, filename):
   with open('code.s', 'w') as f:
      f.write(assemblerCode)
   subprocess.check_call(['as', 'code.s', '-o', filename])
   subprocess.check_call(['objcopy', filename, '-O', 'binary', filename])
   

def main():
   parser = argparse.ArgumentParser(description='Add loop')   
   parser.add_argument('csv', help="csv file")
   parser.add_argument('rep', type=int, help="If a benchmark has fewer than 'rep' instructions, it will unrolled until it contains at least 'rep' instructions")
   args = parser.parse_args()

   allLoopRegs = set(regTo64(reg) for reg in GPRegs) - {'RSP'}
   
   with open(args.csv, 'r') as f:
      lines = f.read().splitlines()   

   print('hexCode,hexCodeDec,hexCodeJmp,asm,loopReg')
   for line in lines[1:]:
      hexCode = line.split(',')[0]
      if not hexCode: continue
      with open('code', 'wb') as f:
         f.write(binascii.unhexlify(hexCode))
      xedBinary = os.path.join(os.path.dirname(__file__), '..', '..', 'XED-to-XML', 'obj', 'wkit', 'bin', 'xed')
      output = subprocess.check_output([xedBinary, '-64', '-v', '4', '-ir', 'code']).decode()
      disas = parseXedOutput(output)
      regs = set(getCanonicalReg(reg) for instr in disas for reg in instr.regOperands.values())
      memAddrs = [getMemAddr(memOp) for instr in disas for memOp in instr.memOperands.values()]
      regs |= set(getCanonicalReg(reg) for memAddr in memAddrs for reg in [memAddr.base, memAddr.index] if reg is not None)
      unusedRegs = allLoopRegs - regs
      
      if len(unusedRegs) >= 1:
         if len(disas) >= args.rep:
            continue
         unroll = int(math.ceil(args.rep/len(disas)))
         
         reg = sorted(unusedRegs)[0]
         hexCode = hexCode * unroll

         assemblerCode = '.intel_syntax noprefix\n' \
                         'l:\n' \
                         '.byte ' + ', '.join('0x'+hexCode[i]+hexCode[i+1] for i in range(0,len(hexCode),2)) + '\n' \
                         'dec ' + reg + '\n'
         assemble(assemblerCode, 'code.o')
         with open('code.o', 'rb') as f:
            hexCodeDec = binascii.hexlify(f.read()).decode()

         assemblerCodeJmp = assemblerCode + 'jnz l\n'
         assemble(assemblerCodeJmp, 'codeJ.o')
         with open('codeJ.o', 'rb') as f:
            hexCodeJmp = binascii.hexlify(f.read()).decode()
         
         asmCode = '"' + getAssemblerCode('codeJ.o') + '"'

         print(','.join([hexCode, hexCodeDec[len(hexCode):], hexCodeJmp[len(hexCodeDec):], asmCode, reg]))
         
         

if __name__ == "__main__":
    main()
