#!/bin/bash

# deps: mpv awk sed grep lynx

# Colors
invi=$(tput civis)
visi=$(tput cnorm)
c_orange=$(tput setaf 221)
c_green=$(tput setaf 193)
c_green2=$(tput setaf 76)
c_yellow=$(tput setaf 184)
c_red=$(tput setaf 52)
bold=$(tput bold)
reset=$(tput sgr0)

# Variables
crunchy="http://www.crunchyroll.com"
dir="$HOME/.local/share/crcli"
shows="$HOME/.local/share/crcli/.listashows.txt"

# MPV
player='setsid -f mpv
	--x11-name=crcli
	--save-position-on-quit
	--slang=enUS)'

# Functions
about_show () {
# Getting info about the show
	lynx -dump "$crunchy"/"$nombre" \
	| sed -n '/About the Show/,/User Rating/p' \
	| sed 's/\s\.*\s\[[0-9]*]more$//g;s/\%/ percent/g' \
	| grep -v -e "*" -e "Simulcast"
}

enumerate_color () {
# even odd colouring
	for (( i=1; i<=$1; ++i )); do
		if (( i % 2 == 0 )) ; then
			printf "${c_orange}"
			echo "$2" \
			| head -"$i" \
			| tail +"$i" \
			| sed "s/^/  [$i] /g"
		else
			printf "${c_green}"
			echo "$2" \
			| head -"$i" \
			| tail +"$i" \
		        | sed "s/^/  [$i] /g"
		fi
	done
}

check_deps () {
	for dep; do
		if ! command -v "$dep" >/dev/null ; then
			terminate "\"$dep\" is missing."
		fi
	done
}

terminate () {
	printf "$*" >&2
	exit 1
}

extract_from_url () {
	lynx -dump -listonly -nonumbers "$1" \
	| cut -d "/" -f 4
}

input_control () {
[[ "$1" == $contarShows ]] && follow=menu_watch \
		              follow2=watch_directory \
			   || follow=description_anime \
			      follow2=trending_menu

[[ "$1" == $contar ]] && follow2=menu_search

	if [[ $1 -gt $2 && $2 -ge 1 ]] ; then
		$follow
	elif [[ $2 = b ]] ; then
		clear
		menu_ppal
	else
		echo "Please enter a valid input."
	$follow2
	fi
}

####################
#  MENU FUNCTIONS  #
####################

menu_ppal ()
{
while :
do
  clear
  cat<<EOF
  crcli's menu
  ============
  [s] search
  [w] watch
  [r] regshows
  [q] exit
  ${invi}
EOF
	read -n1
	case $REPLY in
	s)
	clear
	menu_selection;;
	w)
	clear
	watch_directory;;
	r)
	clear
	extract_from_url "$crunchy"/videos/anime/alpha?group=all > "$shows"
	printf "Done."
	sleep 1;;
	q)
	clear
	exit;;
	*)
	printf "Invalid input.";;
	esac
done
}

menu_search ()
{
clear
printf "There are [$(echo "$showst" | wc -l)] shows on the database.\n\n"
echo "Enter keyword(s) or press [Return] to see the whole list: ${visi}"
read busqueda

# Adding - to query so it matches
busqueda=$(echo "$busqueda" \
	| tr '[:upper:]| ' '[:lower:]|-')

# Counting and greping the show
contar=$(echo "$showst" \
	| grep "$busqueda" | wc -l)

# Checking that its not null
[ -z "$(echo "$showst" | grep "$busqueda")" ] && \
	clear \
	echo "Nothing found!" \
	sleep 1 \
	clear \
	menu_search

# Enumerating
query=$(echo "$showst" | grep "$busqueda")
enumerate_color $contar "$query"

printf "\n${reset}Enter [num] or [b] to go back: "
read

# Getting the show URL
nombre=$(cat "$shows" \
	| grep "$busqueda" \
	| head -"$REPLY" \
	| tail +"$REPLY" \
	| sed "s/\[.\] //g")

# Controlling that user input is not higher or lesser than
# than max/min of matched items
input_control $contar $REPLY
}

description_anime ()
{
clear
printf "About [${c_orange}"$nombre"${reset}]${c_orange}:\n\n"
about_show
# Rating calculation var
rating="$(lynx -dump "$crunchy"/"$nombre" \
	| sed -n '/User Rating/,/Read/p' \
	| grep -v -e "Read" -e "*" -e Average \
	| sed 's/(//g;s/)//g;s/\s//g' \
	| tr '\n' ' ' \
	| awk '{printf ($1 * 5 + $2 * 4 + $3 * 3 + $4 * 2 + $5) / ($1 + $2 + $3 + $4 + $5)}' \
	| sed 's/...$//g')"

	# Printing rating with colors
	if awk -v x=$rating -v y=3.8 'BEGIN { exit (x < y) ? 0 : 1 }' ; then
		printf "\t(${c_yellow}*${reset}) User Rating: ${c_yellow}$rating\n"
	elif awk -v x=$rating -v y=2 'BEGIN { exit (x < y) ? 0 : 1 }' ; then
		printf "\t(${c_red}*${reset}) User Rating: ${c_red}$rating\n"
	else
		printf "\t(${c_green2}*${reset}) User Rating: ${c_green2}$rating\n"
	fi

cat<<EOF
  ${reset}
  Generate
  ========
  [1] normal method
  [2] inverted method
  Press [n] or go back [any]${invi}
EOF
nombreproc=$(echo "$nombre" \
	| tr '-' ' ' \
	| sed -e "s/\b\(.\)/\u\1/g")

	read -n1 -s
	case $REPLY in
	# Method 1
	1)
	mkdir "$dir"/"$nombreproc" 2> /dev/null ; \

	lynx -dump -listonly -nonumbers "$crunchy"/"$nombre" \
	| grep episode \
	| awk -F'......$' '!seen[$(NF-1)]++' \
	| tac > "$dir"/"$nombreproc"/fullepisodes.txt

	clear
	printf "Successfully generated.\n"
	sleep 1
	watch_directory;;
	2)
	mkdir "$dir"/"$nombreproc" 2> /dev/null

	lynx -dump -listonly -nonumbers "$crunchy"/"$nombre" \
	| grep episode \
	| tac \
	| awk -F'......$' '!seen[$(NF-1)]++' \
	> "$dir"/"$nombreproc"/fullepisodes.txt

	clear
	printf "Successfully generated.\n"
	sleep 1
	watch_directory;;
	*)
	clear
	menu_selection;;
	esac
}

watch_directory ()
{
# Counting total shows
contarShows=$(ls "$dir" | wc -l)
dirEcho=$(ls "$dir")

clear
echo "  My list"
echo "  ======="
# Function to color and index shows
enumerate_color $contarShows "$dirEcho"

printf "\n${reset}Enter [num] or [b] to go back: ${visi}"
read iComeFromIndex

# Getting the show from the crcli's directory
serie=$(ls "$dir" \
	| head -"$iComeFromIndex" \
	| tail +"$iComeFromIndex" \
	| sed "s/\[.\] //g")

input_control $contarShows $iComeFromIndex
}

menu_watch () {
clear
cat<<EOF
  ${invi}$serie has [$(cat "$dir"/"$serie"/fullepisodes.txt | wc -l)] episodes.
  =====================
  [1] full or resume
  [2] watch one ep
  [3] start from ep
  [4] play range of eps
  Press [num]
EOF
	read -n1 selectPlayer
	case $selectPlayer in
	# Watch full or resume
	1)
	clear
	$player --playlist="$dir"/"$serie"/fullepisodes.txt \
	        > /dev/null 2>&1;;
	# Single episode
	2)
	clear
	printf "Select ep to watch: ${visi}"
       	read epi
	$player "$(head -"$epi" "$dir"/"$serie"/fullepisodes.txt | tail +"$epi")" \
		> /dev/null 2>&1;;
	# Start from episode
	3)
	clear
	printf "Select ep to start from: ${visi}"
	read epi
	$player --playlist-start="$(( epi - 1 ))" \
		--playlist="$dir"/"$serie"/fullepisodes.txt \
		> /dev/null 2>&1;;
	# Range of episodes
	4)
	clear
	printf "Start at: ${visi}"
	read epis
	printf "End at: ${visi}"
	read epie
	head -"$epie" "$dir"/"$serie"/fullepisodes.txt \
	| tail +"$epis"
	> "$dir"/"$serie"/templist.txt \
	$player --playlist="$dir"/"$serie"/templist.txt \
		> /dev/null 2>&1;;
	*)
	menu_watch;;
	esac
}

menu_selection ()
{
while :
do
  clear
  cat<<EOF
  Search menu
  ===========
  [s] search
  [t] trending
  [r] random
  [any] back
EOF
	read -n1 -s
	case $REPLY in
	s) menu_search;;
	t) trending_menu;;
	r) random_menu;;
	*) menu_ppal;;
	esac
done
}

trending_menu ()
{
# Getting the shows
trending=$(extract_from_url "$crunchy"/videos/anime/popular \
	| grep -v videos \
	| sed -n '/simulcastcalendar/,/simulcastcalendar/p' \
	| head -n -7 \
	| tail -n +2)

# Counting the shows
contarTrending=$(echo "$trending" | wc -l)

clear
echo "  Trending Shows"
echo "  =============="
# Function to color/list the shows
enumerate_color $contarTrending "$trending"
printf "${reset}\nEnter [num] or [b]: "
read iComeFromTrending

# User selection
nombre=$(echo "$trending" \
	| head -"$iComeFromTrending" \
	| tail +"$iComeFromTrending" \
	| sed "s/\[.\] //g")

input_control $contarTrending $iComeFromTrending
}

random_menu ()
{
# Generating random n
randomnum=$(shuf -i 1-"$(echo "$showst" | wc -l)" -n 1)

# Same n on head & tail, cutting the URL from the showslist
nombre=$(echo "$showst" \
	| head -"$randomnum" \
	| tail +"$randomnum" \
       	| sed "s/\[.\] //g")

clear
printf "Selected: "$nombre".\n\n Accept [a], re-roll [r] or back [b]."
	read -n1 -s
	case $REPLY in
	a) description_anime;;
	r) random_menu;;
	b) menu_selection;;
	*) random_menu;;
	esac
}

#########
# START #
#########

check_deps "mpv" "lynx" "sed" "awk"

[ ! -d "$dir" ] && mkdir "$dir"
[ ! -f "$shows" ] && extract_from_url "$cruncy"/videos/anime/alpha?group=all > "$shows"
showst=$(sed -n '/^[0-9]/,/^z./p' "$shows" | grep -v -e '/\|:\|&\|%')

menu_ppal
