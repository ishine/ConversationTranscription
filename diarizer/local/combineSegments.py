#!/usr/bin/python3
# -*- coding: utf-8 -*-
"""
Created on Wed Nov  6 11:11:25 2019

Combine the segments file based on silences to improve X-vector extraction 

@author: Austin Bell
"""

import re
import sys


def combineSegments(old_segments, threshold, min_segment):
    
    # initialize
    segments = []
    
    prev_start = str(0)
    prev_end = 0
    segment_name = None
    name = None
    
    # combine overlapping segments 
    for i, line in enumerate(old_segments):
        if name == None:
            name = line[1]
        if segment_name == None:
            segment_name = line[0]
        
        start = line[2]
        end = line[3]
            
        # there needs to be some minimum amount silence or the min segment length needs to be reached
        if abs(float(start) - float(prev_end)) > threshold and \
            (abs(float(prev_end)-float(prev_start)) > min_segment or name != line[1]):
            new_line = ' '.join(word for word in [segment_name, name, prev_start, prev_end+"\n"])
            segments.append(new_line)
            
            # define new start
            prev_start = start
            prev_end = end
            segment_name = line[0]
            name = line[1]
            
        # sometimes the file ends before the min segment criter is reached
            
        else:
            prev_end = end
            continue
    
    # handle last one
    segments.append(' '.join(word for word in [segment_name, name, prev_start, prev_end+"\n"]))
    
    return segments
           

if __name__ == "__main__":
    
    # extract args
    data_dir = sys.argv[1]
    threshold = float(sys.argv[2])
    min_segment = float(sys.argv[3])
    
    old_segments = open(data_dir + "/segments", "r").readlines()
    old_segments = [re.sub("\n", "", line).split() for line in old_segments]
    
    segments = combineSegments(old_segments, threshold, min_segment)
    
    with open(data_dir + "/segments", "w") as f:
        f.writelines(segments)
