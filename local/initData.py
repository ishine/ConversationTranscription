#!/usr/bin/env python3
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

def GenWavFile(file_names, file_list):
    wav_file = train_dir + "/wav.scp"
    
    if os.path.exists(wav_file):
        pass
    
    else:
        with open(wav_file, "w") as f:
            for i, (file, path) in enumerate(zip(file_names, file_list)):
                name, ext = os.path.splitext(file)
    
                # if sphere then pip it to wav
                if ext.lower() == ".sph":
                    #f.write(name + " " + sph2pipe + " " + "-f wav -p " + train_dir + "/"+file + " |\n")
                    f.write(name + " sph2pipe -f wav -p " + path + " |\n")
    
                # if wav then just have file name
                if ext.lower() == ".wav":
                    f.write(name + " " + path + "\n")

def GenUtt2Spk(file_names, train_dir):
    Utt2Spk = train_dir + "/utt2spk"
    
    # if the segments file exists then map utt2spk based on segments
    if os.path.exists(train_dir + "/segments"):
        with open(train_dir + "/segments") as segments:
            with open(Utt2Spk, "w") as f:
                for line in segments:
                    name = line.split(" ")[0]
                    f.write(name + " " + name + "\n")
                    
                    
    else: # otherwise just map recording id to recording id
        with open(train_dir + "/wav.scp") as wav:
            with open(Utt2Spk, "w") as f:
                for line in wav:
                    #name, _ = os.path.splitext(file)
                    name = line.split(" ")[0]
                    f.write(name + " " + name + "\n")
            


if __name__ == "__main__":
    import sys
    import os
    from glob import glob
    import re
    
    data_dir = sys.argv[1]
    train_dir = sys.argv[2]
    #data_dir = "./data/amicorpus"
    #train_dir = "./data/train"
    
    # given a data directory, recursively walk and identify any audio files 
    file_types = ['flac', 'aiff', 'wav', 'mp4', 'ogg']
    file_list = GetFileList(data_dir,file_types)
    
    
    # convert to format needed by Kaldi
    file_names =  [os.path.basename(file) for file in file_list]
       
    # generate training directory if it does not exist
    if not os.path.exists(train_dir):
        os.makedirs(train_dir)
    
    GenWavFile(file_names, file_list)
    
    print("wav file successfully created and exported")
   
    # generate utt2spk
    GenUtt2Spk(file_names, train_dir)
    print("utt2spk file successfully created")

    
    
    
