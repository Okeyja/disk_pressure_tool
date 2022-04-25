#!/bin/bash

# Help Docs
function MainHelp(){
   # Display Main Help
   echo "Presuring and collection your disk data."
   echo
   echo "Syntax: $0 action target [opts:-t|-n]"
   echo
   echo "actions:"
   echo "    read          executing a sequantial read task with fio."
   echo "    write         executing a sequantial write task with fio."
   echo "    rw            executing a task that mixing read and write"
   echo "                  with fio."
   echo "    randread      executing a random read task with fio."
   echo "    randwrite     executing a random write task with fio."
   echo "    randrw        executing a task that mixing random read and"
   echo "                  random write with fio."
   echo "    collect       collecting disk data with iostat command."
   echo "    help          print this help."
   echo
}

function PressureHelp(){
   # Display Pressure Help
   echo "Presuring and collection your disk data."
   echo
   echo "Syntax: $0 $1 block [opts:-t|-n]"
   echo 
   echo "options:"
   echo "    -t, --try-times     fio try times, default: 100."
   echo "    -n, --name          fio task name, default: \"mytest\"."
   echo "    -h, --help          print this help."
   echo 
   echo "example:"
   echo "    $0 $1 /dev/sda -t 100 -name \"mytest1\""
   echo
}

function CollectHelp(){
   # Display Pressure Help
   echo "Presuring and collection your disk data."
   echo
   echo "Syntax: $0 collect block [opts:-o|-r]"
   echo 
   echo "options:"
   echo "    -o, --output-file   output log file, default: out.txt"
   echo "    -r, --rows          rows of data that you need to collect."
   echo "    -h, --help          print this help."
   echo
   echo "examples:"
   echo "    $0 collect sda"
   echo "    $0 collect sda -o sda-randread.txt"
   echo
}


function doPressure() {
        # 模式参数
        MODE="$1"
        shift # remove action(MODE)

        # 必位参数
        BLOCK_DIR="$1"
        shift # remove block(BLOCK_DIR)
        if [[ $BLOCK_DIR == "" ]] ;
        then
            PressureHelp
            echo "error: $MODE block parameter required."
            exit 3
        fi
        if [[ $BLOCK_DIR == -* ]] ;
        then
            PressureHelp
            echo "error: invalid block parameter."
            exit 2
        fi

        # 选填参数
        MAXTRY=100
        NAME="mytest"
        for arg in "$@"
        do
            case $arg in
                -t|--try-times)
                    MAXTRY=$2
                    shift # Remove arg key
                    shift # Remove arg val
                ;;

                -n|--name)
                    NAME=$2
                    shift # Remove arg key
                    shift # Remove arg val
                ;;

                -h|--help)
                    PressureHelp
                    exit 0
                ;;
            esac
        done

        # 意外参数：屏蔽
        for arg in "$@"
        do
            case $arg in
                *)
                    PressureHelp $MODE
                    echo "error: argument \"$arg\" not allowed."
                    exit 2
                ;;
            esac
        done

        for ((i=0;i<$MAXTRY;i++))
        do
            fio -filename="$BLOCK_DIR" \
            -direct=1 \
            -iodepth 1 \
            -thread \
            -rw="$MODE" \
            -ioengine=psync \
            -bs=16k \
            -size=10G -numjobs=30 -runtime=1000 -group_reporting -name=$NAME
        done
}

function doCollect() {

        # 盘参数
        BLOCK="$1"
        shift # remove action(MODE)

        if [[ $BLOCK == -* ]] ;
        then
            CollectHelp
            echo "error: invalid block name"
            exit 2
        fi

        # 选填参数
        OUTPUT_FILE="out.txt"
        ROWS=100
        for arg in "$@"
        do
            case $arg in
                -o|--output-file)
                    OUTPUT_FILE=$2
                    shift # Remove arg key
                    shift # Remove arg val
                ;;
                
                -r|--rows)
                    ROWS=$2
                    shift # Remove arg key
                    shift # Remove arg val
                ;;

                -h|--help)
                    CollectHelp
                    exit 0
                ;;
            esac
        done

        # 意外参数：屏蔽
        for arg in "$@"
        do
            case $arg in
                *)
                    CollectHelp
                    echo "error: argument \"$arg\" not allowed."
                    exit 2
                ;;
            esac
        done

        iostat -x 1 $ROWS | awk "/$BLOCK/" > "$OUTPUT_FILE"
}

# 动作参数：提取首参数，在枚举中比对，如果没有或为超出枚举的值，则不允许执行。
case $1 in
    read|write|rw|randread|randwrite|randrw)
        doPressure $@
        exit 0
    ;;

    collect)
        shift # remove mode name(collect)
        doCollect $@
        exit 0
    ;;

    help)
        MainHelp
        exit 0
    ;;

    "")
        MainHelp
        echo "error: action required."
        exit 1
    ;;

    *)
        MainHelp
        echo "error: invalid action \"$1\"."
        exit 1
    ;;
esac
