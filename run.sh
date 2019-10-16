#!/bin/bash

# bash file for running the transcription tool
# given a data set, runs the diarization process, then runs speech recognition
# exports transcribed text files by recording split by speaker
# requires trained speech recognition model and trained X-Vectors


data_dir=`pwd`/data # add data directory 
inter_dir=`pwd`/data/inter

. ./cmd.sh
. ./path.sh
set -e

mfccdir=$data_dir/mfcc
vaddir=$data_dir/mfcc
stage=0
nnet_dir=exp/xvector_nnet_1a/
num_components=1024 # the number of UBM components (used for VB resegmentation)
ivector_dim=400 # the dimension of i-vector (used for VB resegmentation)

# Prepare datasets
if [ $stage -le 0 ]; then
	# generate wav files 
	genWavFile.py $data_dir $inter_dir

	# generate MFCC features so that we can create the segments file 
	steps/make_mfcc.sh --mfcc-config conf/mfcc.conf --nj 40 \
		--cmd "$train_cmd" --write-utt2num-frames true \
		$inter_dir exp/make_mfcc $mfccdir
   	 utils/fix_data_dir.sh $inter_dir
	
	# Compute vad
	sid/compute_vad_decision.sh --nj 40 --cmd "$train_cmd" \
	       	$inter_dir exp/make_vad $vaddir  
	utils/fix_data_dir.sh $inter_dir # maybe only one fix_data_dir for compute_vad_decision and vad_to_segments?
	
	# prepare features for x-vector training
	local/nnet3/xvector/prepare_feats.sh --nj 40 --cmd "$train_cmd" \
      $inter_dir data/cmn exp/cmn
    cp $inter_dir/vad.scp data/cmn/
	
	
	# create segments file
	diarization/vad_to_segments.sh --nj 40 --cmd "$train_cmd" \
		$inter_dir $inter_dir
	utils/fix_data_dir.sh $inter_dir
	
fi
