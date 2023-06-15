#!/bin/bash

for i in $(cat params.txt) ; do declare $i ; done
in=$1
path=$2
name=$3

chekOutput() {
    quit="" ; arg=""
    while [ -n "$1" ] ; do
    case "$1" in
        -q ) quit="true" ;;
        -n ) arg="-n" ;;
    esac
    shift
    done

    if [[ -s $path/log.txt ]] ; then
        echo "undone"
        echo "see output in $path/log.txt"
        exit 1
    else
        if [[ "$quit" != "true" ]] ; then 
            echo "$arg" "done"
        fi
    fi
}

mkdir -p $path/upscaled 2> /dev/null
mkdir -p $path/segments 2> /dev/null
mkdir -p $tmpPath/inFrames 2> /dev/null
mkdir -p $tmpPath/processed 2> /dev/null
mkdir -p $tmpPath/outFrames 2> /dev/null
mkdir -p $tmpPath/compares 2> /dev/null

begin=0
if [ -f $path/startFrom.txt ] ; then
    begin=$(cat $path/startFrom.txt)
    echo processing continues from fragment $begin
else
    rm -rf $path/upscaled/*
    rm -rf $path/segments.txt
    rm -rf $path/segments/*
fi
rm -rf $tmpPath/inFrames/*
rm -rf $tmpPath/outFrames/*

echo "in: $in"
echo "path: $path"
echo "name: $name"
echo resolution: $($ffprobe -v 8 -select_streams v:0 -show_entries stream=width,height -of csv=s=x:p=0 $in)
fps=$(echo "$($ffprobe -v 8 -of csv=p=0 -select_streams v:0 -show_entries stream=r_frame_rate $in)" | tr -d $'\r' | bc -l)
lenght=$($ffprobe -i $in -show_entries format=duration -v 8 -of csv="p=0")
ilenght=${lenght%.*}
echo fps: $fps
echo lenght: $lenght
#echo "chunks amount: ~$(($ilenght / $chunkSize ))"
echo

requestedFps=$(printf "%.0f" "$(bc <<< "$fps + 0.5")")
if [[ "$(printf "%.0f" "$(bc <<< "$fps - 0.5")")" != "$requestedFps" ]] ; then
    if [[ -f "$path/re-encoded" ]] ; then
        echo "video already re-encoded into $requestedFps fps"
        in="$path/$requestedFps$name"
        fps=$requestedFps
    else
        echo -n "re-encoding into $requestedFps fps... "
        ffmpeg -i $in -r 24 -crf 2 $path/$requestedFps$name -v 16 -y 2> $path/log.txt
        chekOutput
        touch "$path/re-encoded"
        in="$path/$requestedFps$name"
        fps=$requestedFps
    fi
fi

segments=($(ls $path/segments))
len=${#segments[@]}

if [[ -f "$path/segmented" ]] ; then
    echo "video already segmented"
else
    echo -n "video segmentation... "
    $ffmpeg -i $in -c copy -f segment -segment_time $chunkSize "$path/segments/%d.mp4" -v 16 2> $path/log.txt
    chekOutput
    segments=($(ls $path/segments))
    len=${#segments[@]}
    touch "$path/segmented"
fi

echo "segments amount: $len"
echo
i=0
for ((i=$begin; i<$len; i++)) ; do
    #echo "processing of chunk$i"
    echo $i > $path/startFrom.txt

    rm -rf $tmpPath/inFrames/*
    rm -rf $tmpPath/outFrames/*

    echo -en "\rdecomposition into frames a segment $i...  "
    $ffmpeg -i $path/segments/$i.mp4 -qscale:v 1 -vsync 0 $tmpPath/inFrames/\%010d.jpg -hide_banner -v 16 -y 2> $path/log.txt
    chekOutput -n

    ./upscale.sh $i 2> $path/log.txt
    chekOutput -q
    echo

    echo -n "assembling a segment $i from frames... "
    $ffmpeg -framerate $fps -i $tmpPath/outFrames/\%010d.jpg -i $path/segments/$i.mp4 -map 0:v -map 1:a -qscale:v 1 $path/upscaled/chunk$i.mp4 -v 16 -y 2> $path/log.txt
    chekOutput -n
    
    echo file upscaled/chunk$i.mp4 >> $path/segments.txt
done
rm -rf $path/startFrom.txt

echo
echo -en "\rassembling a video from segments... "
$ffmpeg -f concat -safe 0 -i $path/segments.txt -c copy $path/$name -y -v 16 2> $path/log.txt
chekOutput
echo -n "deleting video segments... "
rm -rf $path/segments 2> /dev/null
echo "done"