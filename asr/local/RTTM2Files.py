#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Sat Nov 30 12:17:01 2019

Converts RTTM file format to segments file

@author: Austin Bell
"""

import sys, re
rttm_dir = sys.argv[1]

rttm = open(rttm_dir+ "/rttm").readlines()

rttm = [r.split() for r in rttm]
rttm_seg = [[r[1], round(float(r[3]),2), round(float(r[4]),2), r[7]] for r in rttm]

new_segments = []
utt2spk = []
for seg in rttm_seg:
    filename = seg[0]
    start = seg[1]
    duration = seg[2]
    end = start + duration
    
    # create segment id and line
    start_name = re.sub("\.", "", str(start)).zfill(7)
    end_name = re.sub("\.", "", str(end)).zfill(7)
    segment_id = speaker + "_" + filename + "_" + str(start_name) + "-" + str(end_name)
          
    line = " ".join([s for s in [segment_id, filename, str(start), str(end)]]) + "\n"
    new_segments.append(line)

    # append to utt2spk
    utt2spk.append(segment_id + " " + speaker + "\n")

with open(input_dir + "/segments", "w") as f:
    f.writelines(new_segments)

with open(input_dir + "/utt2spk", "w") as f:
    f.writlines(utt2spk)
