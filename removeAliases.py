#!/usr/bin/python

import argparse

def main():
   parser = argparse.ArgumentParser(description='Remove basic blocks based on the BHive may-alias.csv file')
   parser.add_argument('csv', help="csv file")
   parser.add_argument('mayAlias', help=" may-alias.csv file")
   args = parser.parse_args()
   
   with open(args.csv, 'r') as f:
      lines = f.read().splitlines()

   with open(args.mayAlias, 'r') as f:
      mayAliasBlocks = set(f.read().splitlines())   
   
   for line in lines:
      code = line.split(',')[0]
      if code in mayAliasBlocks:      
         continue
      print line

if __name__ == "__main__":
    main()
