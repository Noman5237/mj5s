# Mini Jenkins with Bash

## What is it?

mj5s.sh is a Bash script designed to automate various tasks related to managing multiple Git repositories. It provides a set of functions to simplify tasks like cloning repositories, fetching updates, checking out branches, pushing changes, building JAR files, creating Docker images, and more.

The best thing is you can extend the functionalities by adding your own custom functions, taking advantage of built-in parsing and infrastructure automation.

## Examples

### Pulling from a Branch

```bash
./mj5s.sh pull -remote=gitea -branch=alpha
```

### Pushing to a Branch

```bash
./mj5s.sh push -remote=github -branch=alpha
```

### Doing Them Together, One After Another

```bash
./mj5s.sh pull -remote=gitea -branch=alpha push -remote=github -branch=alpha
```

### Creating JARs and Building Images

#### Build JAR Files and Create Images (Excluding repo-test-1)

```bash
./mj5s.sh _service -except=repo-test-1 jar image -prefix=noman5237/prod -tag=2.0.0
```

#### Build JAR Files and Create Images (Only for repo-test-1)

```bash
./mj5s.sh _service -only=repo-test-1 jar image -prefix=noman5237/prod -tag=2.0.0
```

## How Does It Work?

The script defines a modular Bash framework for managing services, particularly for operations on Git repositories and Docker containers. Here's a high-level overview of its key components:

### Globals and Data Structures

* Global Variables: Variables like `__args`, `__func`, and arrays (`__urls`, `__context_args`) manage inputs and state.
* Associative Arrays: Arrays like `__services` map repository names to URLs for service management.

### Logging and Debugging

* Standardized Output: Functions like `log`, `debug`, `warn`, and `error` provide color-coded output.
* Verbose Control: Conditional aliasing controls verbosity via `LOG_LEVEL`.

### Services Management

* Dynamically builds a list of services (`__services`) from predefined Git repository URLs.
* Filters services based on inclusion (`only`) or exclusion (`except`) criteria.

### Git Operations

* Supports operations like cloning, fetching, checking out branches, merging, pulling, tagging, and remote management.

### Build and Deployment

* Automates tasks such as permission setting, Maven-based Java builds, and Docker image handling (e.g., build, push).
* Includes Docker registry login and image management commands.

### Helpers

* Functions like `capture_func_args` and `copy_to_context_args` parse and handle command-line arguments for flexibility.
* Ensures smooth argument passing and context management.

### Main Execution Logic

* Processes function names and arguments sequentially.
* Handles service filtering before executing specific operations.

## Usage

The script allows chaining commands for multi-step operations. For example:

```bash
./mj5s.sh -only=repo-test-1 clone checkout -branch=main
```

### Explanation

1. Filters services to include only repo-test-1.
2. Clones the repository if not already cloned.
3. Checks out the main branch in the cloned repository.

## Key Features

* Dynamic Service Filtering: Enables precise targeting of repositories for specific actions.
* Modularity: Functions like `_service`, `clone`, and `fetch` can be composed flexibly.
* Custom Logging: Facilitates easy debugging and status tracking.
* Reusable Components: Easily extendable for additional services or operations.

## Dynamic Input Argument Parsing

The script supports dynamic input arguments in the `-key=value` format, making scripting functions highly customizable.

### Helper Function: capture_func_args

```bash
capture_func_args() {
  __func_args=()
  for (( ; __args_i < ${#__args[@]}; ++__args_i)); do
    local arg="${__args[$__args_i]}"
    debug "arg: $arg"
    if [[ "$arg" == -* ]]; then
      if [[ "$arg" == *"="* ]]; then
        # Parse key-value pairs (-key=value)
        local key="${arg%%=*}"
        key="${key#-}"
        local value="${arg#*=}"
        __func_args["$key"]="$value"
      else
        # Parse flags (-key)
        local key="$arg"
        key="${key#-}"
        __func_args["$key"]=true
      fi
    else
      break
    fi
  done
}
```

### Example Usage in Functions

#### Function: clone

```bash
clone() {
  : '
  This function clones a repository based on the __services array.
  If the -force argument is provided, the repository will be forcibly cloned.

  Usage:
  ./mj5s.sh clone -force=true
  '
  if [ -z "${__func_args[force]}" ]; then
    debug "force is unset, setting it to false"
    __func_args[force]=false
  fi
  local force="${__func_args[force]}"
  debug "force: $force"

  for __service in "${!__services[@]}"; do
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
  done
}
```

### Running the Script with Arguments

#### Example Input

```bash
./mj5s.sh clone -force=true
```

#### Explanation

* `capture_func_args` processes `-force=true` and sets `__func_args[force]` to `true`.
* The `clone` function reads `__func_args[force]` and decides whether to force clone the repositories.

## Summary

* Dynamic Input Arguments: Use `-key=value` or `-flag` formats for flexible operations.
* Extendable Functions: Customize behaviors using parsed arguments.
* Modular Design: Easily reusable components for a variety of tasks.
