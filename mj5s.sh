################################ GLOBALS ################################
__args=()
__args_i=0
__func=""
__urls=()
declare -A __context_args
declare -A __func_args
declare -A __services

################################ LOG ##################################
log() {
  echo -e "\e[34m[LOG]\e[0m\t[${FUNCNAME[1]}]\t" "$@"
}

debug() {
  echo -e "\e[32m[DEBUG]\e[0m\t[${FUNCNAME[1]}]\t" "$@"
}

warn() {
  echo -e "\e[33m[WARN]\e[0m\t[${FUNCNAME[1]}]\t" "$@"
}

error() {
  echo -e "\e[31m[ERROR]\e[0m\t[${FUNCNAME[1]}]\t" "$@"
}

label() {
  echo -e "################################ $1 ################################"
}

LOG_LEVEL=log
case $LOG_LEVEL in
debug)
  alias log=':'
  ;;
log)
  alias debug=':'
  ;;
off)
  alias log=':'
  alias debug=':'
  ;;
esac

################################ URLS ################################
__urls=(
  git@github.com:Noman5237/repo-test-1.git
  git@github.com:Noman5237/repo-test-2.git
)

################################ REPOS ################################
for url in "${__urls[@]}"; do
  repo_name=$(echo "$url" | awk -F/ '{print $NF}' | sed 's/.git//')
  __services["$repo_name"]="$url"
done

################################ FUNCTIONS ################################
_service() {
  # remove all the services that are not in __func_args[only]
  local selected_services=()
  local excepted_services=()
  # parse comma separated values in __func_args[only] to an array
  IFS=',' read -r -a selected_services <<<"${__func_args[only]}"
  # parse comma separated values in __func_args[except] to an array
  IFS=',' read -r -a excepted_services <<<"${__func_args[except]}"

  # show error if any selected __service is not in __services
  for selected_repo in "${selected_services[@]}"; do
    if [ -z "${__services[$selected_repo]}" ]; then
      error "Invalid service: $selected_repo"
      # remove the invalid __service from selected_services
      selected_services=("${selected_services[@]/$selected_repo/}")
    fi
  done

  # if selected_services is not empty
  if [ ! "${#selected_services[@]}" -eq 0 ]; then
    # remove all the services that are not in selected_services
    for __service in "${!__services[@]}"; do
      local found=false
      for selected_repo in "${selected_services[@]}"; do
        if [[ "$__service" == "$selected_repo" ]]; then
          found=true
          break
        fi
      done
      if [ "$found" == false ]; then
        debug "unsetting $__service"
        unset __services["$__service"]
      fi
    done
  fi

  # remove all the repos that are in excepted_services
  for __service in "${excepted_services[@]}"; do
    debug "unsetting $__service"
    unset __services["$__service"]
  done

  # print all the selected repos
  debug "selected services:" "${!__services[@]}"
}

clone() {
  # if force is unset, set it to false
  if [ -z "${__func_args[force]}" ]; then
    debug "force is unset, setting it to false"
    __func_args[force]=false
  fi
  local force="${__func_args[force]}"
  debug "force: $force"

  # clone each url if directory doesn't exist
  # if directory doesn't exist and force is false, clone the __service
  if [ "$force" == true ]; then
    log "force cloning $__service"
    rm -rf "$__service"
    git clone "${__services[$__service]}"
  elif [ ! -d "$__service" ]; then
    log "cloning $__service"
    git clone "${__services[$__service]}"
  else
    log "service $__service already exists!"
  fi
}

fetch() {
  # go to each directory and pull all branches
  # if directory doesn't exist and clone is true, clone the __service
  if [ ! -d "$__service" ]; then
    error "service $__service not found locally!"
    return
  fi
  cd "$__service" || return
  log "fetching $__service"
  git fetch --all
  cd ..
}

checkout() {
  # go to each directory and switch to the branch
  local branch="${__func_args[branch]}"

  cd "$__service" || return
  log "checking out branch on $__service to $branch"
  git checkout "$branch" || error "failed to checkout branch on $__service to $branch"
#  git switch -c "$branch" || error "failed to switch branch on $__service to $branch"
  cd ..
}

remote() {
  cd "$__service" || return
  local name="${__func_args[name]:-origin}"
  local url="${__func_args[url]}"

  if git remote | grep -q "^$name$"; then
    # Remote exists, set the URL
    git remote set-url "$name" "$url" || echo "not set"
  else
    # Remote doesn't exist, add it
    git remote add "$name" "$url" || echo "not add"
  fi
  cd ..
}

merge() {
  # go to each directory and merge the branch
  local branch="${__func_args[branch]}"

  cd "$__service" || return
  log "merging branch on $__service to $branch"
  git merge "$branch" --no-edit || error "failed to merge branch on $__service to $branch"
  cd ..
}

pull() {
  # go to each directory and merge the branch
  local branch="${__func_args[branch]}"
  local remote="${__func_args[remote]:-origin}"

  cd "$__service" || return
  log "pulling branch on $__service to $remote:$branch"
  git pull "$remote" "$branch" --no-rebase --no-edit || error "failed to pull branch on $__service to $branch"
  cd ..
}

tag() {
  # go to each directory and tag the branch
  local version="${__func_args[version]}"

  cd "$__service" || return

  # delete tag if exists
  log "deleting tag on $__service to $version"
  git tag -d "$version" || error "failed to delete tag on $__service to $version"
  git push origin ":refs/tags/$version" || error "failed to remove tag from remote on $__service to $version"

  log "tagging branch on $__service to $version"
  git tag "$version" || error "failed to tag branch on $__service to $version"
  cd ..
}

push() {
  # go to each directory and push the branch
  local branch="${__func_args[branch]}"
  local remote="${__func_args[remote]:-origin}"

  cd "$__service" || return
  log "pushing branch on $__service to $remote:$branch"
  git push "$remote" "$branch" || error "failed to push branch on $__service to $branch"
  cd ..
}

mvnw_permission() {
  # go to each directory and switch to the branch
  cd "$__service" || return
  log "changing mvnw permission on $__service"
  chmod +x mvnw
  cd ..
}

jar() {
  export JAVA_HOME=/home/noman637/.jdks/corretto-11.0.20/
  cd "$__service" || return
  log "cleaning and building jar on $__service"
  ./mvnw clean package -DskipTests || error "failed to clean and build jar on $__service"
  cd ..
}

image() {
  cd "$__service" || return
  local prefix="${__func_args[prefix]}"
  local tag="${__func_args[tag]}"
  log "removing docker image on $__service"
  docker rmi "$prefix/$__service:$tag" || error "failed to remove docker image on $__service"
  log "building docker image on $__service"
  docker build --no-cache -t "$prefix/$__service:$tag" .
  cd ..
}

_registry() {
  local registry="${__func_args[reg]}"
  local username="${__func_args[user]}"
  local password="${__func_args[pass]}"

  log "logging in to $registry"
  docker login "$registry" -u "$username" -p "$password" || error "failed to login to $registry"
}

image_push() {
  local prefix="${__func_args[prefix]}"
  local tag="${__func_args[tag]}"

  log "pushing docker image on $__service"
  docker push "$prefix/$__service:$tag" || error "failed to push docker image on $__service"
}

################################ HELPERS ################################
: '
Captures all the arguments that are passed to current function
and stores them in an associative array __func_args
'
capture_func_args() {
  __func_args=()
  for (( ; __args_i < ${#__args[@]}; ++__args_i)); do
    local arg="${__args[$__args_i]}"
    debug "arg: $arg"
    if [[ "$arg" == -* ]]; then
      if [[ "$arg" == *"="* ]]; then
        local key="${arg%%=*}"
        key="${key#-}"
        local value="${arg#*=}"
        __func_args["$key"]="$value"
      else
        local key="$arg"
        key="${key#-}"
        __func_args["$key"]=true
      fi
    else
      break
    fi
  done
}

copy_to_context_args() {
  for key in "${!__func_args[@]}"; do
    __context_args["$key"]="${__func_args[$key]}"
  done
}

################################ MAIN ################################
main() {
  # capture all the arguments in an array
  __args=("$@")
  # capture context arguments
  capture_func_args
  copy_to_context_args

	# if the current function is not _service
	if [[ "${__args[$__args_i]}" != "_service" ]]; then
		debug "adding _service to the arguments"
		# insert _service at the __args_i index
		__args=("${__args[@]:0:$__args_i}" "_service" "${__args[@]:$__args_i}")
		debug "__args:" "${__args[@]}"
	else
		debug "skipping adding _service to the arguments"
	fi

  # for each argument, check if it's a valid function
  for (( ; __args_i < ${#__args[@]}; )); do
    local arg="${__args[$__args_i]}"
    __args_i=$((__args_i + 1))
    if [ "$(type -t "$arg")" == "function" ]; then
      # if it's a valid function
      __func="$arg"
      capture_func_args
      debug "__func: $__func"
      debug "__func_args_keys:" "${!__func_args[@]}"
      debug "__func_args_values:" "${__func_args[@]}"

      label "$__func"
      # if function name starts with _, call the function with the arguments
      if [[ "$__func" == _* ]]; then
        "$__func" "${__func_args[@]}"
        continue
      fi
      for __service in "${!__services[@]}"; do
        # call the function with the arguments
        "$__func" "${__func_args[@]}"
      done
    else
      # if it's not a valid function, print error message
      error "Invalid function: $arg"
      capture_func_args
      warn "Skipping:"
      warn "__func_args_keys:" "${!__func_args[@]}"
      warn "__func_args_values:" "${__func_args[@]}"
    fi
  done

  echo
  debug "__context_args_keys:" "${!__context_args[@]}"
  debug "__context_args_values:" "${__context_args[@]}"
}

main "$@"
