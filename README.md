# autoUpscale

A small script to increase the video resolution using waifu2x ncnn vulkan. It has optimization for skipping repetitive frames.

## installation

```ffmpeg``` and ```waifu2x-ncnn-vulcan``` are required for use, and ```imagemagick``` is also required when using frame skipping. Before the first run in the file ```params.txt``` you must specify the path to the waifu2x executable file. If ffmpeg or imagemagick are not added to the PATH, you need to specify their path to the executable file.

## usages

The main file is ```useOnVideo.sh``` , it takes 2 parameters: input and output, the rest of the regulation of the script is carried out through a file ```params.txt``` . It sets the parameters of waifu2x, the storage location of temporary files, and the parameters for skipping frames.

### params meanings
| name | meaning |
|-|-|
| waifu2x | path to executable file of waifu2x-ncnn-vulkan |
| model | model what will used for upscale |
| scale | scale value |
| noise | denoise level |
| proc | thread count for load/proc/save can be 1:2,2,2:2 for multi-gpu |
| ffprobe | ffprobe path |
| ffmpeg | ffmpeg path |
| tmpPath | path to directory for temporary files |
| deleteUpscaled | if true, the upscaled frames will be deleted after processing |
| deleteSegments | if true, the upscaled segments will be deleted after processing |
| useImageMagick | if true, then the imagemagick optimization will be applied when using |
| chunkSize | the number of frames in one fragment |
| queueLen | queue lenght |
