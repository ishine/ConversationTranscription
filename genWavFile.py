# -*- coding: utf-8 -*-
"""
Created on Tue Oct 15 18:39:15 2019

Generates WAV bash file for Kaldi 
See format here: http://kaldi-asr.org/doc/data_prep.html


Currently, developed for the AMI Corpus, but should work given any directory of audio files

Args:
    Argument 1: data source directory
    Argument 2: Training directory

@author: Austin Bell
"""

def GetFileList(data_dir, file_types):
        
    """
    Returns the complete file list of all files matching a file type in user provided file types
    recursively walks through folders
    """
    
    file_list = []
    
    # extracts all files with an audio extension
    for file_type in file_types:
        file_paths = [file for path in os.walk(data_dir) for file in glob(os.path.join(path[0], '*.' + file_type))]
        file_list += file_paths
        
    file_list = [re.sub("\\\\", "/", file) for file in file_list]
    return file_list

def GenWavFile(file_names, file_list, sph2pipe, train_dir):
    wav_file = train_dir + "/wav.scp"
    with open(wav_file, "w") as f:
        for i, (file, path) in enumerate(zip(file_names, file_list)):
            name, ext = os.path.splitext(file)
            f.write(name + " " + sph2pipe + " " + "-f wav -p -c " + str(i) + train_dir + "/"+file + "|\n")
        


if __name__ == "__main__":
    import sys
    import os
    from glob import glob
    import re
    
    data_dir = sys.argv[1]
    train_dir = sys.argv[2]
    #data_dir = "./data/amicorpus"
    train_dir = "./data/train"
    
    # given a data directory, recursively walk and identify any audio files 
    file_types = ['flac', 'aiff', 'wav', 'mp4', 'ogg']
    file_list = GetFileList(data_dir,file_types)
    
    
    # convert to format needed by Kaldi
    file_names =  [os.path.basename(file) for file in file_list]
    sph2pipe = "/home/dpovey/kaldi-trunk/tools/sph2pipe_v2.5/sph2pipe" # unsure if this is correct
    
    # generate training directory if it does not exist
    if not os.path.exists(train_dir):
        os.makedirs(train_dir)
    
    GenWavFile(file_names, file_list, sph2pipe, train_dir)
    
    print("wav file successfully created and exported")
    
    
    
    