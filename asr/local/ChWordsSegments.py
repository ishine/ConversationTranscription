#!/usr/bin/env python3
# alb2307 - all code created by me
# -*- coding: utf-8 -*-
"""
Created on Wed Dec 11 17:39:26 2019

Create the Callhome Words.txt and Segments file 
Let's hope that I do not have to scale down the time segments so that they start at 0

@author: Austin Bell
"""

import os, re, sys, string 

# confirmed no file overlap  between train, dev, and test

def genLines(filename, line):
    metadata = line[0].split()
    start = metadata[0]
    end = metadata[1]
    speaker = metadata[2]
    
    filename = re.sub("[\.txt|^en_]", "", filename) 
    
    text = line[1]
        
    # callhome text has markers denoting when a word is in another language which we want to remove
    text = re.sub("<\w{1}", "", text)
    text = text.translate(None, "<>()%&&/.?|,")

    # create segment id 
    start_name = re.sub("\.", "", "{:.2f}".format(float(start))).zfill(7)
    end_name = re.sub("\.", "", "{:.2f}".format(float(end))).zfill(7)
    
    segment_id =  speaker + "-" + filename  + "-" + str(start_name) + "-" + str(end_name)
    
    # add to segments file 
    seg_line = " ".join([s for s in [segment_id, filename, str(start), str(end)]]) + "\n"
    
    # add to text file 
    text_line = segment_id + " " + text.lower() + "\n"
    
    return seg_line, text_line



if __name__ == "__main__":
    dirs = ["train", "devtest", "evaltest"]
    #transcript_dir = "./rawData/CallHome/callhome_english_trans_970711/transcrpt"
    transcript_dir = sys.argv[1]
    output_dir = sys.argv[2]

    text_file =[]
    segments = []

    # I want to remove all punctuation except for apostrophes
    punctuation = re.sub("'", "", string.punctuation)
    
    for directory in dirs:
        files = os.listdir(transcript_dir + "/" + directory)
        for filename in files: 
    
            lines = open(transcript_dir + "/" + directory + "/" + filename, "r").readlines()
            
            # only keep lines that start with a number and strip lines
            lines = [line.strip().split(": ") for line in lines if re.search("^\d", line)]
            
            
            for line in lines:
                seg_line, text_line = genLines(filename, line)
                segments.append(seg_line)
                text_file.append(text_line)
    
    open(output_dir + "/text", "w").writelines(text_file) 
    open(output_dir + "/segments", "w").writelines(segments) 
    # hopefully I do not need to scale down to make timestamp start at 0...
                     
           
        
