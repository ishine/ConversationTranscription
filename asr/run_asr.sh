#!/bin/bash

# Runs ASPIRE ASR model 
# downloaded from Kaldi: https://kaldi-asr.org/models/1/0001_aspire_chain_model.tar.gz
# leverages results from diarization and transcribes speech 

. ./cmd.sh
. ./path.sh

diarzerdir=../diarizer
datadir=`pwd`/data
inputdir=$datadir/inputs
mfccdir=$datadir/mfcc
nnetdir=$datadir/nnet/aspire_ASR

lmdir=$nnetdir/data/lang_pp_test
ivectordir=$nnetdir/exp/nnet3

stage=0


if [ $stage -le '0' ]; then
	# move our relevant data 
	#mkdir $inputdir
	#cp -a ../diarizer/data/cmn/. $inputdir/ # moves segments utt2speak and such
	utils/copy_data_dir.sh ../diarizer/data/cmn $inputdir 
	cp ../diarizer/data/nnet/0006_callhome_diarization_v2_1a/exp/xvector_nnet_1a/exp/xvectors/plda_scores_speakers/rttm $inputdir/rttm # moves diarization results

	# downsample wav files to 8khz
	sed 's/16000/8000/g' $inputdir/wav.scp > $inputdir/wav.tmp
	mv $inputdir/wav.tmp $inputdir/wav.scp
fi


# compute our cmvn statistics
if [ $stage -le '1' ]; then

	utils/mkgraph.sh --self-loop-scale 1.0 $nnetdir/data/lang_pp_test \
		$nnetdir/exp/chain/tdnn_7b $nnetdir/exp/chain/tdnn_7b/graph_pp

	steps/make_mfcc.sh --mfcc-config conf/mfcc_hires.conf --cmd "$train_cmd" --nj 8 \
		--write-utt2num-frames true $inputdir $mfccdir/log $mfccdir

	steps/compute_cmvn_stats.sh $inputdir
	utils/fix_data_dir.sh $inputdir
fi

# extract ivectors
if [ $stage -le '2' ]; then
	echo "Extracting i-Vectors"

	steps/online/nnet2/extract_ivectors.sh --cmd "$train_cmd" --nj 8 \
		--sub-speaker-frames 6000 --max-count 75 \
		$inputdir $lmdir $ivectordir/extractor $datadir/ivectors
fi

if [ $stage -le '3' ]; then
	echo "Decoding"
	steps/nnet3/decode.sh --nj 8 --cmd "$train_cmd" --config conf/decode.config \
		--acwt 1.0 --post-decode-acwt 10.0 --online-ivector-dir $datadir/ivectors \
		$nnetdir/exp/chain/tdnn_7b/graph_pp $inputdir $nnetdir/exp/chain/tdnn_7b/decode

	

fi	

