# -*- coding: utf-8 -*-
"""
Created on Sat Nov 23 15:36:03 2019

Generate corpus to Expand Language Model
- outputs text file of words
Just uses the Callhome Transcripts, but this would need to be a different script for each domain

For example, if transcribing biomedical conversations then I would need to generate a biomedical corpus


@author: Austin Bell
"""

import os, re, sys
import string

def cleanFile(file):
    lines = open(transcription_dir + "/" + file, "r").readlines()

    # begin to clean the file
    lines = lines[8:]
    lines = lines[:-1]
    
    # replace \t \x.\n with blanks, remove &= and speaker identification
    lines = [re.sub(r'[^^a-zA-Z\s{}]'.format(string.punctuation), "", line) for line in lines]
    lines = [re.sub("^\*[A|B]:|\t|\n|\+|&=\w+", "", line) for line in lines]
    
    words = '\n'.join([line for line in lines])
    return words


if __name__ == "__main__":
    
    transcription_dir = sys.argv[1]
    output_dir = sys.argv[2]
    
    files = os.listdir(transcription_dir)
    files = [file for file in files if re.search("cha", file)]
    
    corpus = [cleanFile(file) for file in files]
    '\n'.join([text for text in corpus])
    
    open(output_dir + "/corpus.txt", "w").writelines(corpus)
    
    
