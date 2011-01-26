#!/bin/sh
#

function usage
{
	echo "Usage: pyrex.sh -t <title no> -a <audio id> -c <channels> 
		-r <aspect ratio> [-P profile] -o <output name>"
	echo
	echo -e "Aspect ratio is in the format 16:9 or 4:3\n"
	echo "Profile can be one of; mpeg4, theora+ac3 or theora+vorbis"
	echo "It defaults to; theora+ac3"
	
	exit
}

if [ "$#" -eq 0 ]; then
	usage
	exit
fi

while getopts "t:a:c:r:P:o:" options; do
	case $options in
		t) title=$OPTARG
			;;
		a) aid=$OPTARG
			;;
		c) channels=$OPTARG
			;;
		r) aspect=$OPTARG
			;;
		P) profile=$OPTARG
			;;
		o) name=$OPTARG
			;;
	esac
done

# Validate input
if [[ ! $title ]]; then
	echo "Error: Missing required option -t [dvd title number]"
	usage
fi

if [[ ! $aid ]]; then
	echo "Error: Missing required option -a [dvd audio id]"
	usage
fi

if [[ ! $channels ]]; then
	echo "Error: Missing required option -c [number of audio channels]"
	usage
fi

if [[ ! $aspect ]]; then
	echo "Error: Missing required option -r [aspect ratio]"
	usage
fi

# Set the default profile
if [[ ! $profile ]]; then
	profile="theora+ac3"
elif [[ $profile != "mpeg4" ]] && [[ $profile != "theora+ac3" ]] &&
					[[ $profile != "theora+vorbis" ]]; then
	echo "Error: Unknown profile '$profile'"
	usage
fi

if [[ ! $name ]]; then
        echo "Error: Missing required option -o [dvd title name]"
        usage
fi


#
# Commands
#

# Extract title from DVD
dvd_rip_cmd="nice mplayer dvdnav://$title -aid $aid -channels $channels -dumpstream -dumpfile $name.vob -nocache"

# Extract AC3 audio
extract_ac3_cmd="nice mplayer $name.vob -aid $aid -channels $channels -dumpaudio -dumpfile $name.ac3"

# Convert AC3 into Vorbis
ac3_to_vorbis_cmd="nice ffmpeg -i $name.ac3 -f s16le -acodec pcm_s16le - | oggenc -o $name.oga -q 5 -r -B 16 -C 6 -R 48000 -Q -"

# Encode video (MPEG4/AC3 - AVI)
mpeg4_enc_cmd="nice mencoder $name.vob -aid $aid -vf scale,harddup -zoom -aspect $aspect -xy 720 -o $name.avi -channels $channels -oac copy -ovc lavc -lavcopts vcodec=mpeg4"

# Encode video (Theora/Vorbis - OGV)
ogv_enc_video_cmd="nice ffmpeg2theora -o $name.ogv --no-skeleton -v 7 -a 3 $name.vob"

# Encode video to Ogg Theora
theora_enc_cmd="nice ffmpeg2theora -o $name.ogv --no-skeleton -v 7 $name.vob"

# Mux the video and audio from AVI into a Matroska container
avi_to_mkv_cmd="nice mkvmerge -o $name.mkv $name.avi"

# Mux the Theora video and AC3 audio into a Matroska container
ogv_to_mkv_cmd="nice mkvmerge -o $name.mkv -A $name.ogv $name.ac3"


#
# Profiles
#
# mpeg4 	- mpeg4 + AC3 in an AVI container
# theora+ac3	- Theora + 5.1 AC3 in a Matroska container (default)
# theora+vorbis	- Theora + 2.1 Vorbis in an Ogg container
#

echo "Starting DVD rip using the '$profile' profile."
$dvd_rip_cmd

if [[ $profile = mpeg4 ]]; then
	$mpeg4_enc_cmd
	$avi_to_mkv_cmd
elif [[ $profile = "theora+ac3" ]]; then
	$extract_ac3_cmd
	$theora_enc_cmd
	$ogv_to_mkv_cmd
elif [[ $profile = "theora+vorbis" ]]; then
	$ogv_enc_video_cmd
fi

echo "DVD rip complete."
