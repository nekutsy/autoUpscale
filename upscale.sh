#!/bin/bash
shopt -s extglob

for i in $(cat variables.txt) ; do declare $i ; done

skipped=0
upscaled=0
frames=($(ls $tmpPath/inFrames))
framesAmount=${#frames[@]}

queue=()
upscale() {
    rm -rf $tmpPath/processed/*
    for j in ${queue[*]} ; do
        cp $tmpPath/inFrames/$j $tmpPath/processed/$j 
        upscaled=$(($upscaled + 1))
    done
    $waifu2x -i $tmpPath/processed -o $tmpPath/outFrames -s 2 -n $noise -j $proc -t 160 -f jpg -m $model 2> /dev/null
    queue=()
}

mkdir -p $tmpPath/inFrames 2> /dev/null
mkdir -p $tmpPath/processed 2> /dev/null
mkdir -p $tmpPath/outFrames 2> /dev/null
mkdir -p $tmpPath/compares 2> /dev/null

preFrame=""
num=1
START_TIME=$(date +%s)

if [[ "$useImageMagick" == "true" ]] ; then
    for i in $(ls $tmpPath/inFrames) ; do
        if [[ $(compare -metric AE -fuzz 5% $tmpPath/inFrames/$preFrame $tmpPath/inFrames/$i -compose src $tmpPath/compares/$i 2>&1) -le 400 ]] ; then
            echo $i skipped
            skipped=$(($skipped+1))
        else
            #echo "$i added to the queue"
            queue+=($i)
            if [[ ${#queue[@]} == $queueLen ]] ; then
                if [[ "$1" = "-v" ]] ; then
                    echo "processing ${queue[*]}"
                else
                    NOW_TIME=$(date +%s)
                    echo -en "\rsegmentNum=$1 framesAmount=$framesAmount framesUpscaled=$upscaled framesSkipped=$skipped progress=$((${num##+(0)} * 100 / $framesAmount))% time=$(($NOW_TIME - $START_TIME))s"
                    num=$(basename -s ".jpg" $i)
                fi
                upscale
            fi
            preFrame=$i
        fi
    done
    upscale
    num=$(basename -s ".jpg" $i)
    NOW_TIME=$(date +%s)
    echo -en "\rsegmentNum=$1 framesAmount=$framesAmount framesUpscaled=$upscaled framesSkipped=$skipped progress=$((${num##+(0)} * 100 / $framesAmount))% time=$(($NOW_TIME - $START_TIME))s"

    preFrame=""
    for i in $(ls $tmpPath/inFrames) ; do
        if [[ ! -f $tmpPath/outFrames/$i ]] ; then 
            cp $tmpPath/outFrames/$preFrame $tmpPath/outFrames/$i
        fi
        preFrame=$i
    done
else
    echo -en "\r                                                                  "
    echo -en "\rsegmentNum=$1 framesAmount=$framesAmount in progress..."
    $waifu2x -i $tmpPath/inFrames -o $tmpPath/outFrames -s 2 -n $noise -j $proc -t 160 -f jpg -m $model 2> /dev/null
    NOW_TIME=$(date +%s)
    echo -en "\r                                                                               "
    echo -en "\rsegmentNum=$1 framesAmount=$framesAmount time=$(($NOW_TIME - $START_TIME))s"
fi