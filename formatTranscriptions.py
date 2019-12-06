# -*- coding: utf-8 -*-
"""
Created on Sat Nov 30 12:17:01 2019

actions:
- convert decoded text to nice format

@author: Austin Bell
"""


"""
Steps:
    - filter decoded text to just speech lines 
    - stack decoded files 
    - split segment id from the text 
    - split segment id on the first dash (i.e., split on speaker id)
    - sort on the segment id minus speaker id 
    - split the rest of the segment id 
    - for each file
        - append line: formatted start time, formatted end time, speaker, text 
        - ouput text file 
    
"""

import os, re, sys
from time import strftime, gmtime

# function to format timestamp
def formatTime(time_string):
    time_float = float(time_string[0:5] + "." + time_string[5:])
    return strftime("%H:%M:%S", gmtime(time_float))
    
# generate our total set of transcriptions
def extractTranscriptions(raw, decoded_files):
    # combine decoded text
    total_decoded = []
    for file in decoded_files:
        decoded_text = open(raw + "/" + file, "r").readlines()
        decoded_text = [line for line in decoded_text if re.search("^[0-9]+-", line)]
        total_decoded += decoded_text
        
    # split segment id and text 
    total_decoded = [line.split(" ", 1) for line in total_decoded]
    
    # split speaker id from segment id
    total_decoded = [[line[0].split("-",1), line[1]] for line in total_decoded]
    
    # now sort by segment id without speaker id
    sorted_decoded = sorted(total_decoded, key = lambda x: x[0][1])
    return sorted_decoded


if __name__ == "__main__":
    raw = "./results/raw"
    final = "./results/final" # this will be what is returned in the end
    
    #raw = sys.argv[1]
    #final = sys.argv[2]

    # gen file list 
    files = os.listdir(raw)
    decoded_files = [file for file in files if re.search("decode.*.log", file) ]
    
    
    sorted_decoded = extractTranscriptions(raw, decoded_files)
    
    # now let's start going through and outputting 
    prev_file = None
    output = []
    for line in sorted_decoded:
        metadata = line[0]
        text = line[1]
        
        # extract metadata
        speaker = metadata[0]
        filename = metadata[1].split("-")[0]
        start_time = metadata[1].split("-")[1]
        end_time  = metadata[1].split("-")[2]
        
        # format start and end
        start_time = formatTime(start_time)
        end_time = formatTime(end_time)
        
        # generate line
        new_line = "\t".join(s for s in [start_time, end_time, speaker, text])
        
        # start a new file if a new file name is extracted
        if filename != prev_file:

            # export 
            if output != []:
                print(len(output))
                with open(final + "/" + prev_file + "_transcribed.txt", "w") as f:
                    f.writelines(output)
           
            prev_file = filename
            # start new file 
            output = []
            output.append("Start Time (Hour:Min:Secs)\tEnd Time (Hour:Min:Secs)\tSpeaker ID\tTranscribed Text\n")
            
        output.append(new_line)
    
