#!/bin/bash
# prepares necessary data for diarization


. ./path.sh

# Merge transcripts into a single 'stm' file, do some mappings:
# - <F0_M> -> <o,f0,male> : map dev stm labels to be coherent with train + test,
# - <F0_F> -> <o,f0,female> : --||--
# - (2) -> null : remove pronunciation variants in transcripts, keep in dictionary
# - <sil> -> null : remove marked <sil>, it is modelled implicitly (in kaldi)
# - (...) -> null : remove utterance names from end-lines of train
# - it 's -> it's : merge words that contain apostrophe (if compound in dictionary, local/join_suffix.py)
{ # Add STM header, so sclite can prepare the '.lur' file

 echo ';;
;; LABEL "o" "Overall" "Overall results"
;; LABEL "f0" "f0" "Wideband channel"
;; LABEL "f2" "f2" "Telephone channel"
;; LABEL "male" "Male" "Male Talkers"
;; LABEL "female" "Female" "Female Talkers"
;;'
    # Process the STMs
    cat db/TEDLIUM_release2/$set/stm/*.stm | sort -k1,1 -k2,2 -k4,4n | \
      sed -e 's:<F0_M>:<o,f0,male>:' \
          -e 's:<F0_F>:<o,f0,female>:' \
          -e 's:([0-9])::g' \
          -e 's:<sil>::g' \
          -e 's:([^ ]*)$::' | \
      awk '{ $2 = "A"; print $0; }'
  } | local/join_suffix.py > data/$set.orig/stm