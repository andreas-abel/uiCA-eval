#!/usr/bin/python

import argparse
import subprocess

# run inside Ithemal docker container
def main():
   parser = argparse.ArgumentParser(description='Ithemal')
   parser.add_argument('csv', help="csv file")
   parser.add_argument('arch', help="ivb, hsw, or skl")
   parser.add_argument('model', help="paper, bhive")
   args = parser.parse_args()

   if args.model == 'paper':
      if args.arch == 'ivb':
         archLong = 'ivybridge'
      elif args.arch == 'hsw':
         archLong = 'haswell'
      elif args.arch == 'skl':
         archLong = 'skylake'
      dumpFile = '/home/ithemal/hosthome/code/Ithemal-models/paper/' + archLong + '/predictor.dump'
      mdlFile = '/home/ithemal/hosthome/code/Ithemal-models/paper/' + archLong + '/trained.mdl'
   elif args.model == 'bhive':
      dumpFile = '/home/ithemal/hosthome/code/Ithemal-models/bhive/' + args.arch + '.dump'
      mdlFile = '/home/ithemal/hosthome/code/Ithemal-models/bhive/' + args.arch + '.mdl'

   with open(args.csv, 'r') as f:
      lines = f.read().splitlines()

   print(lines[0] + ',Ithemal_' + args.model)
   lines = lines[1:]

   ithemal = subprocess.Popen(['python', '-u', '/home/ithemal/ithemal/learning/pytorch/ithemal/predict.py', '--model', dumpFile, '--model-data', mdlFile,
                               '--raw-stdin'], stdin = subprocess.PIPE, stdout = subprocess.PIPE)
   for line in lines:
      code = line.split(',')[0]
      ithemal.stdin.write(code+'\n')
      ithemal.stdin.flush()
      outputLine = ithemal.stdout.readline().strip()
      print(line + ',' + outputLine.split(',')[1])


if __name__ == "__main__":
    main()
