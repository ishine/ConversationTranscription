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
nnet_dir=$data_dir/nnet/0003_sre16_v2_1a/exp/xvector_nnet_1a
num_components=1024 # the number of UBM components (used for VB resegmentation)
ivector_dim=400 # the dimension of i-vector (used for VB resegmentation)

# Prepare datasets
if [ $stage -le 0 ]; then
	# generate wav files 
	local/initData.py $data_dir $inter_dir
	utils/fix_data_dir.sh $inter_dir

	# generate MFCC features so that we can create the segments file 
	steps/make_mfcc.sh --mfcc-config conf/mfcc.conf --cmd "$train_cmd" --nj 8 \
		--cmd "$train_cmd" --write-utt2num-frames true \
		$inter_dir exp/make_mfcc $mfccdir
   	utils/fix_data_dir.sh $inter_dir

fi


# prepare features for X vector extraction
if [ $stage -le 1 ]; then
	
	# Compute vad
	sid/compute_vad_decision.sh  --cmd "$train_cmd" --nj 8 \
	       	$inter_dir exp/make_vad $vaddir  
	utils/fix_data_dir.sh $inter_dir # maybe only one fix_data_dir for compute_vad_decision and vad_to_segments?
	

	# prepare features for x-vector training
	local/prepare_feats.sh  --cmd "$train_cmd" --nj 8 \
	       	$inter_dir data/cmn exp/cmn
	utils/fix_data_dir.sh $inter_dir
	cp $inter_dir/vad.scp data/cmn	
	

	# create segments file
	diarization/vad_to_segments.sh  --cmd "$train_cmd" --nj 8 \
		$inter_dir  data/cmn/segmented
	utils/fix_data_dir.sh $inter_dir

	# prepare our cepstral mean normalization for X-vector extraction
	cp $inter_dir/subsegments data/cmn/segments
	utils/fix_data_dir.sh data/cmn
	
fi

# extract our x-vectors
if [ $stage -le 2 ]; then
	diarization/nnet3/xvector/extract_xvectors.sh --cmd "$train_cmd" --nj 8 \
		--window 1.5 --period 0.75 --apply-cmn false \
		--min-segment 0.5 $nnet_dir \
		data/cmn $nnet_dir/exp/xvectors
fi


