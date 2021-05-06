#!/usr/bin/python

import argparse
import csv
import os
import subprocess
import sys

sys.path.append('../../XED-to-XML')
from disas import *

sys.path.append('../../uiCA')
from x64_lib import *

def main():
   parser = argparse.ArgumentParser(description='Counts benchmarks that access memory but have a throughput < 0.5')
   parser.add_argument('csv', help="csv file")
   parser.add_argument("col", help="Column index", type=int)
   args = parser.parse_args()
   
   with open(args.csv, 'r') as f:
      lines = f.read().splitlines()
   
   xedBinary = os.path.join(os.path.dirname(__file__), '..', '..', 'XED-to-XML', 'obj', 'wkit', 'bin', 'xed')

   count = 0
   for line in csv.reader(lines[1:]):
      code = line[0]            
      with open('code.hex', 'w') as f:
         f.write(code)
      output = subprocess.check_output([xedBinary, '-64', '-v', '4', '-ih', 'code.hex'])
      disas = parseXedOutput(output)
      
      hasMem = any(instr.memOperands for instr in disas if 'nop' not in instr.asm)
      tp = float(line[args.col])

      if hasMem and (tp < 50):
         count += 1
         print line

   print(count)
   

if __name__ == "__main__":
    main()
