#!/bin/bash

# Runs ASPIRE ASR model 
# downloaded from Kaldi: https://kaldi-asr.org/models/1/0001_aspire_chain_model.tar.gz
# leverages results from diarization and transcribes speech 

../cmd.sh
../path.sh

diarzerdir=../diarizer
datadir=`pwd`/data
mfccdir=$datadir/mfcc
nnetdir=$datadir/nnet/aspire_ASR

init=true
stage=0


# initiate the model with the following - only need to run once
if [ "$init" =  true ]; then
	steps/online/nnet3/prepare_online_decoding.sh --mfcc-config conf/mfcc_hires.conf \
		$nnetdir/data/lang_chain $nnetdir/exp/nnet3/extractor \
		$nnetdir/exp/chain/tdnn_7b $nnetdir/exp/tdnn_7b_chain_online

	utils/mkgraph.sh --self-loop-scale 1.0 $nnetdir/data/lang_pp_test \
		$nnetdir/exp/tdnn_7b_chain_online $nnetdir/exp/tdnn_7b_chain_online/graph_pp
fi


