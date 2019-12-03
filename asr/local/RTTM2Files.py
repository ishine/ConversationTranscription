#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Sat Nov 30 12:17:01 2019

Converts RTTM file format to segments file

@author: Austin Bell
"""

if __name__ == "__main__":
    import sys, re
    input_dir = sys.argv[1]

    rttm = open(input_dir+ "/rttm").readlines()

    rttm = [r.split() for r in rttm]
    rttm_seg = [[r[1], round(float(r[3]),2), round(float(r[4]),2), r[7]] for r in rttm]

    new_segments = []
    utt2spk = []
    for seg in rttm_seg:
        filename = seg[0]
        start = seg[1]
        duration = seg[2]
        end = start + duration
        speaker = seg[3]

        # create segment id and line
        start_name = re.sub("\.", "", "{:.2f}".format(float(start))).zfill(7)
        end_name = re.sub("\.", "", "{:.2f}".format(float(end))).zfill(7)
        segment_id = speaker + "-" + filename + "-" + str(start_name) + "-" + str(end_name)
          
        line = " ".join([s for s in [segment_id, filename, str(start), str(end)]]) + "\n"
        new_segments.append(line)

        # append to utt2spk
        utt2spk.append(segment_id + " " + segment_id + "\n")

    with open(input_dir + "/segments", "w") as f:
        f.writelines(new_segments)
        print("generated Segments")

    with open(input_dir + "/utt2spk", "w") as f:
        f.writelines(utt2spk)
        print("generated Utt2spk")
