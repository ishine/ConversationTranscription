#!/bin/bash
  
# core file for running the diarization and transcription process 
# takes in the files and preps them for transcriptions
# calls diarization and asr scripts

# for now we just need to get the call diarization and asr part working

stage=0

# run speaker diarization
echo "Beginning Speaker Diarization"
if [ $stage -le '0' ]; then
	bash diarizer/run_diarization.sh
fi 

# once diarization is complete, run speech recognition
echo "Completed Diarization, Beginning Speech Recognition"
if [ $stage -le '1' ]; then
	bash asr/run_asr.sh
fi

echo "Text has been transcribed"

# push results to results folder
# combine and format the results


# return the results to user 
exit 0


