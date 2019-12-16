#!/bin/bash
# alb2307 - all code created by me
  
# core file for running the diarization and transcription process 
# takes in the files and preps them for transcriptions
# calls diarization and asr scripts

# for now we just need to get the call diarization and asr part working

# vars

interdir=diarizer/data/inter
stage=0
threshold=0.5
lm_expansion=false
lm_corpus="none"

echo "$0 $@"
[ -f ./path.sh ] && . ./path.sh
. diarizer/utils/parse_options.sh || exit 1;

# to update
if [ $# -ne 3 ]; then
  echo "Usage: $0 [--stage (0|1...)] <raw-data-r> <output-name> <num-speakers>"
  echo " Options:"
  echo "    --stage (0|1|2|3)                 # start scoring script from part-way through."
  echo "    --lm_expansion (true/false)       # expand the language model with a new corpus."
  echo "    --lm_corpus <str>                 # path to corpus file used for language model expansiong "
  echo "    --threshold <int>                 # threshold for PLDA speaker clustering."
  exit 1;
fi

echo "$#"

rawdata=$1
outputdir=$2
num_speakers=$3 # can take on an integer value or "unknown"

# clean past results and generate starting files
if [ $stage = '0' ]; then

	"
	Kaldi does not automatically overwrite files and only generates some files if they do not already exist
	Since this project is data agnostic, we first delete all previously generated files
	if this is not done prior to any big data changes then errors will occur
	"
	# remove files generated from diarizer
	[ -e diarizer/data/cmn ] && rm -r diarizer/data/cmn
	[ -e $interdir ] && rm -r $interdir
	[ -e diarizer/data/mfcc ] && rm -r diarizer/data/mfcc

	# remove files generated from asr
	[ -e asr/data/inputs ] && rm -r asr/data/inputs
	[ -e asr/data/mfcc ] && rm -r asr/data/mfcc
	[ -e asr/data/cmn ] && rm -r asr/data/cmn

	# remove files generated from lmExpansion
	if [ '$lm_expansion' = true ]; then
		[ -e asr/data/lmdata ] && rm -r asr/data/lmdata
		[ -e asr/data/nnet/aspire_ASR/data/local/new_lang ] && rm -r asr/data/nnet/aspire_ASR/data/local/new_lang
		[ -e asr/data/nnet/aspire_ASR/data/local/new_dict ] && rm -r asr/data/nnet/aspire_ASR/data/local/new_dict
		[ -e asr/data/nnet/aspire_ASR/data/new_lm ] && rm -r asr/data/nnet/aspire_ASR/new_lm
	fi

	mkdir -p $interdir
	# generate wav files and prep base datasets 
	diarizer/local/initData.py $rawdata $interdir
	#diarizer/utils/fix_data_dir.sh $interdir

fi

# run speaker diarization
echo "Beginning Speaker Diarization"
if [ $stage -le '1' ]; then
	bash diarizer/run_diarization.sh --threshold $threshold $num_speakers
fi 

# once diarization is complete, run speech recognition
echo "Completed Diarization, Beginning Speech Recognition"
if [ $stage -le '2' ]; then
	
	bash asr/run_asr.sh --lm_expansion $lm_expansion --lm_corpus $lm_corpus
fi

echo "Text has been transcribed"

# push results to results folder
# combine and format the results
if [ $stage -le '3' ]; then
	cp asr/data/inputs/rttm results/raw/rttm
	
	# copy decoded files - assuming 8 jobs and 8 outputs
	# is this the same as best_path? 
	for i in {1..8}
	do
		cp asr/data/nnet/aspire_asr/chain/exp/tdnn_7b/decode/log/decode.$i.log results/raw/decode.$i.log
	done

	# combine results 
	# export outputdir
	mkdir -p results/$outputdir
	python formatTranscriptions.py results/$outputdir
fi
echo "Formatted Transcriptions"
echo "Saving Results for User"


# return the results to user 
exit 0


