# autoUpscale

A small script to increase the video resolution using waifu2x ncnn vulkan. It has optimization for skipping repetitive frames.

## installation

ffmpeg and waifu2x-ncnn-vulcan are required for use, and imagemagick is also required when using frame skipping. Before the first run in the file params.txt you must specify the path to the waifu2x executable file. If ffmpeg or imagemagick are not added to the PATH, you need to specify their path to the executable file.

## usages

The main file is useOnVideo.sh , it takes 2 parameters: input and output, the rest of the regulation of the script is carried out through a file params.txt . It sets the parameters of waifu2x, the storage location of temporary files, and the parameters for skipping frames. chunkSize - the approximate time of a video fragment processed at a time. queueLen - the number of frames processed at a time when applying a frame pass, it is recommended to specify large values.
