alias ls="exa -a --icons"
alias la="exa -a --long --icons --header --no-user --git"

alias php74="/opt/homebrew/opt/php@7.4/bin/php"
alias php80="/opt/homebrew/opt/php@8.0/bin/php"

phpmyadmin() {
  docker run --net $1 --rm -e PMA_HOST=$2 -p 8000:80 phpmyadmin
}

mov2gif() {
  out="$(echo $1 | sed 's/\.mov$/\.gif/')"
  max_width="640"
  frames_per_second="10"
  ffmpeg -i $1 -vf "scale=min(iw\,$max_width):-1" -r "$frames_per_second" -sws_flags lanczos -f image2pipe -vcodec ppm - \
    | convert -delay 5 -layers Optimize -loop 0 - "$out" &&
  echo "$(tput setaf 2)output file: $out$(tput sgr 0)" &&
  open -a Google\ Chrome $out
}

# FIND PROCESS
function fp(){
        ps aux | grep -i $1 | grep -v grep
}

# KILL ALL
function ka(){

    cnt=$( fp $1 | wc -l)  # total count of processes found
    klevel=${2:-15}       # kill level, defaults to 15 if argument 2 is empty

    echo -e "\nSearching for '$1' -- Found" $cnt "Running Processes .. "
    fp $1

    echo -e '\nTerminating' $cnt 'processes .. '

    ps aux  |  grep -i $1 |  grep -v grep   | awk '{print $2}' | xargs kill -${klevel}
    echo -e "Done!\n"

#    echo "Running search again:"
#    fp "$1"
#    echo -e "\n"
}


