#!/usr/bin/env python3

import argparse
import binascii
import csv
import os
import subprocess
import sys

#def toLittleEndian(s):
#   return s[6:8] + s[4:6] + s[2:4] + s[0:2]

def getHexCode(assemblerCode):
   with open('code.s', 'w') as f:
      f.write('.intel_syntax noprefix\n')
      f.write(assemblerCode + '\n')      
   subprocess.check_call(['as', 'code.s', '-o', 'code.o'])
   subprocess.check_call(['objcopy', 'code.o', '-O', 'binary', 'code.o'])
   with open('code.o', 'rb') as f:
      return binascii.hexlify(f.read()).decode()
      

def main():
   parser = argparse.ArgumentParser(description='Measurements')
   parser.add_argument("-detectBankConflicts", action='store_true')
   parser.add_argument('csv', help="csv file")
   args = parser.parse_args()

   #rep = 10000
   #rep1Hex = toLittleEndian('%.8X' % rep)
   #rep2Hex = toLittleEndian('%.8X' % (2*rep))

   linesWithTLBReadMisses = []
   linesWithTLBWriteMisses = []
   linesWithDifferentMeasurements = []
   linesWithErrors = []
   linesWithBankConflicts = []
   
   with open(args.csv, 'r') as f:
      lines = f.read().splitlines()

   print(lines[0] + ',measurements')
   lines = lines[1:]

   with open(os.devnull, 'w') as devnull:
      for line in lines:
         try:
            lineSplit = next(csv.reader([line]))
            code = lineSplit[0]
            codeDecJmp = code + lineSplit[1] + lineSplit[2]
            reg = lineSplit[4]

            minTLBReadMisses = sys.maxsize
            minTLBWriteMisses = sys.maxsize
            cycles = []

            rep = 10000
            code_init1 = code + getHexCode('mov ' + reg + ', ' + str(rep))
            code_init2 = code + getHexCode('mov ' + reg + ', ' + str(2*rep))

            if args.detectBankConflicts:
               output = subprocess.check_output(['../timing-harness-BankConfl/test', codeDecJmp, code_init2, "1"], stderr=devnull).decode()
               minBankConflicts = min(int(ol.split()[4]) for ol in output.splitlines()[-10:])
               if minBankConflicts > 5:
                  linesWithBankConflicts.append(line + ' ' + str(minBankConflicts))
                  continue
         
            for _ in range(0,10):
               output1 = subprocess.check_output(['../timing-harness/test', codeDecJmp, code_init1, "1"], stderr=devnull).decode()
               output2 = subprocess.check_output(['../timing-harness/test', codeDecJmp, code_init2, "1"], stderr=devnull).decode()

               minTLBReadMisses = min(minTLBReadMisses, min(int(ol.split()[4]) for ol in output2.splitlines()[-10:]))
               minTLBWriteMisses = min(minTLBWriteMisses, min(int(ol.split()[3]) for ol in output2.splitlines()[-10:]))

               cycles1 = [int(ol.split()[0]) for ol in output1.splitlines()[-10:]]
               cycles2 = [int(ol.split()[0]) for ol in output2.splitlines()[-10:]]
               cycles.extend(float(c2-c1)/rep for c1, c2 in zip(cycles1, cycles2))

            minCycles = sorted(cycles)[len(cycles)//5]
            maxCycles = sorted(cycles)[4*len(cycles)//5]
            medCycles = sorted(cycles)[len(cycles)//2]
            
            if minTLBReadMisses > 5:
               linesWithTLBReadMisses.append(line + ' ' + str(minTLBReadMisses))
            elif minTLBWriteMisses > 5:
               linesWithTLBWriteMisses.append(line + ' ' + str(minTLBWriteMisses))
            else:
               if (maxCycles - minCycles) > 0.02:
                  linesWithDifferentMeasurements.append(line + ' ' + str(maxCycles) + ' - ' + str(minCycles))
                  continue
               TP = int(round(100 * float(medCycles)))
               print(line + ',' + str(TP))
         except subprocess.CalledProcessError as e:
            sys.stderr.write(str(e) + '\n')
            linesWithErrors.append(line + ' ' + str(e))

   for lines, filename in [(linesWithTLBReadMisses, 'ignored_TLBReadMisses.csv'), (linesWithTLBWriteMisses, 'ignored_TLBWriteMisses.csv'),
                           (linesWithDifferentMeasurements, 'ignored_DiffMeasurements.csv'), (linesWithErrors, 'ignored_errors.csv'),
                           (linesWithBankConflicts, 'ignored_BankConflicts.csv')]:
      with open(args.csv + '_' + filename, 'w') as f:
         f.write('\n'.join(lines))

if __name__ == "__main__":
    main()
