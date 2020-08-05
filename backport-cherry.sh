#!/bin/bash

########################
## Check requirements ##
########################
command -v hub >/dev/null 2>&1 || {
  echo "It looks like the \"hub\" command is not available. We use this to automatically create PR's";
  echo "Please install the \"hub\" command. For more information, please visit: https://github.com/github/hub";
  exit 1;
}

#################
## Help dialog ##
#################
usage="$(basename "$0") [-h|--help] [-c|--commit] [-t|--tags] [-p|--prefix] [-s|--suffix] [-r|--remote] [-v|--verbose] -- Script to cherry-pick a commit and apply it to several tags. The script will create branches based on the tags.

Parameters:
    -h|--help              Shows this help text.
    -c|--commit            The SHA of the commit to cherry-pick.
    -t|--tags              A list of tags to apply the cherry-picked commit to.
    -s|--suffix            The suffix to use for the branches
    -p|--prefix            The prefix to use for the branches (defaults to \"backport\")
    -r|--remote            The remote to push the branches to (defaults to \"origin\")
    -rb|--release-branch   Creates release branches if provided (Naming scheme \"release/[TAG]\")
    -pr|--pull-request     Automatically create a PR on Github
    -v|--verbose           Output additional information during execution"

########################
## Param verification ##
########################
declare -a tags
declare -a prUrlCollection

while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -c|--commit)
    commit="$2"
    shift # past argument
    shift # past value
    ;;
    -t|--tags)
    IFS=' ' read -r -a tags <<< "$2"
    shift # past argument
    shift # past value
    ;;
    -p|--prefix)
    prefix="$2"
    shift # past argument
    shift # past value
    ;;
    -s|--suffix)
    suffix="$2"
    shift # past argument
    shift # past value
    ;;
    -rb|--release-branch)
    createReleaseBranch=1
    shift # past argument
    ;;
    -pr|--pull-request)
    createPR=1
    shift # past argument
    ;;
    -v|--verbose)
    verbose=1
    shift # past argument
    ;;
    -h|--help)
    echo "$usage"
    exit;
    ;;
    *)    # unknown option
    echo "$1" is not a valid parameter
    echo ""
    echo "$usage"
    exit;
    ;;
esac
done

########################
## Manual param input ##
########################
if [ "$commit" == "" ]; then
  read -rp 'Commit to cherry-pick:' commit
  if [ "$commit" == "" ]; then
    echo A commit SHA is required.
    exit;
  fi
fi

if [ ${#tags[@]} -eq 0 ]; then
  echo 'Which tags would you like to update:'
  read -a tags
  if [ ${#tags[@]} -eq 0 ]; then
    echo At least 1 tag should be provided
    exit;
  fi
fi

if [ "$prefix" == "" ]; then
  read -rp 'Branch prefix [backport]:' prefix
  if [ "$prefix" == "" ]; then
    echo "Using default value \"backport\""
    prefix="backport"
  fi
fi

if [ "$suffix" == "" ]; then
  read -rp 'Branch suffix:' suffix
fi

if [ "$suffix" != "" ]; then
    suffix="/$suffix"
fi

if [ "$remote" == "" ]; then
  read -rp 'Git remote [origin]:' remote
  if [ "$remote" == "" ]; then
    echo "Using default value \"origin\""
    remote="origin"
  fi
fi

echo ""

##################
## Script logic ##
##################
for tag in "${tags[@]}"
do
  if [ "$verbose" -eq 1 ]; then
    echo Cherry-picking commit "$commit" for tag "$tag"
  fi

  branchName="$prefix/$tag$suffix"

  if [ "$verbose" -eq 1 ]; then
    echo Creating branch "$branchName"
  fi

  if ! git checkout -b "$branchName" "$tag" &> /dev/null;
  then
      echo "Git failed to checkout branch \"$branchName\"."
      echo "Command that failed was \"git checkout -b $branchName $tag\""
      exit 1;
  fi

  if [ "$verbose" -eq 1 ]; then
    echo Cherry picking commit "$commit"
  fi

  if ! git cherry-pick -x "$commit" &> /dev/null;
  then
      echo "Unable to cherry-pick commit \"$commit\"."
      echo "Command that failed was \"git cherry-pick -x $commit\""
      exit 1;
  fi

  if [ "$verbose" -eq 1 ]; then
    echo Pushing branch to remote "$remote"
  fi

  if ! git push -u "$remote" "$branchName" &> /dev/null;
  then
      echo "Unable to push \"$branchName\" to \"$remote\"."
      echo "Command that failed was \"git push -u $remote $branchName\""
      exit 1;
  fi

  #############################
  ## Release branch creation ##
  #############################
  if [ "$createReleaseBranch" -eq 1 ]; then
    releaseBranchName="release/${tag//v}";

    if [ "$verbose" -eq 1 ]; then
      echo Creating release branch "$releaseBranchName"
    fi

    if ! git checkout -b "$releaseBranchName" "$tag" &> /dev/null;
    then
      echo "Git failed to checkout branch \"$releaseBranchName\"."
      exit 1;
    fi

    if [ "$verbose" -eq 1 ]; then
      echo Pushing release branch to remote "$remote"
    fi

    if ! git push -u "$remote" "$releaseBranchName" &> /dev/null;
    then
        echo "Unable to push \"$releaseBranchName\" to \"$remote\"."
        exit 1;
    fi

    #################
    ## PR Creation ##
    #################
    if [ "$createPR" -eq 1 ]; then
      if [ "$verbose" -eq 1 ]; then
        echo Creating PR from branch "$branchName" '>' "$releaseBranchName"
      fi
      prUrl=$(hub pull-request --no-edit --base "$releaseBranchName" --head "$branchName");
      prUrlCollection+=("$prUrl")
    fi
  fi

  echo "Cherry-picked \"$commit\" into new branch \"$branchName\", and pushed to \"$remote\"

--------------------------------------------------------------------------------------------
";
done

if [ "$createPR" -eq 1 ]; then
  echo "You've chosen to create PR's. Here are the links to the created pull-requests"
  for url in "${prUrlCollection[@]}"
  do
     echo "$url"
  done
fi

echo Finished picking cherries!;