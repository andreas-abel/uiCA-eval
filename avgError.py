#!/usr/bin/env python3

import argparse
import csv
import importlib
import numpy as np
import os
import sys
import scipy.stats

sys.path.append(os.path.join(os.path.dirname(os.path.realpath(__file__)), '../uiCA'))
import xed
from x64_lib import *
from uiCA import getInstructions, adjustLatenciesAndAddMergeUops
from microArchConfigs import MicroArchConfigs
from analyticalPredictor import *


def getNumberOfMemOps(disas):
   memR = len([o for i in disas for o, m in i['rw'].items() if ('MEM' in o) and ('R' in m) and not 'nop' in i['asm']])
   memW = len([o for i in disas for o, m in i['rw'].items() if ('MEM' in o) and ('W' in m) and not 'nop' in i['asm']])
   return (memR, memW)

def getNumberOfLCP(disas):
   return sum((instrD['prefix66'] != '0') and (instrD.get('IMM_WIDTH', 0) == 16) for instrD in disas)

# maximum latency between the same instructions in two consecutive iterations;
# the latency of potentially eliminated instr. is assumed to be 0, the latency of address -> register 4, and all other latencies 1
def getMaxLat(disas):
   disas = [i for i in disas if (not 'nop' in i['asm']) and any(('REG' in n) and (('W' in rw)) for n, rw in i['rw'].items())]

   maxLat = 0
   for i in range(len(disas)):
      baseInstr = disas[i]
      baseInstrWRegs = {getCanonicalReg(r) for n, r in baseInstr['regOperands'].items() if (not 'RFLAGS' in r) and ('W' in baseInstr['rw'][n])}
      latForReg = {r: 0 for r in baseInstrWRegs}
      if baseInstrWRegs:
         for instr in disas[i+1:] + disas[:i+1]:
            rRegs = [getCanonicalReg(r) for n, r in instr['regOperands'].items() if (not 'RFLAGS' in r) and (('R' in instr['rw'][n]) or (r in Low8Regs))]
            wRegs = [getCanonicalReg(r) for n, r in instr['regOperands'].items() if (not 'RFLAGS' in r) and ('W' in instr['rw'][n])]
            addrRegs = []
            for _, m in instr['memOperands'].items():
               memRegs = [r for r in [m.get('base'), m.get('index')] if r is not None]
               if 'lea' in instr['asm']:
                  rRegs.extend(memRegs)
               else:
                  addrRegs.extend(memRegs)

            curLat = -1
            if (len(rRegs) == len(set(rRegs))) or (not any(m in instr['asm'] for m in ['xor', 'sub', 'pcmp'])):
               for r in set(rRegs) & latForReg.keys():
                  if ('mov' in instr['asm']) and (len(instr['regOperands']) == 2) and (not 'movsx' in instr['asm']): # potentially eliminated
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

def getBaselineForUnrolling(hex, xedDisas, nMemWritePorts):
   nInstr = len(xedDisas)
   memR, memW = getNumberOfMemOps(xedDisas)
   #lat = getMaxLat(disas)
   preDec = (len(hex)/2) / 16
   misc = 0
   #misc = max(misc, getNumberOfLCP(disas) * 3.2)
   #misc = max(misc, l.count('lea')/2)
   return max(nInstr/4, memR/2, memW/nMemWritePorts) #, lat, preDec, misc))

def getBaselineForLoop(xedDisas, nMemWritePorts, issueWidth):
   nInstr = len(xedDisas) - 1 # omit one bec. of macro fusion
   memR, memW = getNumberOfMemOps(xedDisas)
   #lat = getMaxLat(disas)
   misc = 0
   #misc = max(misc, l.count('lea')/2)
   return max(1, nInstr/issueWidth, memR/2, memW/nMemWritePorts) #, lat, misc))


def main():
   parser = argparse.ArgumentParser(description='AvgError')
   parser.add_argument('csv', help="csv file")
   parser.add_argument('col1', type=int)
   parser.add_argument('col2', type=int, nargs='?')
   parser.add_argument('-heatmap', nargs=2, help='1st arg: filename, 2nd arg: title')
   parser.add_argument('-showDiff', action='store_true')
   parser.add_argument('-metrics', default='count,MAPE,kendall,pearson,spearman')
   parser.add_argument('-round', action='store_true')
   parser.add_argument('-baselineUnroll', action='store_true')
   parser.add_argument('-baselineLoop', action='store_true')
   parser.add_argument('-issueWidth', type=int, default=4)
   parser.add_argument('-memWritePorts', type=int, default=1)
   parser.add_argument('-CPI', type=int, help='normalize TP to CPI; the parameter must contain the column index for the assembler code')
   parser.add_argument('-category', nargs=2, help='only consider the specified category; 1st arg: csv file, 2nd arg: category')
   parser.add_argument('-source', nargs=2, help='only consider the specified source; 1st arg: sources folder, 2nd arg: source application')
   parser.add_argument('-arch', help='Microarchitecture', default='SKL')
   parser.add_argument('-analyticalUnroll', action='store_true')
   parser.add_argument('-analyticalLoop', action='store_true')
   parser.add_argument('-analyticalComponents', default='predec,dec,dsb,lsd,issue,portUsage,lat')
   parser.add_argument('-bottlenecks', action='store_true') # can only be used together with -analytical*
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

   if args.source:
      sourceFileMap = {
         'OpenBLAS': [f for _, _, fs in os.walk(args.source[0]) for f in fs if f.startswith('openblas')],
         'Redis': ['redis-server.csv'],
         'SQLite': ['sqlite.csv'],
         'GZip': ['gzip-compress.csv', 'gzip-decompress.csv'],
         'TensorFlow': ['tensorflow.csv'],
         'Clang/LLVM': ['clang.csv'],
         'Eigen': ['eigen-matmat.csv', 'eigen-vecmat.csv'],
         'Embree': ['embree.csv'],
         'FFmpeg': ['ffmpeg.csv'],
         'OpenSSL': ['openssl.csv']
      }
      allBenchmarksForSource = set()
      for filename in sourceFileMap[args.source[1]]:
         with open(os.path.join(args.source[0], filename), 'r') as f:
            allBenchmarksForSource.update(l.split(',')[0] for l in f.read().splitlines())
      lines = [l for l in lines if l.split(',')[0] in allBenchmarksForSource]

   uArchConfig = None
   archData = None
   bottlenecks = {}
   if args.analyticalUnroll or args.analyticalLoop:
      uArchConfig = MicroArchConfigs[args.arch]
      archData = importlib.import_module('instrData.'+uArchConfig.name+'_data')

   tp1L = getColumn(lines, args.col1, args.CPI)
   tp2L = []

   if args.baselineUnroll or args.analyticalUnroll:
      for l in lines:
         hex = l.split(',')[0]
         disas = xed.disasHex(hex, chip='TIGER_LAKE')
         if args.baselineUnroll:
            tp2L.append(100 * getBaselineForUnrolling(hex, disas, args.memWritePorts))
         elif args.analyticalUnroll:
            instructions = getInstructions(disas, uArchConfig, archData, 0)
            #adjustLatenciesAndAddMergeUops(instructions, uArchConfig)

            TPs = getAnalyticalPredictionForUnrolling(instructions, hex, disas, uArchConfig, args.analyticalComponents.split(','))

            TP = max(v for _, v in TPs)
            tp2L.append(round(100 * TP))

            if args.bottlenecks:
               key = frozenset(n for n, v in TPs if .99 < (v/TP) < 1.01)
               bottlenecks[key] = bottlenecks.get(key, 0) + 1
   elif args.baselineLoop or args.analyticalLoop:
      for l in lines:
         hex = l.split(',')[0] + l.split(',')[1] + l.split(',')[2]
         disas = xed.disasHex(hex, chip='TIGER_LAKE')
         if args.baselineLoop:
            tp2L.append(100 * getBaselineForLoop(disas, args.memWritePorts, args.issueWidth))
         elif args.analyticalLoop:
            instructions = getInstructions(disas, uArchConfig, archData, 0)
            #adjustLatenciesAndAddMergeUops(instructions, uArchConfig)

            TPs = getAnalyticalPredictionForLoop(instructions, hex, disas, uArchConfig, args.analyticalComponents.split(','))

            TP = max(v for _, v in TPs)
            tp2L.append(round(100 * TP))

            if args.bottlenecks:
               key = frozenset(n for n, v in TPs if .99 < (v/TP) < 1.01)
               bottlenecks[key] = bottlenecks.get(key, 0) + 1
   else:
      tp2L = getColumn(lines, args.col2, args.CPI)

   if args.bottlenecks:
      for n, v in sorted(bottlenecks.items(), key=lambda x: -x[1]):
         print('{' + ', '.join(n) + '}: ' + str(round(100 * v/len(lines), 2)) + '%')

   if not args.heatmap:
      if args.showDiff:
         for tp1, tp2, l in zip(tp1L, tp2L, lines):
            #if not (tp1>0 and tp2>0): continue
            #if tp1 != tp2:
            #if abs(tp1-tp2)/tp1 > .1:
            #if abs(tp1-tp2) > 1:
            if tp1 < 0.95 * tp2:
               print(l + ' - ' + str(tp1) + ',' + str(tp2))

      if 'count' in args.metrics:
         print('Count: {}'.format(len(lines)))
      if 'MAPE' in args.metrics:
         error = getError(tp1L, tp2L) * 100
         if args.round:
            print('MAPE: {:.2f}'.format(error))
         else:
            print('MAPE: {}'.format(error))
      if 'kendall' in args.metrics:
         tau = scipy.stats.kendalltau(tp1L, tp2L)
         if args.round:
            print('Kendall: {:.4f}'.format(tau[0]))
         else:
            print('Kendall: {}'.format(tau[0]))
      if 'pearson' in args.metrics:
         pearson = scipy.stats.pearsonr(tp1L, tp2L)
         if args.round:
            print('Pearson: {:.4f}'.format(pearson[0]))
         else:
            print('Pearson: {}'.format(pearson[0]))
      if 'spearman' in args.metrics:
         spearman = scipy.stats.spearmanr(tp1L, tp2L)
         if args.round:
            print('Spearman: {:.4f}'.format(spearman[0]))
         else:
            print('Spearman: {}'.format(spearman[0]))
   else:
      import seaborn as sns
      import matplotlib
      import matplotlib.pyplot as plt
      from matplotlib.colors import LogNorm

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
