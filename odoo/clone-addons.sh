#!/bin/bash

set -e

# Constructs the appropriate git clone command based on repository type
#
# Args:
#   $1 (repo_type): Type of repository - 'private', 'enterprise', or 'public'
#   $2 (repo_url): URL of the git repository to clone
#
# Returns:
#   The constructed git clone command as a string with appropriate authentication
construct_clone_command() {
    local repo_type=$1
    local repo_url=$2
    case $repo_type in
        private) echo "git clone https://${GITHUB_USER}:${GITHUB_ACCESS_TOKEN}@${repo_url#https://}" ;;
        enterprise) echo "git clone https://${ENTERPRISE_USER}:${ENTERPRISE_ACCESS_TOKEN}@${repo_url#https://} ${ENTERPRISE_ADDONS}" ;;
        public) echo "git clone $repo_url" ;;
    esac
}

# Clones a repository and copies specified modules based on conditions
#
# Args:
#   $1 (repo_type): Type of repository - 'private', 'enterprise', or 'public'
#   $2 (repo_url): URL of the git repository to clone
#   $@ (modules_conditions): Array of alternating module names and boolean conditions
#
# Example:
#   clone_and_copy_modules public "https://github.com/example/repo.git" "module1" true "module2" false
clone_and_copy_modules() {
    local repo_type=$1
    local repo_url=$2
    local clone_cmd=$(construct_clone_command $repo_type $repo_url)
    local repo_name=$(basename -s .git "$repo_url")

    shift 2
    local modules_conditions=("$@")

    # Clone and copy logic for enterprise repository
    if [[ $repo_type == "enterprise" ]]; then
        if [ -n "$GITHUB_USER" ] && [ -n "$GITHUB_ACCESS_TOKEN" ]; then
            $clone_cmd --depth 1 --branch ${ODOO_TAG} --single-branch --no-tags
        fi
    else
        # Determine if any module has a true condition
        local should_clone=false
        if [[ ${#modules_conditions[@]} -eq 1 ]]; then
            [[ ${modules_conditions[0]} == true ]] && should_clone=true
        else
            for (( i=1; i<${#modules_conditions[@]}; i+=2 )); do
                if [[ ${modules_conditions[i]} == true ]]; then
                    should_clone=true
                    break
                fi
            done
        fi

        # Clone the repo if should_clone is true and it's not already cloned
        if [[ $should_clone == true && ! -d "$repo_name" ]]; then
            $clone_cmd --depth 1 --branch ${ODOO_TAG} --single-branch --no-tags
        fi

        # Copy the modules if the condition is true
        if [[ $should_clone == true ]]; then
            for (( i=0; i<${#modules_conditions[@]}; i+=2 )); do
                local module=${modules_conditions[i]}
                local condition=${modules_conditions[i+1]}
                if [[ $condition == true ]]; then
                    echo "Copying ${module} from ${repo_name} into ${THIRD_PARTY_ADDONS}"
                    cp -r /${repo_name}/${module} ${THIRD_PARTY_ADDONS}/${module}
                fi
            done
        fi
    fi
}

# Expands environment variables in a string, defaulting to 'false' if unset
#
# Args:
#   $1: String containing environment variables in ${VAR} format
#
# Returns:
#   String with all environment variables expanded
#
# Example:
#   expand_env_vars "module1 ${USE_REDIS} module2 ${USE_S3}"
#   -> "module1 true module2 false" (assuming USE_REDIS=true and USE_S3 unset)
expand_env_vars() {
    while IFS=' ' read -r -a words; do
        for word in "${words[@]}"; do
            if [[ $word == \$\{* ]]; then
                # Remove the leading '${' and the trailing '}' from the word
                varname=${word:2:-1}
                # Check if the variable is set and not empty
                if [ -n "${!varname+x}" ]; then
                    echo -n "${!varname} " # Substitute with its value
                else
                    echo -n "false " # Default to false if not set
                fi
            else
                echo -n "$word "
            fi
        done
        echo
    done <<< "$1"
}

# This section reads third-party-addons.txt line by line and:
# 1. Creates directories for enterprise and third party addons if they don't exist
# 2. Skips empty lines and comments (lines starting with #)
# 3. For each valid line:
#    - Expands any environment variables (e.g. ${USE_REDIS} -> true/false)
#    - Calls clone_and_copy_modules with the expanded line to:
#      a) Clone the git repo if needed
#      b) Copy specified modules based on their conditions
echo "
#####################################################
#                                                   #
#           CLONING THIRD PARTY ADDONS             #
#                                                   #
#####################################################
"

while IFS= read -r line; do
    mkdir -p ${ENTERPRISE_ADDONS}
    mkdir -p ${THIRD_PARTY_ADDONS}
    [[ -z "$line" || "$line" == \#* ]] && continue
    clone_and_copy_modules $(expand_env_vars "$line")
done < "third-party-addons.txt"

echo "
#####################################################
#                                                   #
#         FINISHED CLONING THIRD PARTY ADDONS       #
#                                                   #
#####################################################
"
