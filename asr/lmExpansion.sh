#!/bin/bash
# alb2307 - all code created by me

# Generates a new LM corpus
# recompiles the language model to include new words
# recompiles the graph

[ -f ./path.sh ] && . ./path.sh
. utils/parse_options.sh || exit 1;


corpus=$1

datadir=`pwd`/data
lmdatadir=$datadir/lmdata
transcriptiondir=../rawData/CallHome/callhome_english_trans_970711/transcrpt
G2Pdir=$datadir/nnet/sequiturG2P
nnetdir=$datadir/nnet/aspire_ASR
newlmdir=$nnetdir/data/local/new_lang
newdictdir=$nnetdir/data/local/new_dict

. ./path.sh

# assume that user has already created a corpus file
# generate corpus
mkdir -p $lmdatadir
if [ "$corpus" = "none" ]; then

	local/genCallHomeCorpus.py $transcriptiondir $lmdatadir
	corpus=$lmdatadir/corpus.txt
	echo "$corpus"
fi

echo "Get unique words from corpus"
# get unique words
grep -oE "[A-Za-z\\-\\']{3,}" $corpus | tr '[:lower:]' '[:upper:]' | sort | uniq > $lmdatadir/words.txt

echo "Convert graphemes to phonemes"
# convert graphemes to phonemes
g2p.py --model $G2Pdir/model-b.key --apply $lmdatadir/words.txt > $lmdatadir/words.dic

echo "Convert Corpus to Upper Case"
cat $lmdatadir/corpus.txt | tr '[:lower:]' '[:upper:]' > $lmdatadir/corpus_upper.txt

echo "Generate Language Model from our Corpus"
ngram-count -text $lmdatadir/corpus_upper.txt -order 3 \
	-limit-vocab 2 -vocab $lmdatadir/words.txt -unk -map-unk "<UNK>" \
        -kndiscount -interpolate -lm $lmdatadir/new_lm.arpa

echo "merging new language model files with Aspire"
mkdir -p $newlmdir
mkdir -p $newdictdir
python local/mergeLmDicts.py $nnetdir/data/local/dict/lexicon4_extra.txt \
	$nnetdir/data/local/lm/3gram-mincount/lm_unpruned \
	$lmdatadir/words.dic $lmdatadir/new_lm.arpa \
	$lmdatadir/merged-lexicon.txt $lmdatadir/merged-lm.arpa

# copy over additional relevant files 
cp $lmdatadir/merged-lexicon.txt $newdictdir/lexicon.txt
cp $lmdatadir/merged-lm.arpa $newlmdir/lm.arpa
cp $nnetdir/data/local/dict/extra_questions.txt $newdictdir/extra_questions.txt
cp $nnetdir/data/local/dict/nonsilence_phones.txt $newdictdir/nonsilence_phones.txt
cp $nnetdir/data/local/dict/optional_silence.txt $newdictdir/optional_silence.txt
cp $nnetdir/data/local/dict/silence_phones.txt $newdictdir/silence_phones.txt

echo "Finalized Language Model Expansion"
exit 0

