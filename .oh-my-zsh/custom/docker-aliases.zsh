alias dps="docker ps"
alias dc="docker compose"
alias dcps="docker compose ps"
alias dcl="docker compose logs"

function drun {
  IMG=$1  
  CMD="${2:-bash}"
  RUN_CMD="docker run -ti --rm ${IMG} ${CMD}"
  echo "\033[0;32m$RUN_CMD\033[0m"
  eval $RUN_CMD
}

function dexec {
  CONTAINER=$1
  CMD="${2:-bash}"
  RUN_CMD="docker exec -ti ${CONTAINER} ${CMD}"
  echo "\033[0;32m$RUN_CMD\033[0m"
  eval $RUN_CMD
}

