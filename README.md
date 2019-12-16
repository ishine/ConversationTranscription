# Transcribe Conversational Speech

Scripts and directory related to tool that transcribes conversational speech.  Takes as conversational speech files as input and returns formatted transcribed and diarized conversation.  A single text file is returned per speech file.  Subsequent data mining can then be performed on returned text files. 

## Tool Structure and Script Details 

~/ : home directory responsible for running all other scripts, storing results, and data
 * transcribe_conversations.sh: bash script that runs the entire process from start to finish.  
   * Mandatory inputs: directory to raw speech files; name of desired output directory; number of speakers in file ("unknown" is also an option)
   * Optional inputs: threshold for clustering PLDA scores when number of speakers is unknown; whether to expand the language model with additional words; corpus to use for language model expansion 
   * Steps:
     * Resets all directories (Kaldi will not re-write files if they exist)
     * Run Diarization
     * Run Speech Recognition (with possible language model expansion)
     * Format results into nice text files 
     
 * formatTranscriptions.py: formats results into user readable text files that are diarized and transcribed
   * Mandatory input: output directory
   * Process: 
     * parse decoded results and split into separate files
     * parse speaker information, time stamps, and text  
 
diarizer/ : folder containing all scripts and tools related to speaker diarization
 * run_diarization.sh: primary script for running the diarization process
   * Mandatory inputs: number of speakers ("unknown" is an option)
   * Optional inputs: threshold for clustering of PLDA scores 
   * Process:
     * Generate the segments file using an energy based speech activity detection algorithm 
     * Once segments file has been created then generate other features (MFCC)
     * Extract X-vectors from trained X-Vector model
     * Score PLDA 
     * Cluster PLDA scores to complete diarization (able to select number of speakers or select an unknown number of speakers)
     * export diarization results for use in ASR system
     
 *  local/initData.py: initialize data inputs for use in diarization
   * Mandatory Inputs: input directory; output directory
   * Process: 
     * Generates wav.scp and utt2spk leveraging and all speech files in the input directory 
     * outputs wav.scp and utt2spk in output data directory
     * ensure that speech files are processed correctly (16,000 hz, monophone, 16 bits, wav)
     
 * local/combineSegments.py: Combines short segments
   * Mandatory Inputs: segments directory
   * process:
     * Sometimes the segments that are created from energy-based SAD system are too long for proper X-vector extraction
     * identifies the segments that are too short and combines them with the succeeding segment
     * outputs new segments file
 
asr/ : folder containing all scripts and tools related to automatic speech recognition
 * 
