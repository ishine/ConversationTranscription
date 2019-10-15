#!/bin/bash

# bash file for running the transcription tool
# given a data set, runs the diarization process, then runs speech recognition
# exports transcribed text files by recording split by speaker
# requires trained speech recognition model and trained X-Vectors


data_dir= `pwd`\data # add data directory 
train_dir=`pwd`\data\train

. ./cmd.sh
. ./path.sh
set -e

mfccdir=`pwd`/mfcc
vaddir=`pwd`/mfcc
stage=0
nnet_dir=exp/xvector_nnet_1a/
num_components=1024 # the number of UBM components (used for VB resegmentation)
ivector_dim=400 # the dimension of i-vector (used for VB resegmentation)

# Prepare datasets
if [ $stage -le 0 ]; then
	# generate wav files 
	genWavFile.py data_root train_dir

	# generate MFCC features so that we can create the segments file 
	steps/make_mfcc.sh --mfcc-config conf/mfcc.conf --nj 40 \
      --cmd "$train_cmd" --write-utt2num-frames true \
      data/$name exp/make_mfcc $mfccdir
    utils/fix_data_dir.sh data/$name
fi
