#!/usr/bin/env bash

#======================================================================================================================
# CompanionPi: Tooling to generate an image or to install Companion (https://bitfocus.io/companion)
# Copyright (c) …
# Licensed under the MIT License. See LICENSE file in the project root for full license information.
# Bitfocus Companion enables users to control a wide range of professional broadcast equipment and software
# using the Elgato Stream Deck or other devices.
#----------------------------------------------------------------------------------------------------------------------
# Usage: curl https://raw.githubusercontent.com/bitfocus/companion-pi/main/install.sh | bash -s -- stable v3.0.0
# Developer Notes at the bottom
#======================================================================================================================

#======================================================================================================================
#  Variable declarations
#----------------------------------------------------------------------------------------------------------------------
echo -e "\n\e[1m ----- Variable declarations\e[0m"

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
#  Defaults for options arguments.
#  Options arguments as in ${__ScriptName} [options] <install-type> [install-type-args]
#----------------------------------------------------------------------------------------------------------------------
# todo
#======================================================================================================================

#======================================================================================================================
#  Defaults for install type arguments.
#  Install type arguments as in ${__ScriptName} [options] <install-type> [install-type-args]
#----------------------------------------------------------------------------------------------------------------------
ITYPE="stable"
#unused COMPANION_LATEST_VERSION="v3.0.0" #todo replace with function call
#======================================================================================================================


#======================================================================================================================
#  Environment variables taken into account.
#----------------------------------------------------------------------------------------------------------------------
#   COMPANION_BUILD:          Install a specific stable build
#   COMPANIONPI_BRANCH:       Development only: Allow building using a testing branch of this updater
#======================================================================================================================


#======================================================================================================================
#  Other default values.
#  It is explicitly encouraged to use getopts below to overwrite these default values.
#----------------------------------------------------------------------------------------------------------------------
# Packages required to run this install script (stored as an array)
COMPANIONPI_DEPS=("git" "curl" "jq") # "zip" "unzip"
# Packages required to run Companion (stored as an array)
COMPANION_DEPS=("libusb-1.0-0-dev" "libudev-dev" "libfontconfig1")
# OS architectures (stored as an array)
COMPANION_OS_ARCHS=("x64" "amd64" "arm64")
# OS release status (stored as an array)
COMPANION_VALID_INSTALL_TYPES=("stable" "beta" "experimental")
# system groups to add the companion user to (stored as an array)
COMPANION_USER_GROUPS=("gpio" "dialout")
##############todo COMPANION_USER_NAME
# Default URL where to fetch 
COMPANION_API_URL="https://api.bitfocus.io/v1/product/companion/packages?branch=stable&limit=999"
# todo check if names or paths
COMPANION_SCRIPTS_TO_SYMLINK=("companion-license" "companion-help" "companion-update" "companion-reset")
# Companion repo source and target
COMPANION_REPO_URL="https://github.com/bitfocus/companion"
COMPANION_CLONE_FOLDER="/usr/local/src/companion"
COMPANION_REPO_BRANCH="master"
# CompanionPi repo source and target
COMPANIONPI_REPO_URL="https://github.com/bitfocus/companion-pi"
COMPANIONPI_REPO_URL="https://github.com/cprima/companion-pi"
#todo env var and default value
COMPANIONPI_REPO_BRANCH="main"
COMPANIONPI_REPO_BRANCH="dev-cpm"
COMPANIONPI_CLONE_FOLDER="/usr/local/src/companionpi"
COMPANIONPI_CLONE_FOLDER="/usr/local/src/companionpi-ng"
COMPANIONPI_CLONE_FOLDER="/mnt/d/github.com/cprima/companion-pi"
COMPANION_INSTALL_FOLDER="/opt/companion"

# fnm read the environment variable as its base-dir for the root directory of fnm installations
FNM_DIR=/opt/fnm
export FNM_DIR=${FNM_DIR} 

#======================================================================================================================




#---  FUNCTION  -------------------------------------------------------------------------------------------------------
#         NAME:  __usage
#  DESCRIPTION:  Display usage information. Needs to be declared before getopts call.
#----------------------------------------------------------------------------------------------------------------------
__usage() {
    cat << EOT

  Usage :  ${__ScriptName} [options] <install-type> [install-type-args]

  Installation types:
    - stable                   Install latest stable release. This is the default install type.
    - stable [version]         Install a specific version.
    - beta [version]           Install …
    - experimental [version]   Install …
    - git branch               Install …


  Examples:
    - ${__ScriptName}
    - ${__ScriptName} stable
    - ${__ScriptName} stable latest
    - ${__ScriptName} stable v3.0.0
    - ${__ScriptName} stable v2.4.2 #???????????????????????????????????????????? todo
    - ${__ScriptName} beta
    - ${__ScriptName} beta latest
    - ${__ScriptName} beta 3.1.0+6079-beta-df3aa2bd
    - ${__ScriptName} experimental
    - ${__ScriptName} experimental latest
    - ${__ScriptName} experimental 3.99.0+6187-develop-b7144a02
    - ${__ScriptName} git stable-2.4


  Options:
    -v  Display script version

EOT
}   # ----------  end of function __usage  ----------

echo -e "\n\e[1m ----- Going to parse arguments, possibly overwriting variable declarations\e[0m"

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


#----------------------------------------------------------------------------------------------------------------------
# End of variable declarations
#======================================================================================================================




#======================================================================================================================
#  Function declarations
#----------------------------------------------------------------------------------------------------------------------
echo -e "\n\e[1m ----- function declarations\e[0m"


#---  FUNCTION  -------------------------------------------------------------------------------------------------------
#         NAME:  __foo
#  DESCRIPTION:  Template
#----------------------------------------------------------------------------------------------------------------------
: '
__foo

Description…

Parameters:
    $1 - if used

Return:
    Returns…

Example:
    someval=$(__foo)
    echo "$someval"
'
__foo() {
    echo foo
}   # ----------  end of function __foo  ----------



#----------------------------------------------------------------------------------------------------------------------
#--helper functions----------------------------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------------------------------------


#---  FUNCTION  -------------------------------------------------------------------------------------------------------
: '
__parse_semver

Parse a semantic version string to retrieve the major, minor, patch, or pre-release label.

Usage:
    __parse_semver <version_string> [component]

Arguments:
    version_string: The semantic version string to parse (e.g., v1.2.3, v1.2.3-rc1).
    component: (Optional) Specific component of the version to retrieve. 
               Acceptable values are "major", "minor", "patch", "prerelease", or "all" (default).

Returns:
    The requested component of the version string or the entire version if "all" is specified.

Examples:
    __parse_semver v1.2.3                # Returns 1.2.3
    __parse_semver v1.2.3 major          # Returns 1
    __parse_semver v1.2.3-rc1 all        # Returns 1.2.3-rc1
    __parse_semver v1.2.3-rc1 prerelease # Returns rc1
'
__parse_semver() {
    local version="$1"
    local component="${2:-all}"  # Default to 'all' if no component specified
    
    # Strip the leading 'v' prefix
    version="${version#v}"
    
    # Extract pre-release label if it exists
    local pre_release_label=""
    if [[ "$version" =~ - ]]; then
        pre_release_label="${version#*-}"
        version="${version%%-*}"
    fi
    
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
        prerelease) echo "$pre_release_label" ;; # Adding this to retrieve pre-release label
        all) 
            if [[ -n "$pre_release_label" ]]; then
                echo "$major.$minor.$patch-$pre_release_label"
            else
                echo "$major.$minor.$patch"
            fi
            ;;
        *) echo "Error: Invalid component. Choose between 'major', 'minor', 'patch', 'prerelease', or leave empty for full version." ;;
    esac
} # ----------  end of function __parse_semver  ----------


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
__append_in_bashrc_to_path

Append a directory to the PATH variable in ~/.bashrc if not already present.

Usage:
    __append_in_bashrc_to_path /path/to/directory

Parameters:
    $1: The directory path to add to the PATH.

Example:
# Example usage:
# __append_in_bashrc_to_path "/path/to/directory"

Description:
    This function checks if the provided directory path is already present in the 
    PATH variable declaration within the ~/.bashrc file. If the directory is not 
    already in PATH, the function appends it. If it is already present, a message 
    indicating the same is displayed.
'

__append_in_bashrc_to_path() {

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

# ----------  end of function __append_in_bashrc_to_path  ----------

#---  FUNCTION  -------------------------------------------------------------------------------------------------------
: '
__copy_semantic_versioned_file

Copy a file based on semantic versioning from subfolders.

Usage:
    copy_semantic_versioned_file SEMANTIC_VERSION GIT_REPO_URL

Globals:
    COMPANIONPI_CLONE_FOLDER: todo

Parameters:
    SEMANTIC_VERSION: The version for which the file should be checked and copied.
    FILE: 
    TARGETFOLDER: 

Description:
    This function will clone the given git repository and then look for a file in subfolders 
    named by semantic versioning. It will try to copy the file based on the given version, 
    and if not found, it will step up the version hierarchy until it finds the file.
    
# Example usage:
# copy_semantic_versioned_file "2.4.2" "myfile.txt" "/tmp"
'
__copy_semantic_versioned_file() {    
    local version="$1"
    local major=$(__parse_semver "$version" "major")
    local minor=$(__parse_semver "$version" "minor")
    local patch=$(__parse_semver "$version" "patch")
    local file="$2"
    local targetfolder="$3"

    # Clone the repo and cd into it
    #git clone "$repo_url" cloned_repo
    cd ${COMPANIONPI_CLONE_FOLDER}

    # Check and copy the file based on version hierarchy
    if [[ -f "./files/v${major}.${minor}.${patch}/${file}" ]]; then
        cp "./files/v${major}.${minor}.${patch}/${file}" "${targetfolder}"
    elif [[ -f "./files/v${major}.${minor}/${file}" ]]; then
        cp "./files/v${major}.${minor}/${file}" "${targetfolder}"
    else
        cp "./files/v${major}/${file}" "${targetfolder}"
    fi

} # ----------  end of __copy_semantic_versioned_file  ----------



#----------------------------------------------------------------------------------------------------------------------
#--installer functions-------------------------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------------------------------------



#---  FUNCTION  -------------------------------------------------------------------------------------------------------
: '
__determine_package_target

Determines the target platform and architecture for downloading a package,
with reference to  https://api.bitfocus.io/v1/product/companion/packages?branch=stable
The function identifies the systems OS (Mac, Raspberry Pi, or Windows) and its architecture (32-bit or 64-bit).

Parameters:
    $1 - Companion major version

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
__create_user_with_groups

Adds a user to the system with the specified username.
#############################################group

Parameters:
    $1 - Username (required).

Return:
    None. It prints messages indicating success or failure.

Example:
    __create_user_with_groups "newuser"
'

__create_user_with_groups() {
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

    # Add user to groups
    for group in "${COMPANION_USER_GROUPS[@]}"; do
        # Check if the group exists on the system
        if getent group "$group" > /dev/null; then
            # Add the user to the group
            usermod -aG "$group" "$username"
            echo "User $username added to group $group."
        else
            echo "Group $group does not exist, skipping."
        fi
    done

} # ----------  end of function __create_user_with_groups  ----------




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
    export FNM_DIR=${FNM_DIR}

    # Append the setting to root's .bashrc for persistence
    echo "export FNM_DIR=${FNM_DIR}" >> /root/.bashrc #todo

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
__install_update_prompt()

Run yarn install in the specified directory or default to the update-prompt directory of companionpi.

Usage:
    install_update_prompt [directory_path]

Parameters:
    directory_path: Optional. The directory where yarn install should be run. Defaults to "/usr/local/src/companionpi/update-prompt".

Description:
    This function checks if yarn is available, then changes the current working directory to the specified directory 
    (or the default if none is provided) and runs the yarn install command to install the necessary dependencies.
# Example usage:
# install_update_prompt
# or
# install_update_prompt "/path/to/other/directory"
'
__install_update_prompt() {

    # Check if yarn is available
    if ! command -v yarn &> /dev/null; then
        echo "yarn command not found. Please install yarn before proceeding."
        return 1
    fi

    local cwd="${1:-${COMPANIONPI_CLONE_FOLDER}/update-prompt}"
    
    yarn --cwd "$cwd" --silent install
}


#---  FUNCTION  -------------------------------------------------------------------------------------------------------
# Declare global variable
#########COMPANION_SCRIPTS_TO_SYMLINK=("companion-license" "companion-help" "companion-update" "companion-reset")

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
__create_symlinks() {
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
__create_motd_symlink() {
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
: '
__setup_node_with_fnm

Sets up the Node environment using `fnm` based on the `.node-version` file 
present in the COMPANION_INSTALL_FOLDER. Also updates the PATH to include 
the associated Node binaries.

Globals:
    COMPANION_INSTALL_FOLDER (str): Path to the Companion installation folder.

Arguments:
    None.

Returns:
    None.
'
__setup_node_with_fnm() {
    local node_version
    export FNM_DIR=${FNM_DIR}
    export PATH=$FNM_DIR:$PATH
    eval "$(fnm env --shell bash)"

    # Navigate to the installation folder
    cd "${COMPANION_INSTALL_FOLDER}" || {
        echo "Error: Failed to change directory to ${COMPANION_INSTALL_FOLDER}"
        return 1
    }

    # Display the Node version from .node-version file
    #cat .node-version

    # Use fnm to set up Node based on .node-version, and install if missing
    fnm use --install-if-missing --silent-if-unchanged

    # Create an alias for the current Node version
    # Enables use of: export PATH=/opt/fnm/aliases/companion/bin:$PATH
    fnm alias "$(fnm current)" companion

    # Update PATH to include the Node binaries
    export PATH="${FNM_DIR}/aliases/companion/bin:$PATH"
}

# ----------  end of function __is_version_lt_2_4_2  ----------

#---  FUNCTION  -------------------------------------------------------------------------------------------------------
: '
__fetch_latest_uri

Fetch the latest URI for a given API URL and version.

Parameters:
$1: COMPANION_API_URL - The API URL to fetch data from.
$2: IVERSION - The version of interest.

Returns:
The latest URI matching the provided version.

Prerequisites:
Assumes the availability of the __determine_package_target and __parse_semver functions.
'
__fetch_latest_uri() {
    #local COMPANION_API_URL="$1"
    #local IVERSION="$2"
    
    local URI
    URI=$(curl -s "$COMPANION_API_URL" | jq  --arg target "$(__determine_package_target $(__parse_semver "${IVERSION}" "major"))"  --arg version "$IVERSION" -r '[.packages[] | select(.target == $target and .version == $version)] | sort_by(.published) | last | .uri')
    
    echo "$URI"
}

# ----------  end of function __is_version_lt_2_4_2  ----------

#---  FUNCTION  -------------------------------------------------------------------------------------------------------

# ----------  end of function __is_version_lt_2_4_2  ----------

#---  FUNCTION  -------------------------------------------------------------------------------------------------------

# ----------  end of function __is_version_lt_2_4_2  ----------






#---  FUNCTION  -------------------------------------------------------------------------------------------------------
preinstall_3.0.0() {
    echo "~~PRE~3.0.0~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
}
# ----------  end of function __is_version_lt_2_4_2  ----------

#---  FUNCTION  -------------------------------------------------------------------------------------------------------
postinstall_3.0.0() {
    echo "~~POST~3.0.0~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
}
# ----------  end of function __is_version_lt_2_4_2  ----------






#---  FUNCTION  -------------------------------------------------------------------------------------------------------

main_install_packaged_v3() {
    local URI=$(__fetch_latest_uri)
    if declare -Ff "preinstall_$(__parse_semver "${IVERSION}" "all")" > /dev/null; then
        "preinstall_$(__parse_semver "${IVERSION}" "all")"
    fi
    if [[ "$URI" && "$URI" != "null" ]]; then
        #__download_and_extract_package "$(__fetch_latest_uri)"
        __setup_node_with_fnm
        cd ${COMPANION_INSTALL_FOLDER}
        echo $PATH
        which npm
        npm --unsafe-perm install -g yarn #&>/dev/null #todo errorhandlign
        #__install_apt_packages "${COMPANION_DEPS[@]}"
        __copy_semantic_versioned_file "${IVERSION}" "companion.service" "/etc/systemd/system"
        #systemctl daemon-reload
        __create_symlinks
        __create_motd_symlink
        #systemctl enable companion
        if declare -Ff "postinstall_$(__parse_semver "${IVERSION}" "all")" > /dev/null; then
            "postinstall_$(__parse_semver "${IVERSION}" "all")"
        fi

    else
        echo "No matching package found for target: $(__determine_package_target $(__parse_semver "${IVERSION}" "major")) and version: $IVERSION"
        exit 1
    fi
} # ----------  end of function install_packaged  ----------


#----------------------------------------------------------------------------------------------------------------------
#  End of function declarations
#======================================================================================================================





#======================================================================================================================
#  Satisfy requirements for this installer script
#----------------------------------------------------------------------------------------------------------------------
echo -e "\n\e[1m ----- satisfy requirements for installer script\e[0m"

if [ $(/usr/bin/id -u) -ne 0 ]; then
    echo "Must be run as root"
    exit 1
fi

# # the following code depends on some packages, like git or jq.
#__install_apt_packages "${COMPANIONPI_DEPS[@]}"

# # get installer repo and software repo into /usr/local/src/ 
#__clone_or_update_repo "${COMPANIONPI_REPO_URL}" "${COMPANIONPI_CLONE_FOLDER}" "${COMPANIONPI_REPO_BRANCH}"
#__clone_or_update_repo "${COMPANION_REPO_URL}" "${COMPANION_CLONE_FOLDER}" "${COMPANION_REPO_BRANCH}"

# # The Fast and simple Node.js version Manager, instructed to work on the file .node-version
#__install_fnm


#----------------------------------------------------------------------------------------------------------------------
# 
#======================================================================================================================



#======================================================================================================================
#  Determine machine, environment, installation type and version-to-install
#----------------------------------------------------------------------------------------------------------------------
echo -e "\n\e[1m ----- determine machine, environment, installation type and version-to-install\e[0m"

# Determine installation-type from the argument
if [ "$#" -gt 0 ];then
    ITYPE=$1
    shift
fi

# do we have a supported value for $ITYPE?
# looping the array for match (verbose but intuitive)
is_valid_type=0
for type in "${COMPANION_VALID_INSTALL_TYPES[@]}"; do
    if [[ "$ITYPE" == "$type" ]]; then
        is_valid_type=1
        break
    fi
done
# Use the result of the check in a condition
if [[ "$is_valid_type" -eq 0 ]]; then
    echo "Invalid ITYPE value."
    # Handle the invalid case here
    exit 1
fi

# # placeholder for explicit code
# if [ "$ITYPE" = "stable" ]; then
# :
# elif [ "$ITYPE" = "beta" ]; then
# :
# elif [ "$ITYPE" = "experimental" ]; then
# :
# fi

# If no version is given get the latest from COMPANION_API_URL as per .published timestamp
if [ "$#" -eq 0 ];then
    IVERSION=$(__get_latest_version "${COMPANION_API_URL}" "$(__determine_package_target)" )
else
    IVERSION="$1"
    shift
fi

# Check for any unparsed arguments. Should be an error.
if [ "$#" -gt 0 ]; then
    __usage
    echo
    echo "Too many arguments."
    exit 1
fi

# updating the global variable
COMPANION_API_URL="https://api.bitfocus.io/v1/product/companion/packages?branch=${ITYPE}&limit=999"

target="$(__determine_package_target $(__parse_semver "${IVERSION}" "major"))"

echo $COMPANION_API_URL
echo "${IVERSION}"
echo "$ITYPE"
echo "target: ${target}"

#----------------------------------------------------------------------------------------------------------------------
# 
#======================================================================================================================



#======================================================================================================================
#  Installation
#----------------------------------------------------------------------------------------------------------------------
echo -e "\n\e[1m ----- installation\e[0m"



# If this script is run, but not sourced:
if [[ $0 == "$BASH_SOURCE" ]]; then
    if __is_version_lt_2_4_2 "${IVERSION}"; then
        echo "Version ${IVERSION} does not meet the specified criteria."
        exit 1
        #todo make work for stable-2.* branches
    elif [ "$(__parse_semver "${IVERSION}" "major")" -ge "4" ]; then
        echo "Version ${IVERSION} does not meet the specified criteria."
        exit 1
    else
        main_install_packaged_v3
    fi
fi

#----------------------------------------------------------------------------------------------------------------------
# End of Installation
#======================================================================================================================



#======================================================================================================================
#  Cleanup
#----------------------------------------------------------------------------------------------------------------------
echo -e "\n\e[1m ----- cleanup\e[0m"


#======================================================================================================================

exit 0

















exit 0
# add the fnm node to this users path
# TODO - verify permissions
echo "export PATH=/opt/fnm/aliases/default/bin:\$PATH" >> /home/companion/.bashrc



######################################################################################


exit 0

# echo -e "\n\e[1m ----- variable declarations\e[0m"
# echo -e "\n\e[1m ----- function declarations\e[0m"
# echo -e "\n\e[1m ----- satisfy requirements for installer\e[0m"
# echo -e "\n\e[1m ----- determine machine, environment, installation type and version-to-install\e[0m"
# echo -e "\n\e[1m ----- installation\e[0m"
# echo -e "\n\e[1m ----- xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx\e[0m"
# echo -e "\n\e[1m ----- cleanup\e[0m"


#======================================================================================================================
#  Developer Notes
#----------------------------------------------------------------------------------------------------------------------
: '
This script is called curl-to-bash or downloaded-executed.

Anatomy of this script:
1. variable declarations
2. parse arguments, possibly overwriting variable declarations
3. function declarations
4. satisfy requirements for installer script (incl. root)
4.1. 
4.2. 
4.3. 
4.4. 
5. determine machine, environment, installation type and version-to-install 
6. 
7. installation
7.0. perform version-specific preinstall (if exists)
7.1. perform package-based or git-based installation (git-based todo as of 2023-08-08)
7.2. satisfy requirements for companion
7.3. perform version-specific postinstall (if exists)
7.4. administrate system for companion (systemd, launch, helper scripts, …)
8. cleanup



# outline:
# 
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


Styleguide

usage of a multiline string (enclosed with : ' ... '), which is a common way in Bash to create block comments that can serve as function-level documentation or docstrings.

'
#======================================================================================================================





#######################################################################################################################
#======================================================================================================================
#**********************************************************************************************************************
#----------------------------------------------------------------------------------------------------------------------
#
#----------------------------------------------------------------------------------------------------------------------
#**********************************************************************************************************************
#----------------------------------------------------------------------------------------------------------------------
#
#----------------------------------------------------------------------------------------------------------------------
#======================================================================================================================
#######################################################################################################################
