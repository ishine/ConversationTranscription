#!/bin/bash

# Runs ASPIRE ASR model 
# downloaded from Kaldi: https://kaldi-asr.org/models/1/0001_aspire_chain_model.tar.gz
# leverages results from diarization and transcribes speech 

# set to source directory
cd "$(dirname "$0")"

. ./cmd.sh
. ./path.sh

diarzerdir=../diarizer
datadir=`pwd`/data
inputdir=$datadir/inputs
mfccdir=$datadir/mfcc
nnetdir=$datadir/nnet/aspire_ASR

lmdir=$nnetdir/data/lang_pp_test
ivectordir=$nnetdir/exp/nnet3
graphdir=$nnetdir/exp/chain/tdnn_7b/graph_pp


stage=0
expandLM=false

if [ $stage -le '0' ]; then
	# move our relevant data 
	mkdir -p $inputdir
	#cp -a ../diarizer/data/cmn/. $inputdir/ # moves segments utt2speak and such
	#utils/copy_data_dir.sh ../diarizer/data/cmn $inputdir 
	cp ../diarizer/data/nnet/0006_callhome_diarization_v2_1a/exp/xvector_nnet_1a/exp/xvectors/plda_scores_speakers/rttm $inputdir/rttm # moves diarization results
	cp ../diarizer/data/cmn/wav.scp $inputdir/wav.scp

	# convert rttm file to segments file
	python local/RTTM2Files.py $inputdir
	utils/fix_data_dir.sh $inputdir


	# downsample wav files to 8khz
        sed 's/16000/8000/g' $inputdir/wav.scp > $inputdir/wav.tmp
	mv $inputdir/wav.tmp $inputdir/wav.scp

	#steps/make_mfcc.sh --mfcc-config conf/mfcc.conf --cmd "$train_cmd" --nj 8 \
	#               --cmd "$train_cmd" --write-utt2num-frames true \
	#                $inputdir exp/make_mfcc $mfccdir
	#utils/fix_data_dir.sh $inputdir
fi

if [ "$expandLM" = true ] && [ $stage -le '1' ]; then
	echo "Initiate LM Expansion"
	lmsrc=$nnetdir/data/local/new_lang
	dictsrc=$nnetdir/data/local/new_dict
	
	dictdir=$nnetdir/data/new_lm
	lmdir=$nnetdir/data/new_lm
	mkdir -p dictdir
	mkdir -p lmdir

	# expand the language model
	# update lmExpansion so that it takes lmsrc and dictsrc as parameters
	bash lmExpansion.sh

	# Compile the word lexicon (L.fst)
	utils/prepare_lang.sh --phone-symbol-table $graphdir/phones.txt \
	       	$dictsrc "" {$dictsrc}_tmp $dictdir

	# Compile the grammar/language model (G.fst)
	gzip  -f $lmsrc/lm.arpa
	#gunzip -c $lmsrc/lm.arpa.gz \
	#	  | egrep -v '<s> <s>|</s> <s>|</s> </s>|-1.573359|<s>|<\s>' \
	#	  | gzip -c > $lmsrc/lm_out.arpa.gz
	#mv $lmsrc/lm_out.arpa.gz $lmsrc/lm.arpa.gz

	utils/format_lm.sh $dictdir $lmsrc/lm.arpa.gz $dictsrc/lexicon.txt $lmdir	
	
	# generate the new graph dir where we store everything
	graphdir=$nnetdir/exp/chain/tdnn_7b/new_graph
	mkdir -p graphdir
fi

# compute our cmvn statistics
if [ $stage -le '1' ]; then

	utils/mkgraph.sh --self-loop-scale 1.0 $lmdir \
		$nnetdir/exp/chain/tdnn_7b $graphdir

	steps/make_mfcc.sh --mfcc-config conf/mfcc_hires.conf --cmd "$train_cmd" --nj 8 \
		--write-utt2num-frames true $inputdir $mfccdir/log $mfccdir

	steps/compute_cmvn_stats.sh $inputdir
	utils/fix_data_dir.sh $inputdir

	# prepare features for x-vector training
	local/prepare_feats.sh  --cmd "$train_cmd" --nj 8 \
	                $input_dir data/cmn exp/cmn
	utils/fix_data_dir.sh $input_dir
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
		$graphdir $inputdir $nnetdir/exp/chain/tdnn_7b/decode

	

fi	

