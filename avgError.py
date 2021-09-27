#!/usr/bin/env python3

import argparse
import binascii
import csv
import os
import subprocess
import sys
import numpy as np
import scipy
import seaborn as sns
import matplotlib
import matplotlib.pyplot as plt
from matplotlib.colors import LogNorm
from diskcache import Cache

sys.path.append(os.path.join(os.path.dirname(os.path.realpath(__file__)), '../uiCA'))
from disas import *
from x64_lib import *

xedCache = Cache('/tmp/cache/xed', size_limit=4*1024*1024*1024)
@xedCache.memoize()
def getDisas(hex):
   with open('code', 'wb') as f:
      f.write(binascii.unhexlify(hex))
   output = subprocess.check_output(['../uiCA/xed', '-v', '4', '-64', '-isa-set', '-chip-check', 'TIGER_LAKE', '-ir',  'code']).decode()
   return parseXedOutput(output)

memOpCache = Cache('/tmp/cache/memOpCache')
@memOpCache.memoize()
def getNumberOfMemOps(hex):
   disas = getDisas(hex)

   memR = len([o for i in disas for o, m in i.rw.items() if ('MEM' in o) and ('R' in m) and not 'nop' in i.asm])
   memW = len([o for i in disas for o, m in i.rw.items() if ('MEM' in o) and ('W' in m) and not 'nop' in i.asm])
   return (memR, memW)

def hasRWOp(hex):
   disas = getDisas(hex)
   return any(i for i in disas for o, m in i.rw.items() if ('R' in m) and ('W' in m))

def getNumberOfLCP(hex):
   disas = getDisas(hex)
   return sum(('PREFIX66' in instrD.attributes) and (int(instrD.attributes.get('IMM_WIDTH', 0)) == 16) for instrD in disas)

def hasMemRW(hex):
   disas = getDisas(hex)
   return any(i for i in disas for o, m in i.rw.items() if ('R' in m) and ('W' in m) and ('MEM' in o))

# maximum latency between the same instructions in two consecutive iterations;
# the latency of potentially eliminated instr. is assumed to be 0, the latency of address -> register 4, and all other latencies 1
def getMaxLat(hex):
   disas = [i for i in getDisas(hex) if (not 'nop' in i.asm) and any(('REG' in n) and (('W' in rw)) for n, rw in i.rw.items())]

   maxLat = 0
   for i in range(len(disas)):
      baseInstr = disas[i]
      baseInstrWRegs = {getCanonicalReg(r) for n, r in baseInstr.regOperands.items() if (not 'RFLAGS' in r) and ('W' in baseInstr.rw[n])}
      latForReg = {r: 0 for r in baseInstrWRegs}
      if baseInstrWRegs:
         for instr in disas[i+1:] + disas[:i+1]:
            rRegs = [getCanonicalReg(r) for n, r in instr.regOperands.items() if (not 'RFLAGS' in r) and (('R' in instr.rw[n]) or (r in Low8Regs))]
            wRegs = [getCanonicalReg(r) for n, r in instr.regOperands.items() if (not 'RFLAGS' in r) and ('W' in instr.rw[n])]
            addrRegs = []
            for _, m in instr.memOperands.items():
               memAddr = getMemAddr(m)
               memRegs = [r for r in [memAddr.base, memAddr.index] if r is not None]
               if 'lea' in instr.asm:
                  rRegs.extend(memRegs)
               else:
                  addrRegs.extend(memRegs)

            curLat = -1
            if (len(rRegs) == len(set(rRegs))) or (not any(m in instr.asm for m in ['xor', 'sub', 'pcmp'])):
               for r in set(rRegs) & latForReg.keys():
                  if ('mov' in instr.asm) and (len(instr.regOperands) == 2) and (not 'movsx' in instr.asm): # potentially eliminated
                     curLat = max(curLat, latForReg[r])
                  else:
                     curLat = max(curLat, latForReg[r] + 1)
               for r in set(addrRegs) & latForReg.keys():
                  curLat = max(curLat, latForReg[r] + 4)

            for wr in wRegs:
               if curLat >= 0:
                  latForReg[wr] = curLat
               else:
                  if wr in latForReg:
                     del latForReg[wr]

         for r in baseInstrWRegs & latForReg.keys():
            maxLat = max(maxLat, latForReg[r])

   return maxLat

# if cpiCol is not None, it must contain the column index of the assembler code; the TP is then normalized to CPI
def getColumn(lines, colIdx, cpiCol=None):
   col = []
   for l in csv.reader(lines):
      if (colIdx >= len(l)):
         print('Column not found')
         print(l)
         exit(1)
      TP = float(l[colIdx]) if (l[colIdx] not in ['fail', 'error', 'timeout', '']) else 0.0
      if cpiCol is not None:
         CPI = TP / (l[cpiCol].count(';') + 1)
         col.append(CPI)
      else:
         col.append(TP)
   return col

def getError(measurement, prediction):
   diff = [abs(m-p)/m for m, p in zip(measurement, prediction)]
   error = sum(diff)/len(diff)
   return error

def main():
   parser = argparse.ArgumentParser(description='AvgError')
   parser.add_argument('csv', help="csv file")
   parser.add_argument('col1', type=int)
   parser.add_argument('col2', type=int, nargs='?')
   parser.add_argument('-heatmap', nargs=2, help='1st arg: filename, 2nd arg: title')
   parser.add_argument('-showDiff', action='store_true')
   parser.add_argument('-metrics', default='MAPE,kendall,pearson,spearman')
   parser.add_argument('-round', action='store_true')
   parser.add_argument('-baselineUnroll', action='store_true')
   parser.add_argument('-baselineLoop', action='store_true')
   parser.add_argument('-issueWidth', type=int, default=4)
   parser.add_argument('-memWritePorts', type=int, default=1)
   parser.add_argument('-CPI', type=int, help='normalize TP to CPI; the parameter must contain the column index for the assembler code')
   parser.add_argument('-category', nargs=2, help='only consider the specified category; 1st arg: csv file, 2nd arg: category')
   args = parser.parse_args()

   with open(args.csv, 'r') as f:
      lines = f.read().splitlines()

   lines = lines[1:]

   if args.category:
      category = args.category[1]
      allBenchmarksForCategory = set()
      with open(args.category[0], 'r') as f:
         for line in f.read().splitlines():
            benchCode, benchCat = line.split(',')
            if benchCat == category:
               allBenchmarksForCategory.add(benchCode)
      lines = [l for l in lines if l.split(',')[0] in allBenchmarksForCategory]
      print('Applicable lines: ' + str(len(lines)))

   #lines = [l for l in lines if not 'fail' in l]

   tp1L = getColumn(lines, args.col1, args.CPI)

   tp2L = []
   if args.baselineUnroll:
      for i, l in enumerate(lines):
         hex = l.split(',')[0]
         nInstr = l.count(';') + 1
         memR, memW = getNumberOfMemOps(hex)
         lat = getMaxLat(hex)
         preDec = (len(hex)/2) / 16

         misc = 0
         #misc = max(misc, getNumberOfLCP(hex) * 3.2)
         #misc = max(misc, l.count('lea')/2)
         tp2L.append(100 * max(nInstr/4, memR/2, memW/args.memWritePorts, lat, preDec, misc))

         #if tp2L[-1] * .98 > tp1L[i]:
         #   print(str(i) + ': '+ l + ' - ' + str(tp2L[-1]))

   elif args.baselineLoop:
      for i, l in enumerate(lines):
         hex = l.split(',')[0] + l.split(',')[1]
         nInstr = l.count(';') # omit one bec. of macro fusion
         memR, memW = getNumberOfMemOps(hex)
         lat = getMaxLat(hex)
         misc = 0
         #misc = max(misc, l.count('lea')/2)
         tp2L.append(100 * max(nInstr/args.issueWidth, memR/2, memW/args.memWritePorts, lat, misc))

         #if tp2L[-1] * .98 > tp1L[i]:
         #   print(str(i) + ': '+ l + ' - ' + str(tp2L[-1]))
   else:
      tp2L = getColumn(lines, args.col2, args.CPI)

   if not args.heatmap:
      if args.showDiff:
         for tp1, tp2, l in zip(tp1L, tp2L, lines):
            #if not (tp1>0 and tp2>0): continue
            #if tp1 != tp2:
            #if abs(tp1-tp2)/tp1 > .1:
            #if abs(tp1-tp2) > 1:
            if tp1 < 0.98 * tp2:
               print(l + ' - ' + str(tp1) + ',' + str(tp2))

      if 'MAPE' in args.metrics:
         error = getError(tp1L, tp2L) * 100
         if args.round:
            print('{:.2f}'.format(error,2))
         else:
            print(error)
      if 'kendall' in args.metrics:
         tau = scipy.stats.kendalltau(tp1L, tp2L)
         if args.round:
            print('{:.4f}'.format(tau[0],4))
         else:
            print(tau)
      if 'pearson' in args.metrics:
         pearson = scipy.stats.pearsonr(tp1L, tp2L)
         if args.round:
            print('{:.4f}'.format(pearson[0]))
         else:
            print(pearson)
      if 'spearman' in args.metrics:
         spearman = scipy.stats.spearmanr(tp1L, tp2L)
         if args.round:
            print('{:.4f}'.format(spearman[0]))
         else:
            print(spearman)
   else:
      start = 0
      end = 1000

      data = [[0]*100 for _ in range(0,100)]

      for tp1, tp2 in zip(tp1L, tp2L):
         tp1 = int(round(tp1/10.0))
         tp2 = int(round(tp2/10.0))
         if tp1 < 100 and tp2 < 100:
            data[tp2][tp1] += 1

      start = 0
      end = 1000
      bins = np.arange(5, end + 6, 10)

      heatmap, _, _ = np.histogram2d(tp1L, tp2L, bins=bins)

      # based on Ithemal's Figures.ipynb

      extreme = max(map(abs, (heatmap.T.max(), heatmap.T.min())))
      extent = [start+5, end+5, start+5, end+5]
      lognorm = LogNorm(vmin=1, vmax=50000)
      clim = (-extreme, extreme)

      if args.heatmap[0]:
         matplotlib.use("pgf")
         matplotlib.rcParams.update({
            "pgf.texsystem": "pdflatex",
            'font.family': 'serif',
            'text.usetex': True,
            'pgf.rcfonts': False,
         })

      fig = plt.figure(figsize=(8, 6))
      ax = fig.add_subplot(1, 1, 1)
      plt.imshow(heatmap.T, cmap=sns.cm.rocket_r, norm=lognorm, extent=extent, origin='lower')
      plt.plot(np.linspace(start+5, end+5, 1000), np.linspace(start+5, end+5, 1000), 'k--', alpha=0.2)
      cbar = plt.colorbar()
      for t in cbar.ax.get_yticklabels():
         t.set_fontsize(14)
      plt.xticks(np.arange(start, end+1, 100), labels=range(0, 11, 1), fontsize=14)
      plt.yticks(np.arange(start, end+1, 100), labels=range(0, 11, 1), fontsize=14)
      ax.set_xlabel('Measured Throughput', fontsize=20)
      ax.set_ylabel('Predicted Throughput', fontsize=20)
      ax.set_title(args.heatmap[1], fontsize=20)

      if not args.heatmap[0]:
         plt.show()
      else:
         plt.savefig(args.heatmap[0], bbox_inches='tight')


if __name__ == "__main__":
    main()
