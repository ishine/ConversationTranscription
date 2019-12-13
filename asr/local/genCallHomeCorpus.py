#!/usr/bin/env python3
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

# function from before I had LDC version of Callhome Transcripts
def cleanFile(file):
    lines = open(transcription_dir + "/" + file, "r", encoding = "utf-8").readlines()

    # begin to clean the file
    lines = lines[8:]
    lines = lines[:-1]
    
    # replace \t \x.\n with blanks, remove &= and speaker identification
    lines = [re.sub(r'[^^a-zA-Z\s{}]'.format(string.punctuation), "", line) for line in lines]
    lines = [re.sub("^\*[A|B]:|\t|\n|\+|&=\w+", "", line) for line in lines]
    
    words = '\n'.join([line for line in lines])
    return words


if __name__ == "__main__":
    
    transcript_dir = sys.argv[1]
    print(sys.argv)
    output_dir = sys.argv[2]
    
    dirs = ["train", "devtest", "evaltest"]
    #transcript_dir = "./rawData/CallHome/callhome_english_trans_970711/transcrpt"
    
    corpus = []
    for directory in dirs:
        files = os.listdir(transcript_dir + "/" + directory)
        for filename in files: 
    
            lines = open(transcript_dir + "/" + directory + "/" + filename, "r").readlines()
            
            # only keep lines that start with a number and strip lines
            lines = [line.strip().split(": ") for line in lines if re.search("^\d", line)]
            
            
            for line in lines:
                corpus.append(line[1])


    open(output_dir + "/corpus.txt", "w").writelines(corpus)
    
    
