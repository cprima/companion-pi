#!/usr/bin/env bash


#======================================================================================================================
# CompanionPi: Tooling to generate an image or to install Companion (https://bitfocus.io/companion)
# Copyright (c) …
# Licensed under the MIT License. See LICENSE file in the project root for full license information.
# Bitfocus Companion enables users to control a wide range of professional broadcast equipment and software
# using the Elgato Stream Deck or other devices.
#----------------------------------------------------------------------------------------------------------------------
# Usage: curl https://raw.githubusercontent.com/bitfocus/companion-pi/main/install.sh | bash -s -- stable v3.0.0
#======================================================================================================================
# Developer Notes at the bottom

# Exit the script immediately if any command returns a non-zero status (i.e., if any command fails).
set -e

# Treat unset variables as an error
set -o nounset

#todo check use
__ScriptVersion="v0.1.0"
__ScriptName="install.sh"
__ScriptFullName="$0"
__ScriptArgs="$*"


#======================================================================================================================
#  Defaults for positional arguments.
#----------------------------------------------------------------------------------------------------------------------
# todo
#======================================================================================================================

#======================================================================================================================
#  Defaults for install arguments.
#----------------------------------------------------------------------------------------------------------------------
ITYPE="stable"
COMPANION_LATEST_VERSION="v3.0.0" #todo replace with function call
#======================================================================================================================


#======================================================================================================================
#  Environment variables taken into account.
#----------------------------------------------------------------------------------------------------------------------
#   COMPANION_BUILD:          Install a specific stable build
#   COMPANIONPI_BRANCH:       Development only: Allow building using a testing branch of this updater
#======================================================================================================================


#======================================================================================================================
#  Other default values.
#----------------------------------------------------------------------------------------------------------------------
# Packages required to run this install script (stored as an array)
INSTALLER_DEPS=("git" "zip" "unzip" "curl" "jq")
# Packages required to run Companion (stored as an array)
COMPANION_DEPS=("libusb-1.0-0-dev" "libudev-dev" "libfontconfig1")
# OS architectures (stored as an array)
COMPANION_OS_ARCHS=("x64" "amd64" "arm64")
# OS release status (stored as an array)
COMPANION_RELEASE_STATUSES=("stable" "beta" "experimental") #or COMPANION_INSTALL_TYPES ???
# system groups to add the companion user to (stored as an array)
COMPANION_USER_GROUPS=("gpio" "dialout")
##############todo COMPANION_USER_NAME
#
COMPANION_COMPANION_API_URL="https://api.bitfocus.io/v1/product/companion/packages?branch=stable&limit=999"
#
COMPANION_SCRIPTS_TO_SYMLINK=("companion-license" "companion-help" "companion-update" "companion-reset")
#
COMPANION_REPO_URL="https://github.com/bitfocus/companion"
#
COMPANION_CLONE_FOLDER="/usr/local/src/companion"
#
COMPANION_REPO_BRANCH="master"
#
COMPANIONPI_REPO_URL="https://github.com/bitfocus/companion-pi"
COMPANIONPI_REPO_URL="https://github.com/cprima/companion-pi"
#todo env var and default value
COMPANIONPI_REPO_BRANCH="main"
COMPANIONPI_REPO_BRANCH="dev-cpm"
#
COMPANIONPI_CLONE_FOLDER="/usr/local/src/companionpi"
COMPANIONPI_CLONE_FOLDER="/usr/local/src/companionpi-ng"
#
COMPANION_INSTALL_FOLDER="/opt/companion"

#
FNM_DIR=/opt/fnm
#======================================================================================================================




#---  FUNCTION  -------------------------------------------------------------------------------------------------------
#         NAME:  __usage
#  DESCRIPTION:  Display usage information.
#----------------------------------------------------------------------------------------------------------------------
__usage() {
    cat << EOT

  Usage :  ${__ScriptName} [options] <install-type> [install-type-args]

  Installation types:
    - stable               Install latest stable release. This is the default
                           install type
    - stable [branch]      Install latest version on a branch.????????????????????????????
    - stable [version]     Install a specific version.
    - beta                 Install …
    - experimental         Install …
    - outdated [branch]    Install …??????????????????????????????? or instead of outdated git? todo


  Examples:
    - ${__ScriptName}
    - ${__ScriptName} stable
    - ${__ScriptName} stable latest
    - ${__ScriptName} stable v3.0.0
    - ${__ScriptName} stable v2.4.2
    - ${__ScriptName} beta
    - ${__ScriptName} beta latest
    - ${__ScriptName} beta 3.1.0+6079-beta-df3aa2bd
    - ${__ScriptName} experimental
    - ${__ScriptName} experimental latest
    - ${__ScriptName} experimental 3.99.0+6187-develop-b7144a02
    - ${__ScriptName} outdated stable-2.4???????????????????????????????????????? todo


  Options:
    -v  Display script version

EOT
}   # ----------  end of function __usage  ----------


# parse positional parameters from [options]
# may overwrite default variable values
while getopts ':hv' opt
do
  case "${opt}" in

    h )  __usage; exit 0                                ;;
    v )  echo "$0 -- Version $__ScriptVersion"; exit 0  ;;

    \?)  echo
         echo "Option does not exist : $OPTARG"
         __usage
         exit 1
         ;;

  esac    # --- end of case ---
done
# after this, $1 will refer to the first non-option argument passed to the script
shift "$((OPTIND-1))"



#---  FUNCTION  -------------------------------------------------------------------------------------------------------
#         NAME:  __foo
#  DESCRIPTION:  Foo bar todo
#----------------------------------------------------------------------------------------------------------------------
__foo() {
    echo foo
}   # ----------  end of function __foo  ----------


#---  FUNCTION  -------------------------------------------------------------------------------------------------------
: '
__determine_package_target

Determines the target platform and architecture for downloading a package.
The function identifies the systems OS (Mac, Raspberry Pi, or Windows) and its architecture (32-bit or 64-bit).
To be used on https://api.bitfocus.io/v1/product/companion/packages?branch=stable

Parameters:
    $1 - todo write explanation

Return:
    A string representing the determined target platform and architecture.
    Must return one of mac-arm, mac-intel, linux-tgz, linux-arm64-tgz.

Example:
    target=$(__determine_package_target)
    echo "$target"
'
#----------------------------------------------------------------------------------------------------------------------
__determine_package_target() {
    local machine
    local os
    local package_target
    local majorversion="${1:-3}"  # Default to '3' if no version specified
    machine=$(uname -m) #macOS: arm64, x86_64; RPi: armv6l,armv7l,armv8l,aarch64; WSL: x86_64
    os=$(uname -s)

    if [ "$os" == "Darwin" ]; then
        if [ "$machine" == "x86_64" ]; then
            package_target="mac-intel"
        else
            package_target="mac-arm"
        fi
    elif [ "$os" == "Linux" ]; then
        if [ "$machine" == "x86_64" ]; then
            # 64-bit architecture
            if [ "${majorversion}" == "2" ]; then
                # v2.4.2 does not exist as linux-arm64-tgz
                package_target="linux-tgz"
            else
                package_target="linux-arm64-tgz"
            fi
        elif [ "$machine" == "i686" ] || [ "$machine" == "i386" ]; then
            # 32-bit architecture.
            package_target="linux-tgz"
        elif [ "$machine" == "armv6l" ] || [ "$machine" == "armv7l" ]; then
            # likely on a 32-bit Raspberry Pi (or another ARM-based device).
            package_target="linux-tgz"
        elif [ "$machine" == "armv8l" ] || [ "$machine" == "aarch64" ]; then
            # likely on a 64-bit Raspberry Pi (or another ARM-based device).
            if [ "${majorversion}" == "2" ]; then
                # v2.4.2 does not exist as arm64
                package_target="linux-tgz"
            else
                package_target="linux-arm64-tgz"
            fi
        fi
    else
        echo "You are on a type of machine that is not supported by this script."
        exit 1
    fi

    # Returning a string value via echo
    echo ${package_target}

}   # ----------  end of function __determine_package_target  ----------



#---  FUNCTION  -------------------------------------------------------------------------------------------------------
: '
__parse_semver

Parses a semantic version string prefixed with "v" and returns the specified component: major, minor, or patch. 
If no component is specified, it returns the complete version without the "v" prefix.

Parameters:
    $1 - The semantic version string prefixed with "v", e.g., "v1.2.3".
    $2 - The component to extract (optional): "major", "minor", or "patch".

Return:
    A string representing the specified component, the complete version without the "v" prefix, 
    or an error message if the version string cannot be parsed.

Example:
    version=$(__parse_semver "v1.2.3")
    echo "$version"  # Outputs: 1.2.3
'

__parse_semver() {
    local version="$1"
    local component="${2:-all}"  # Default to 'all' if no component specified
    
    # Strip the leading 'v' prefix
    version="${version#v}"
    
    # Validate the version format
    if ! [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "Error: Invalid semantic version format."
        return 1
    fi
    
    # Parse major, minor, and patch versions
    local major="${version%%.*}"
    version="${version#*.}"
    
    local minor="${version%%.*}"
    local patch="${version#*.}"
    
    case "$component" in
        major) echo "$major" ;;
        minor) echo "$minor" ;;
        patch) echo "$patch" ;;
        all) echo "$major.$minor.$patch" ;;
        *) echo "Error: Invalid component. Choose between 'major', 'minor', 'patch', or leave empty for full version." ;;
    esac
} # ----------  end of function __parse_semver  ----------



#---  FUNCTION  -------------------------------------------------------------------------------------------------------
: '
__get_latest_version

Fetches data from the provided API endpoint and returns the version of the latest entry based on the "published" date and the specified target.

Parameters:
    $1 - The API endpoint URL from which to fetch data.
    $2 - The target value to filter the entries by.

Return:
    A string representing the version of the latest entry for the specified target.

Example:
    latest_version=$(__get_latest_version "https://your.api/endpoint" "mac-intel")
    echo "$latest_version"
'
__get_latest_version() {
    # Ensure both arguments are provided
    if [ "$#" -ne 2 ]; then
        echo "Usage: get_latest_version API_ENDPOINT TARGET"
        return 1
    fi
    local API_ENDPOINT="$1"
    local TARGET="$2"
    local version
    version=$(curl -s "$API_ENDPOINT" | jq --arg target "$TARGET" -r '[.packages[] | select(.target == $target)] | sort_by(.published) | last | .version // "Error: Target not found in API results"')
    echo "$version"
} # ----------  end of function __get_latest_version  ----------




#---  FUNCTION  -------------------------------------------------------------------------------------------------------
: '
__add_user

Adds a user to the system with the specified username.
#############################################group

Parameters:
    $1 - Username (required).

Return:
    None. It prints messages indicating success or failure.

Example:
    __add_user "newuser"
'

__add_user() {
    if [ "$#" -lt 1 ]; then
        echo "Error: Username is required."
        return 1
    fi

    local username="$1"

    # Check if the user already exists
    if id "$username" &>/dev/null; then
        echo "Error: User '$username' already exists."
        return 2
    fi

    # Create the user
    if useradd "$username"; then
        echo "User '$username' created successfully."
    else
        echo "Error: Failed to create user '$username'."
        return 3
    fi

    # Add user to groups ############################################
if [ $(getent group gpio) ]; then
  adduser -q companion gpio
fi
if [ $(getent group dialout) ]; then
  adduser -q companion dialout
fi    

} # ----------  end of function __add_user  ----------




#---  FUNCTION  -------------------------------------------------------------------------------------------------------
: '
__install_apt_packages

Installs packages on a system using apt-get.

Parameters:
    $@ - Array of package names to be installed.

Return:
    None. Prints messages indicating the status of installation.

Example:
    packages=("curl" "git" "vim")
    __install_apt_packages "${packages[@]}"
'

__install_apt_packages() {
    # Check if apt-get is available
    if ! command -v apt-get &> /dev/null; then
        echo "Error: apt-get is not available on this system."
        return 1
    fi

    # Ensure there's at least one package to install
    if [ "$#" -eq 0 ]; then
        echo "Error: No packages specified for installation."
        return 2
    fi

    # Update package lists
    sudo apt-get update

    # Install the packages
    sudo apt-get install -y "$@"
    
    if [ $? -eq 0 ]; then
        echo "Packages installed successfully."
    else
        echo "Error: Failed to install some packages."
        return 3
    fi
} # ----------  end of function __install_apt_packages  ----------



#---  FUNCTION  -------------------------------------------------------------------------------------------------------
: '
__install_fnm

Installs the Fast Node Manager (fnm) to the specified directory "/opt/fnm" and sets the FNM_DIR environment variable for the root user.

Parameters:
    None.

Return:
    None. Prints messages indicating the status of installation.

Example:
    __install_fnm
'

__install_fnm() {
    # Set and export the FNM_DIR variable
    export FNM_DIR=/opt/fnm

    # Append the setting to root's .bashrc for persistence
    echo "export FNM_DIR=/opt/fnm" >> /root/.bashrc

    # Download and install fnm
    if curl -fsSL https://fnm.vercel.app/install | bash -s -- --install-dir /opt/fnm; then
        echo "fnm installed successfully."
    else
        echo "Error: Failed to install fnm."
        return 1
    fi
} # ----------  end of function __install_fnm  ----------


#---  FUNCTION  -------------------------------------------------------------------------------------------------------
: '
__is_version_lt_2_4_2

Checks if the provided semantic version string is less than "v2.4.2".

Parameters:
    $1 - Semantic version string (e.g., "v1.2.3").

Return:
    Returns 0 (true) if the provided version is less than "v2.4.2", and 1 (false) otherwise.

Example:
    if __is_version_lt_2_4_2 "v1.3.5"; then
        echo "Version is less than v2.4.2"
    else
        echo "Version is not less than v2.4.2"
    fi
'
__is_version_lt_2_4_2() {
    local version="$1"

    local major=$(__parse_semver "$version" "major")
    local minor=$(__parse_semver "$version" "minor")
    local patch=$(__parse_semver "$version" "patch")

    if [[ $major -lt 2 ]] || 
       [[ $major -eq 2 && $minor -lt 4 ]] || 
       [[ $major -eq 2 && $minor -eq 4 && $patch -lt 2 ]]; then
        return 0  # True, the version is less than v2.4.2
    else
        return 1  # False, the version is not less than v2.4.2
    fi
} # ----------  end of function __is_version_lt_2_4_2  ----------



#---  FUNCTION  -------------------------------------------------------------------------------------------------------
: '
__clone_or_update_repo

Clone or update a Git repository.

Usage:
    clone_or_update_repo <repo_url> <target_dir>

Parameters:
    repo_url:    The URL of the Git repository to clone.
    target_dir:  The directory where the repo should be cloned to or exists already.
    branch:      (Optional) The specific branch to checkout and pull.

If the target directory does not exist, this function will clone the repo into it.
If the target directory exists and contains a Git repository, this function will update (pull) the repo.
If the target directory exists but does not contain a Git repository, an error will be reported.

Example:
    '

__clone_or_update_repo() {
    local repo_url="$1"
    local target_dir="$2"
    local branch="${3:-main}"  # Default to "main" branch if not specified

    # Check if the target directory exists
    if [ ! -d "$target_dir" ]; then
        # Directory doesn't exist, clone the repo
        git clone -q -b "$branch" "$repo_url" "$target_dir"
    else
        # Directory exists, check if it's a git repository
        if [ -d "$target_dir/.git" ]; then
            # It's a git repository, pull the latest changes
            cd "$target_dir"
            git checkout -q "$branch"
            git pull -q origin "$branch"
        else
            echo "Error: Target directory exists but is not a git repository."
            return 1
        fi
    fi
} # ----------  end of function __clone_or_update_repo  ----------



#---  FUNCTION  -------------------------------------------------------------------------------------------------------
: '
__download_and_extract_package

Download and extract the Companion update.

Usage:
    download_and_extract_companion <url>

Parameters:
    url: The URL to download the Companion update from.

Example:

This function performs the following steps:
1. Downloads the specified update from the provided URL.
2. Extracts the downloaded tar.gz archive.
3. Moves the extracted resources to the /opt/companion directory.
4. Cleans up temporary files and directories.
'

__download_and_extract_package() {
    local SELECTED_URL="$1"

    # download the update
    wget "$SELECTED_URL" -O /tmp/companion-package.tar.gz -q  --show-progress

    # extract download
    rm -R -f /tmp/companion-package
    mkdir /tmp/companion-package
    tar -xzf /tmp/companion-package.tar.gz --strip-components=1 -C /tmp/companion-package
    rm /tmp/companion-package.tar.gz

    # copy across the useful files
    rm -R -f ${COMPANION_INSTALL_FOLDER}
    mv /tmp/companion-package/resources ${COMPANION_INSTALL_FOLDER}
    rm -R /tmp/companion-package
} # ----------  end of function __download_and_extract_package  ----------



#---  FUNCTION  -------------------------------------------------------------------------------------------------------

: '
__append_to_path

Append a directory to the PATH variable in ~/.bashrc if not already present.

Usage:
    append_to_path /path/to/directory

Parameters:
    $1: The directory path to add to the PATH.

Example:
# Example usage:
# __append_to_path "/path/to/directory"

Description:
    This function checks if the provided directory path is already present in the 
    PATH variable declaration within the ~/.bashrc file. If the directory is not 
    already in PATH, the function appends it. If it is already present, a message 
    indicating the same is displayed.
'

__append_to_path() {

    local new_dir="$1"
    
    # Check if the path is already in the .bashrc PATH declaration
    if ! grep -q "PATH.*$new_dir" ~/.bashrc; then
        # Append the new directory to PATH in .bashrc
        echo "export PATH=\$PATH:$new_dir" >> ~/.bashrc
        echo "Added $new_dir to PATH in ~/.bashrc"
    else
        echo "$new_dir is already in PATH in ~/.bashrc"
    fi
}

# ----------  end of function __append_to_path  ----------



#---  FUNCTION  -------------------------------------------------------------------------------------------------------
: '
__install_update_prompt

Run yarn install in the update-prompt directory of companionpi.

Usage:
    install_update_prompt

Description:
    This function changes the current working directory to 
    "/usr/local/src/companionpi/update-prompt" and runs the yarn install 
    command to install the necessary dependencies.
'
# Example usage:
# install_update_prompt
__install_update_prompt() {
    yarn --cwd "/usr/local/src/companionpi/update-prompt" install
}


# ----------  end of function __is_version_lt_2_4_2  ----------
install_update_prompt() {
    : '
    Run yarn install in the specified directory or default to the update-prompt directory of companionpi.

    Usage:
        install_update_prompt [directory_path]

    Parameters:
        directory_path: Optional. The directory where yarn install should be run. Defaults to "/usr/local/src/companionpi/update-prompt".

    Description:
        This function checks if yarn is available, then changes the current working directory to the specified directory 
        (or the default if none is provided) and runs the yarn install command to install the necessary dependencies.
    '

    # Check if yarn is available
    if ! command -v yarn &> /dev/null; then
        echo "yarn command not found. Please install yarn before proceeding."
        return 1
    fi

    local cwd="${1:-/usr/local/src/companionpi/update-prompt}"
    
    yarn --cwd "$cwd" --silent install
}

# Example usage:
# install_update_prompt
# or
# install_update_prompt "/path/to/other/directory"

#---  FUNCTION  -------------------------------------------------------------------------------------------------------
# Declare global variable
#########COMPANION_SCRIPTS_TO_SYMLINK=("companion-license" "companion-help" "companion-update" "companion-reset")

create_symlinks() {
    : '
    Create symbolic links for all scripts in the COMPANION_SCRIPTS_TO_SYMLINK array.

    Usage:
        create_symlinks [source_directory]

    Parameters:
        source_directory: Optional. The directory containing the scripts to be linked. Defaults to "/usr/local/src/companionpi".

    Description:
        This function iterates over the global COMPANION_SCRIPTS_TO_SYMLINK array and creates symbolic links 
        from the specified source directory (or the default if none is provided) to the /usr/local/bin/ directory for each script.
    '
    
    local src_dir="${1:-/usr/local/src/companionpi}"
    
    for script in "${COMPANION_SCRIPTS_TO_SYMLINK[@]}"; do
        ln -s -f "$src_dir/$script" "/usr/local/bin/$script"
    done
}

# Example usage:
# create_symlinks
# or
# create_symlinks "/path/to/other/source/directory"


# ----------  end of function __is_version_lt_2_4_2  ----------

#---  FUNCTION  -------------------------------------------------------------------------------------------------------
create_motd_symlink() {
    : '
    Create a symbolic link for the motd file.

    Usage:
        create_motd_symlink [source_directory]

    Parameters:
        source_directory: Optional. The directory containing the motd file to be linked. Defaults to "/usr/local/src/companionpi".

    Description:
        This function creates a symbolic link from the specified source directory (or the default if none is provided) 
        for the motd file to the /etc/motd location.
    '
    
    local src_dir="${1:-/usr/local/src/companionpi}"
    
    ln -s -f "$src_dir/motd" "/etc/motd"
}

# Example usage:
# create_motd_symlink
# or
# create_motd_symlink "/path/to/other/source/directory"

# ----------  end of function __is_version_lt_2_4_2  ----------


#---  FUNCTION  -------------------------------------------------------------------------------------------------------

# ----------  end of function __is_version_lt_2_4_2  ----------






#---  FUNCTION  -------------------------------------------------------------------------------------------------------
preinstall_3.0.0() {
    echo "~~PRE~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    echo "~~PRE~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    echo "~~PRE~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
}
# ----------  end of function __is_version_lt_2_4_2  ----------

#---  FUNCTION  -------------------------------------------------------------------------------------------------------
postinstall_3.0.0() {
    echo "~~POST~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    echo "~~POST~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    echo "~~POST~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
}
# ----------  end of function __is_version_lt_2_4_2  ----------






#---  FUNCTION  -------------------------------------------------------------------------------------------------------
install_packaged() {

    prefix="preinstall_"
    variable_part="3.0.0"
    suffix=""

    function_name="${prefix}${variable_part}${suffix}"

    if declare -Ff "$function_name" > /dev/null; then
        echo "Function ${function_name} exists"
    else
        echo "Function ${function_name} does not exist"
    fi


    #__download_and_extract_package
    # do_udev_stuff
    # do sudoers
    # # if neither old or new config direcoty exists, create it. This is to work around a bug in 3.0.0-rc2
    # if [ ! -d "/home/companion/.config/companion-nodejs" ]; then
    #     if [ ! -d "/home/companion/companion" ]; then
    #         su companion -c "mkdir -p /home/companion/.config/companion-nodejs"
    #     fi
    # fi
    # cp companion.service /etc/systemd/system
    # systemctl daemon-reload
    # create_symlinks
    # create_motd_symlink

    prefix="postinstall_"
    variable_part="3.0.0"
    suffix=""

    function_name="${prefix}${variable_part}${suffix}"

    if declare -Ff "$function_name" > /dev/null; then
        echo "Function ${function_name} exists"
    else
        echo "Function ${function_name} does not exist"
    fi
}
# ----------  end of function install_packaged  ----------


#==end functions=======================================================================================================
#======================================================================================================================
#======================================================================================================================
#======================================================================================================================
#======================================================================================================================
#======================================================================================================================
#======================================================================================================================




# the following code depends on some packages, like git or jq.
__install_apt_packages "${INSTALLER_DEPS[@]}"

__clone_or_update_repo "${COMPANIONPI_REPO_URL}" "${COMPANIONPI_CLONE_FOLDER}" "${COMPANIONPI_REPO_BRANCH}"
__clone_or_update_repo "${COMPANION_REPO_URL}" "${COMPANION_CLONE_FOLDER}" "${COMPANION_REPO_BRANCH}"

__install_fnm
export PATH=/opt/fnm:$PATH #todo use global variable
eval "$(fnm env --shell bash)"





#======================================================================================================================
#  Based on how this script is called: What is to do?
#----------------------------------------------------------------------------------------------------------------------

# Define installation type
if [ "$#" -gt 0 ];then
    ITYPE=$1
    shift
fi
if [ "$(echo "$ITYPE" | grep -E '(stable|beta|experimental)')" = "" ]; then #todo check against array
#
# is_valid_type=0
# for type in "${VALID_TYPES[@]}"; do
#     if [[ "$ITYPE" == "$type" ]]; then
#         is_valid_type=1
#         break
#     fi
# done

# # Use the result of the check in a condition
# if [[ "$is_valid_type" -eq 0 ]]; then
#     echo "Invalid ITYPE value."
#     # Handle the invalid case here
# fi
#
    echo "Installation type \"$ITYPE\" is not known..."
    exit 1
fi
#----------------------------------------------------------------------------------------------------------------------
if [ "$ITYPE" = "stable" ]; then
    COMPANION_API_URL="https://api.bitfocus.io/v1/product/companion/packages?branch=${ITYPE}&limit=999"
    if [ "$#" -eq 0 ];then
        IVERSION=$(__get_latest_version "${COMPANION_API_URL}" "$(__determine_package_target)" )
    else
        IVERSION="$1"
        shift
    fi
#----------------------------------------------------------------------------------------------------------------------
elif [ "$ITYPE" = "beta" ]; then
    COMPANION_API_URL="https://api.bitfocus.io/v1/product/companion/packages?branch=${ITYPE}&limit=999"
    if [ "$#" -eq 0 ];then
        IVERSION=$(__get_latest_version "${COMPANION_API_URL}" "$(__determine_package_target)" )
    else
        IVERSION="$1"
        shift
    fi
#----------------------------------------------------------------------------------------------------------------------
elif [ "$ITYPE" = "experimental" ]; then
    COMPANION_API_URL="https://api.bitfocus.io/v1/product/companion/packages?branch=${ITYPE}&limit=999"
    if [ "$#" -eq 0 ];then
        IVERSION=$(__get_latest_version "${COMPANION_API_URL}" "$(__determine_package_target)" )
    else
        IVERSION="$1"
        shift
    fi
fi
#----------------------------------------------------------------------------------------------------------------------
# Check for any unparsed arguments. Should be an error.
if [ "$#" -gt 0 ]; then
    __usage
    echo
    echo "Too many arguments."
    exit 1
fi
#----------------------------------------------------------------------------------------------------------------------
# …
#======================================================================================================================



# latest_version=$(__get_latest_version "https://api.bitfocus.io/v1/product/companion/packages?branch=${ITYPE}&limit=999" "linux-arm64-tgz")
# echo "latest_version: $latest_version"



# target="$(__determine_package_target $(__parse_semver "${IVERSION}" "major"))"
# echo "target: ${target}"




if __is_version_lt_2_4_2 "${IVERSION}"; then
    echo "Version ${IVERSION} does not meet the specified criteria."
    #todo make work for stable-2.* branches
else
    URI=$(curl -s "$COMPANION_API_URL" | jq  --arg target "$(__determine_package_target $(__parse_semver "${IVERSION}" "major"))"  --arg version "$IVERSION" -r '[.packages[] | select(.target == $target and .version == $version)] | sort_by(.published) | last | .uri')
    # Check if empty
    if [[ "$URI" && "$URI" != "null" ]]; then
        ################install_packaged
        echo " Going to download ${URI}"
        __download_and_extract_package ${URI} #todo work in IVERSION and APIURL and target
        cd ${COMPANION_INSTALL_FOLDER}
        pwd
        cat .node-version
        fnm use --install-if-missing --silent-if-unchanged
        #########todo fnm default
        npm --unsafe-perm install -g yarn &>/dev/null
    else
        echo "No matching package found for target: $target and version: $IVERSION"
    fi
fi








exit 0

__install_apt_packages "${COMPANION_DEPS[@]}"

exit 0




CURRENT_ARCH=$(dpkg --print-architecture)
if [[ "$CURRENT_ARCH" != "x64" && "$CURRENT_ARCH" != "amd64" && "$CURRENT_ARCH" != "arm64" ]]; then
    echo "$CURRENT_ARCH is not a supported cpu architecture for running Companion."
    echo "If you are running on an arm device (such as a Raspberry Pi), make sure to use an arm64 image."
    exit 1
fi

echo "This will attempt to install Companion as a system service on this device."
echo "It is designed to be run on headless servers, but can be used on desktop machines if you are happy to not have the tray icon."
echo "A user called 'companion' will be created to run the service, and various scripts will be installed to manage the service"

if [ $(/usr/bin/id -u) -ne 0 ]; then
    echo "Must be run as root"
    exit 1
fi

# Install a specific stable build. It is advised to not use this, as attempting to install a build that doesn't
# exist can leave your system in a broken state that needs fixing manually
COMPANION_BUILD="${COMPANION_BUILD:-beta}"
# Development only: Allow building using a testing branch of this updater
COMPANIONPI_BRANCH="${COMPANIONPI_BRANCH:-main}"

# add a system user
adduser --disabled-password companion --gecos ""

# install some dependencies
apt-get update
apt-get install -y git zip unzip curl libusb-1.0-0-dev libudev-dev
apt-get clean

# install fnm to manage node version
# we do this to /opt/fnm, so that the companion user can use the same installation
export FNM_DIR=/opt/fnm
echo "export FNM_DIR=/opt/fnm" >> /root/.bashrc
curl -fsSL https://fnm.vercel.app/install | bash -s -- --install-dir /opt/fnm
export PATH=/opt/fnm:$PATH
eval "`fnm env --shell bash`"

# clone the companionpi repository
git clone https://github.com/bitfocus/companion-pi.git -b $COMPANIONPI_BRANCH /usr/local/src/companionpi
cd /usr/local/src/companionpi

# configure git for future updates
git config --global pull.rebase false

# run the update script
if [ "$COMPANION_BUILD" == "beta" ] || [ "$COMPANION_BUILD" == "experimental" ]; then
    ./update.sh beta
else
    ./update.sh stable "$COMPANION_BUILD"
fi

# install update script dependencies, as they were ignored
yarn --cwd "/usr/local/src/companionpi/update-prompt" install

# enable start on boot
systemctl enable companion

# add the fnm node to this users path
# TODO - verify permissions
echo "export PATH=/opt/fnm/aliases/default/bin:\$PATH" >> /home/companion/.bashrc

# check that a build of companion was installed
if [ ! -d "/opt/companion" ] 
then
    echo "No Companion build was installed!\nIt should be possible to recover from this with \"sudo companion-update\"" 
    exit 9999 # die with error code 9999
fi

echo "Companion is installed!"
echo "You can start it with \"sudo systemctl start companion\" or \"sudo companion-update\""




######################################################################################


exit 0




#======================================================================================================================
#  Developer Notes
#----------------------------------------------------------------------------------------------------------------------
: '
This script is called curl-to-bash or downloaded-executed.

Anatomy of this script:
1. variable declarations
2. parse arguments, possibly overwriting variable declarations
3. function declarations
4. satisfy requirements for installer
5. determine which "action" the user wants
6. installation
6.0. perform version-specific preinstall (if exists)
6.1. perform package-based or git-based installation (git-based todo as of 2023-08-08)
6.2. satisfy requirements for companion
6.3. perform version-specific postinstall (if exists)
6.4. administrate system for companion (systemd, scripts, …)
7. cleanup



# todo:
# prep install
# - clone companionpi repo
# - clone companion repo
# - install fnm and configure its use
# parse arguments and commands
# determine which version the user wants to be installed, fallback to latest
# ensure prerequisites are met
# - if v3 is in https://api.bitfocus.io/v1/product/companion/packages?branch=stable&limit=999
# - todo: v2
# - install packages
# - 
# install
# configure
# - add user
# cleanup

# todo: bail if wrong OS / machine


'
#======================================================================================================================
