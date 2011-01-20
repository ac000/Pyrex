#!/bin/sh
#

function usage
{
	echo "Usage: pyrex.sh -t <title no> -a <audio id> -c <channels> 
			-r <aspect ratio> -o <title name>"
	echo
	echo "Aspect ratio is in the format 16:9 or 4:3"
	
	exit
}

if [ "$#" -eq 0 ]; then
	usage
	exit
fi


while getopts t:a:c:r:o: options; do
	case $options in
		t) title=$OPTARG
			;;
		a) aid=$OPTARG
			;;
		c) channels=$OPTARG
			;;
		r) aspect=$OPTARG
			;;
		o) name=$OPTARG
			;;
	esac
done


# Validate input
if [ ! $title ]; then
	echo "Error: Missing required option -t [dvd title number]"
	usage
fi

if [ ! $aid ]; then
	echo "Error: Missing required option -a [dvd audio id]"
	usage
fi

if [ ! $channels ]; then
	echo "Error: Missing required option -c [number of audio channels]"
	usage
fi


if [ ! $aspect ]; then
	echo "Error: Missing required option -r [aspect ratio]"
	usage
fi

if [ ! $name ]; then
        echo "Error: Missing required option -o [dvd title name]"
        usage
fi


#
# MPEG4 + AC3 in Matroska
#

# Extract title from DVD
#cmd1="nice mplayer dvdnav://$title -aid $aid -channels $channels -dumpstream -dumpfile $name.vob -nocache"
#echo Executing: $cmd1
#$cmd1

# Convert AC3 into Vorbis
##nice ffmpeg -i $name.ac3 -f s16le -acodec pcm_s16le - | oggenc -o $name.oga -q 5 -r -B 16 -C 6 -R 48000 -Q -

# Encode video (MPEG4/AC3 - AVI)
#cmd3="nice mencoder $name.vob -aid $aid -vf scale,harddup -zoom -aspect $aspect -xy 720 -o $name.avi -channels $channels -oac copy -ovc lavc -lavcopts vcodec=mpeg4"
#echo Executing: $cmd3
#$cmd3


# Mux the video and audio into a Matroska container
#cmd4="mkvmerge -o $name.mkv -A $name.avi $name.ac3"
#cmd4="nice mkvmerge -o $name.mkv $name.avi"
#echo Executing: $cmd4
#$cmd4

#echo "DVD rip complete."



#
# Ogg Theora + AC3 in Matroska
#

# Extract title from DVD
cmd1="nice mplayer dvdnav://$title -aid $aid -channels $channels -dumpstream -dumpfile $name.vob -nocache"
echo Executing: $cmd1
$cmd1

# Extract AC3 audio
cmd2="nice mplayer $name.vob -aid $aid -channels $channels -dumpaudio -dumpfile $name.ac3"
echo Executing: $cmd2
$cmd2

# Encode video to Ogg Theora
cmd3="nice ffmpeg2theora -o $name.ogv --no-skeleton -v 7 $name.vob"
echo Executing: $cmd3
$cmd3

# Mux the video and audio into a Matroska container
#cmd4="mkvmerge -o $name.mkv -A $name.avi $name.ac3"
cmd4="nice mkvmerge -o $name.mkv -A $name.ogv $name.ac3"
echo Executing: $cmd4
$cmd4

echo "DVD rip complete."

