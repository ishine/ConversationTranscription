#!/bin/bash

# bash file for running the diarization process for a given dataset
# exports a text file of diarization results to be leverage in speech recognition

# leverages callhome Xvector model: https://kaldi-asr.org/models/6/0006_callhome_diarization_v2_1a.tar.gz


data_dir=`pwd`/data # add data directory 
inter_dir=`pwd`/data/inter

. ./cmd.sh
. ./path.sh
set -e

rawdata=../rawData
mfccdir=$data_dir/mfcc
vaddir=$data_dir/mfcc
stage=0
nnet_dir=$data_dir/nnet/0006_callhome_diarization_v2_1a/exp/xvector_nnet_1a
num_components=1024 # the number of UBM components (used for VB resegmentation)
ivector_dim=400 # the dimension of i-vector (used for VB resegmentation)


if [ $stage -le 0 ]; then
# before starting remove already created files
	[ -e data/cmn ] && rm -r data/cmn
	[ -e $inter_dir ] && rm -r $inter_dir
# Generate Segments file 

	# generate wav files and prep base datasets 
	local/initData.py $rawdata/CallHome $inter_dir
	utils/fix_data_dir.sh $inter_dir

	# generate MFCC features so that we can create the segments file 
	steps/make_mfcc.sh --mfcc-config conf/mfcc.conf --cmd "$train_cmd" --nj 8 \
		--cmd "$train_cmd" --write-utt2num-frames true \
		$inter_dir exp/make_mfcc $mfccdir
   	utils/fix_data_dir.sh $inter_dir
	
	# Compute vad
	sid/compute_vad_decision.sh  --cmd "$train_cmd" --nj 8 \
	       	$inter_dir exp/make_vad $vaddir  
	utils/fix_data_dir.sh $inter_dir 
	
	# create segments file
	diarization/vad_to_segments.sh  --cmd "$train_cmd" --nj 8 \
		$inter_dir  $inter_dir/segmented
	utils/fix_data_dir.sh $inter_dir
	
	mv $inter_dir/subsegments $inter_dir/segments # rename the segments 
	
	# combine segments
	local/combineSegments.py $inter_dir .5 4
	

fi


# Now re-run the process to create X-Vectors features
if [ $stage -le 1 ]; then

	rm $inter_dir/feats.scp $inter_dir/vad.scp $inter_dir/utt2dur $inter_dir/utt2num_frames	

	# generate wav files and prep base datasets 
	local/initData.py $data_dir $inter_dir
	utils/fix_data_dir.sh $inter_dir

	# generate MFCC features so that we can create the segments file 
	steps/make_mfcc.sh --mfcc-config conf/mfcc.conf --cmd "$train_cmd" --nj 8 \
		--cmd "$train_cmd" --write-utt2num-frames true \
		$inter_dir exp/make_mfcc $mfccdir
   	utils/fix_data_dir.sh $inter_dir
	
	# Compute vad
	sid/compute_vad_decision.sh  --cmd "$train_cmd" --nj 8 \
	       	$inter_dir exp/make_vad $vaddir  
	utils/fix_data_dir.sh $inter_dir 

	# prepare features for x-vector training
	local/prepare_feats.sh  --cmd "$train_cmd" --nj 8 \
	       	$inter_dir data/cmn exp/cmn
	utils/fix_data_dir.sh $inter_dir
	cp $inter_dir/vad.scp data/cmn	
	

	# move relevant files for cepstral mean normalization for X-vector extraction
	cp $inter_dir/segments data/cmn/segments
	cp -r  $inter_dir/segmented data/cmn/segmented
	utils/fix_data_dir.sh data/cmn
	
	

fi

# extract our x-vectors
if [ $stage -le 2 ]; then
	diarization/nnet3/xvector/extract_xvectors.sh --cmd "$train_cmd" --nj 8 \
		--window 1.5 --period .75 --apply-cmn false \
		--min-segment 0.5 $nnet_dir \
		data/cmn $nnet_dir/exp/xvectors
fi


# tune PLDA clustering and export diarization
if [ $stage -le 3 ]; then
       diarization/nnet3/xvector/score_plda.sh \
		--cmd "$train_cmd" \
		--target-energy 0.9 --nj 8 $nnet_dir/xvectors_callhome1 \
		$nnet_dir/exp/xvectors $nnet_dir/exp/xvectors/plda_scores


	# we know number of speakers
	awk '{print $1, 2}' $inter_dir/segments > $inter_dir/reco2num_spk

	diarization/cluster.sh --cmd "$train_cmd" --nj 8 \
		--reco2num-spk $inter_dir/reco2num_spk \
		$nnet_dir/exp/xvectors/plda_scores \
		$nnet_dir/exp/xvectors/plda_scores_speakers
fi
