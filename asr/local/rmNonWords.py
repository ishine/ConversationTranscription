#!/usr/bin/env python3
# alb2307 - all code created by me
# -*- coding: utf-8 -*-
"""
Created on Fri Dec 13 17:17:24 2019

removes non-word speech from our ground truth text and best path files prior to scoring
- find anything that matches [.*] and {.*} and remove the whole group

@author: Austin Bell
"""

import sys, os, re



def rmNonWords(file, directory):
    lines = open(directory + "/" + file, "r").readlines()

    cleaned_lines =[]
    # start cleaning the lines
    for line in lines:
        if re.search("^[0-9]", line):
            line = re.sub("\{.*\}|\[.*\]", "", line)
        cleaned_lines.append(line)
        
    return cleaned_lines


if __name__ == "__main__":
    
    #scoring_dir = "."
    #text_dir = "."
    
    scoring_dir = sys.argv[1]
    text_dir = sys.argv[2]
    
    scoring_files = os.listdir(scoring_dir)
    best_path_files = [file for file in scoring_files if re.search("best", file)]

    # first clean text
    cleaned_text = rmNonWords("text", text_dir)
    open(text_dir + "/text", "w").writelines(cleaned_text)
    
    # now clean the best path files
    for file in best_path_files:
        cleaned_best_path = rmNonWords(file, scoring_dir)
        open(scoring_dir + "/" + file, "w").writelines(cleaned_best_path)

