#!/usr/bin/env python3

import argparse
import os
import subprocess
import sys

def main():
   parser = argparse.ArgumentParser(description='Measurements')
   parser.add_argument('-issueWidth', type=int, default=4)
   parser.add_argument("-detectBankConflicts", action='store_true')
   parser.add_argument('csv', help="csv file")
   args = parser.parse_args()
   
   with open(args.csv, 'r') as f:
      lines = f.read().splitlines()

   print(lines[0] + ',measurements')
   lines = lines[1:]

   linesWithTLBReadMisses = []
   linesWithTLBWriteMisses = []
   linesWithDifferentMeasurements = []
   linesWithErrors = []
   linesWithBankConflicts = []

   with open(os.devnull, 'w') as devnull:
      for line in lines:
         try:
            code = line.split(',')[0]            
            asm = line.split('"')[1]
            nInstr = asm.count(';') + 1

            nBytes = len(code)/2
            #nRepX = 4096/nBytes
            #nRepX = max(1, (nRepX/4) * 4) # should match issue/retire width

            nRep = max(1, max(1, ((500//nInstr)// args.issueWidth) * args.issueWidth))
            #nRep2 = max(1, ((800/nInstr) / 4) * 4)
            #nRep3 = max(1, ((1000//nInstr)// 4) * 4)          

            minTLBReadMisses = sys.maxsize
            minTLBWriteMisses = sys.maxsize
            #cycles1 = []
            #cycles2 = []
            cycles = []
            #allCycles1 = []
            #allCycles2 = []

            if args.detectBankConflicts:
               output = subprocess.check_output(['../myBHIVE/timing-harness-BankConfl/test', code, code, str(2*nRep)], stderr=devnull).decode()
               minBankConflicts = min(int(ol.split()[4]) for ol in output.splitlines()[-10:])
               if minBankConflicts > 5:
                  linesWithBankConflicts.append(line + ' ' + str(minBankConflicts))
                  continue
            
            for _ in range(0,10):
               #for nRep in [nRep1]:
                  # code also passed to code_init (and thus executed before lfence); the first execution of code often leads to TLB misses that might, e.g.,
                  # influence the port assignment
               output1 = subprocess.check_output(['../myBHIVE/timing-harness/test', code, code, str(nRep)], stderr=devnull).decode()
               output2 = subprocess.check_output(['../myBHIVE/timing-harness/test', code, code, str(2*nRep)], stderr=devnull).decode()
               
               minTLBReadMisses = min(minTLBReadMisses, min(int(ol.split()[4]) for ol in output2.splitlines()[-10:]))
               minTLBWriteMisses = min(minTLBWriteMisses, min(int(ol.split()[3]) for ol in output2.splitlines()[-10:]))

               cycles1 = [int(ol.split()[0]) for ol in output1.splitlines()[-10:]]
               cycles2 = [int(ol.split()[0]) for ol in output2.splitlines()[-10:]]
               cycles.extend(float(c2-c1)/nRep for c1, c2 in zip(cycles1, cycles2))

                  #allCycles1 += cycles1
                  #allCycles2 += cycles2

            #minCycles1 = sorted(cycles1)[len(cycles1)/5]
            #minCycles2 = sorted(cycles2)[len(cycles2)/5]
            #maxCycles1 = sorted(cycles1)[4*len(cycles1)/5]
            #maxCycles2 = sorted(cycles2)[4*len(cycles1)/5]

            
            minCycles = sorted(cycles)[len(cycles)//5]
            maxCycles = sorted(cycles)[4*len(cycles)//5]
            medCycles = sorted(cycles)[len(cycles)//2]
            
            if minTLBReadMisses > 5:
               linesWithTLBReadMisses.append(line + ' ' + str(minTLBReadMisses))
            elif minTLBWriteMisses > 5:
               linesWithTLBWriteMisses.append(line + ' ' + str(minTLBWriteMisses))
            else:
               #diff = minCycles2 - minCycles1
               
               #if (maxCycles / minCycles) > 1.01:
               #if (sorted(allCycles1)[4*len(allCycles1)//5] - sorted(allCycles1)[len(allCycles1)//2]) > 2:
               #   continue
               #if (sorted(allCycles2)[4*len(allCycles2)//5] - sorted(allCycles2)[len(allCycles2)//2]) > 2:
               #   continue
                  
               if (maxCycles - minCycles) > 0.02:
                  linesWithDifferentMeasurements.append(line + ' ' + str(maxCycles) + ' - ' + str(minCycles))
                  continue

                  
               #if (100*minCycles - int(100*minCycles)) == 0.5:
               #TP = 100 * float(minCycles)
               #else:
               TP = int(round(100 * float(medCycles)))
               #print((maxCycles / minCycles))
               #print(str(nBytes ) + ', ' + str(nRep) + ', ' + str(diff))
               #allCyclesMed1 = sorted(allCycles1)[len(allCycles1)//2]
               #allCyclesMed2 = sorted(allCycles2)[len(allCycles2)//2]
               #TPA = int(round(100 * float((allCyclesMed2 - allCyclesMed1)/nRep1)))
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
