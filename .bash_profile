export HISTCONTROL=ignoredups:erasedups  # no duplicate entries
export HISTSIZE=10000.                   # big big history
export HISTFILESIZE=10000                # big big history
shopt -s histappend                      # append to history, don't overwrite it
export LSCOLORS=ExFxBxDxCxegedabagacad
export PATH="/usr/local/sbin:/usr/local/bin:$PATH"
export CLICOLOR=1
export LANG=en_US.UTF-8
export ANDROID_SDK_ROOT=/usr/local/share/android-sdk
export ANDROID_HOME=/usr/local/share/android-sdk
export JAVA_HOME=$(/usr/libexec/java_home)
export NVM_DIR="$HOME/.nvm"
export GREP_OPTIONS='--color=auto'
#export GREP_COLOR='1;30;40'

export WP_CLI_CONFIG_PATH="$HOME/.wp-cli/config.yml"

export COMPOSER_MEMORY_LIMIT=-1

  export LDFLAGS="-L/usr/local/opt/zlib/lib"
  export CPPFLAGS="-I/usr/local/opt/zlib/include"
  export PKG_CONFIG_PATH="/usr/local/opt/zlib/lib/pkgconfig"


# Set prompt - this fixes issue where window title isn't updated after remote ssh disconnect
export PROMPT_COMMAND="history -a; history -n;echo -ne '\033]0;${USER}@${HOSTNAME}\007';$PROMPT_COMMAND"

# Load bash completions
[ -f /usr/local/etc/bash_completion ] && . /usr/local/etc/bash_completion

# Set prompt
PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\] \$ '

#nvm use --silent --lts
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
#[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
#nvm use

#eval "$(rbenv init -)" # This loads rbenv

# Set use colors
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# some more ls aliases
alias ls='ls -alh'
alias df='df -H'
alias du='du -hs *'
alias timestamp='date +%s'
alias his='history | grep -i '
alias mv="mv -v"
alias mv="mv -v" 
alias cp="cp -v"
alias ic="ionic cordova"

alias ngb="nvm use && ng build dev --watch"

#alias sshkey="cat ~/.ssh/id_rsa.pub"
#alias ssh_key="cat ~/.ssh/id_rsa.pub"


#function http_headers() {
#    curl  -D - $@ -o /dev/null
#}
function http_headers(){
#   echo "curl -sSL -D - -o /dev/null $@"
    #curl -sSL -D - -o /dev/null $@
    curl -LI $@
}


function sc() {
  if [ -f bin/console ]; then
    ( bin/console "$@" )
  elif [ -f app/console ]; then
    ( app/console "$@" )
  else
    echo "Error: no symfony console tool found. Are you sure this is a Symfony project directory?"
  fi
}

function sshkey() {
  cat ~/.ssh/id_rsa.pub |pbcopy; echo `pbpaste`;
}

function set_sshkey() {
    echo "Host is $1"
    echo "Password is $2"

    sshkey=$(cat ~/.ssh/id_rsa.pub)

    echo "SSH Key is $sshkey"

    sshpass -p $2 ssh $1 <<-ENDSSH
        mkdir -p .ssh
        #touch .ssh/authorized_keys
        echo -e "$sshkey\n" >> .ssh/authorized_keys
        chmod 0700 .ssh
        chmod 0600 .ssh/authorized_keys
ENDSSH

}

function genpasswd() { 
    pwgen -Bs ${1:-16} 1 |pbcopy; echo `pbpaste`;
}

function mov2gif() {
    mov_filename=$(basename -- "$1")
    #extension="${filename##*.}"
    gif_filename="${filename%.*}.gif"
    echo $mov_filename;
    echo $gif_filename;

    #ffmpeg -i $mov_filename -pix_fmt rgb24 -r 10 -f gif - | gifsicle --optimize=3 --delay=1 > $gif_filename;
    ffmpeg -i $mov_filename -r 10 -f gif - | gifsicle --optimize=3 --delay=1 > $gif_filename;
}

[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm" # Load RVM into a shell session *as a function*
