# Transcribe Conversational Speech

Scripts and directory related to tool that transcribes conversational speech.  Takes as conversational speech files as input and returns formatted transcribed and diarized conversation.  A single text file is returned per speech file.  Subsequent data mining can then be performed on returned text files. 

## Tool Structure and Script Details 

~/ : home directory responsible for running all other scripts, storing results, and data
 * transcribe_conversations.sh: bash script that runs the entire process from start to finish.  
   * Mandatory inputs: directory to raw speech files; name of desired output directory; number of speakers in file ("unknown" is also an option)
   * Optional inputs: whether to expand the language model with additional words; corpus to use for language model expansion 
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
 * 
asr/ : folder containing all scripts and tools related to automatic speech recognition
