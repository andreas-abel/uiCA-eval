#!/usr/bin/env python3

import argparse
import csv
import numpy as np
import scipy
import seaborn as sns
import matplotlib
import matplotlib.pyplot as plt
from matplotlib.colors import LogNorm

# if cpiCol is not None, it must contain the column index of the assembler code; the TP is then normalized to CPI
def getColumn(lines, colIdx, cpiCol=None):
   col = []
   for l in csv.reader(lines):
      if (colIdx >= len(l)):
         print('Column not found')
         print(l)
         exit(1)
      #print(l)
      #print(float(l[colIdx]))
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
   parser.add_argument('-heatmap', action='store_true')
   parser.add_argument('-showDiff', action='store_true')
   parser.add_argument('-metrics', default='MAPE,kendall,pearson,spearman')
   parser.add_argument('-round', action='store_true')
   parser.add_argument('-baselineUnroll', action='store_true')
   parser.add_argument('-baselineLoop', action='store_true')
   parser.add_argument('-issueWidth', type=int, default=4)
   parser.add_argument('-CPI', type=int, help="normalize TP to CPI; the parameter must contain the column index for the assembler code")
   args = parser.parse_args()
      
   with open(args.csv, 'r') as f:
      lines = f.read().splitlines()

   lines = lines[1:]

   #lines = [l for l in lines if not 'fail' in l]

   tp1L = getColumn(lines, args.col1, args.CPI)

   if args.baselineUnroll:
      tp2L = [25*(l.count(';') + 1) for l in lines]
   elif args.baselineLoop:
      mul = 100 / args.issueWidth
      tp2L = [max(100, mul*(l.count(';'))) for l in lines]
      #print(tp2L)
   else:
      tp2L = getColumn(lines, args.col2, args.CPI)   

   if not args.heatmap:
      if args.showDiff:
         for tp1, tp2, l in zip(tp1L, tp2L, lines):
            #if not (tp1>0 and tp2>0): continue
            #if tp1 != tp2:
            if abs(tp1-tp2)/tp1 > .1:
            #if abs(tp1-tp2) > 1:
               print(l)

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

      #fig = plt.figure()
      
      
      #heatMap = sns.heatmap(heatmap.T, norm=LogNorm(), cmap=sns.cm.rocket_r, vmin=1, vmax=50000)
      #heatMap.invert_yaxis()
      
      #plt.plot(np.linspace(start, end, 1000), np.linspace(start, end, 1000), 'k--', alpha=0.2)
      #plt.grid()
      #ax = fig.gca()
      #ax.set_xticks(np.arange(5.5, 106, 10))
      #ax.set_yticks(np.arange(5.5, 106, 10))
      #plt.show()
      
      #exit(0)
      
      matplotlib.use("pgf")
      matplotlib.rcParams.update({
          "pgf.texsystem": "pdflatex",
          'font.family': 'serif',
          'text.usetex': True,
          'pgf.rcfonts': False,
      })

      '''
      for b in range(len(bins) - 1):
         print(heatmap[b, :])
         div = heatmap[b, :].sum() or 1
         heatmap[b, :] /= div
      '''
      # based on Ithemal's Figures.ipynb

      extreme = max(map(abs, (heatmap.T.max(), heatmap.T.min())))
      # extreme = 1
      extent = [start+5, end+5, start+5, end+5]
      lognorm = LogNorm()
      #lognorm = None
      clim = (-extreme, extreme)
      print(heatmap.T)

      cmap = plt.get_cmap('bwr')

      fig = plt.figure(figsize=(8, 6))
      ax = fig.add_subplot(1, 1, 1)
      plt.imshow(heatmap.T, cmap=sns.cm.rocket_r, norm=lognorm, extent=extent, origin='lower', vmin=1, vmax=50000)
      plt.plot(np.linspace(start+5, end+5, 1000), np.linspace(start+5, end+5, 1000), 'k--', alpha=0.2)
      #plt.grid()
      cbar = plt.colorbar()
      #plt.tick_params(labelsize=10)
      #cbar.ax.tick_params(labelsize=10)
      plt.xticks(np.arange(start, end+1, 100), labels=range(0, 11, 1))
      plt.yticks(np.arange(start, end+1, 100), labels=range(0, 11, 1))
      ax.set_xlabel('Measured Throughput', fontsize=14)
      ax.set_ylabel('Predicted Throughput', fontsize=14)
      ax.set_title('Haswell', fontsize=16)
      #plt.show()

      
      plt.savefig('histogram.pgf')

   
if __name__ == "__main__":
    main()
