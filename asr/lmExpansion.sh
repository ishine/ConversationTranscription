#!/bin/bash

# Generates a new lm corpus
# recompiles the language model
# recompiles the graph 

datadir=`pwd`/data
lmdatadir=$datadir/lmdata
transcriptiondir=../rawData/CallHome/eng/transcriptions

# generate corpus 
local/genCallHomeCorpus.py transcriptiondir lmdatadir

# get unique words
grep -oE "[A-Za-z\\-\\']{3,}" $lmdatadir/corpus.txt | tr '[:lower:]' '[:upper:]' | sort | uniq > $lmdatadir/words.txt

