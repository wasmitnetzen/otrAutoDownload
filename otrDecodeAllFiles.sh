#!/bin/bash
if [[ -z "$1" ]]; then
	echo "Please call with ./otrDecodeAllFiles.sh configFolder"
	exit 1
fi

source $1/otr.conf

lockFile="$1/otrDecodeAllFiles.lock"
logFile="$1/otrDecodeAllFiles.log"

if [ -f "$1/otrDecodeAllFiles.lock" ]; then
	echo "otrDecodeAllFiles.sh already running."
        exit 1
fi


touch $lockFile
echo $$ > $lockFile

touch $logFile
echo "Runtime: $(date)" >> $logFile

find $OTRDOWNLOADPATH/*.otrkey 2>/dev/null | while read file; do
    #get media file name, that is, remove the trailing .otrkey
    mediafile=$(echo $(basename $file) | grep -oP ".*[^\.otrkey]")
    # check if resulting file is already in the folder
    if [ -f "$OTROUTPUTPATH/$mediafile" ]
    then
        echo "$mediafile existing, therefore already decoded." >> $logFile
        # check if filename was correctly recorded in save file
        grep "$mediafile" $1/otrDecoded.txt >/dev/null
        RETVAL=$?
        [ $RETVAL -eq 1 ] && echo $mediafile >> $1/otrDecoded.txt
    else
        grep "$mediafile" $1/otrDecoded.txt >/dev/null
        RETVAL=$?
        if [ $RETVAL -eq 1 ]
        then
            echo "Decode $mediafile" >> $logFile
            $1/otrDecode.sh $1 $file >> $logFile
            RETVAL2=$?
            if [ $RETVAL2 -eq 0 ]
            then
                echo "$mediafile successfully decoded." >> $logFile
                echo "$mediafile successfully decoded."
                # tell MQTT
                json=$(printf '{"topic": "otrAutoDownload","measurements": {"decodedFile": "%s"}}' "$mediafile")
                echo "$json" | /home/florin/bin/mqttsend/mqttsend.sh
                echo $mediafile >> $1/otrDecoded.txt
            else
                echo "Error while decoding $mediafile: $RETVAL2" >> $logFile
                echo "Error while decoding $mediafile: $RETVAL2"
		# store nevertheless to avoid multiple decoding attempts
		echo $mediafile >> $1/otrDecoded.txt
            fi
        else
            echo "$mediafile already decoded once." >> $logFile
        fi
    fi
done

/bin/rm $lockFile
