# backport-cherry 🍒 

[![MIT License](https://img.shields.io/apm/l/atomic-design-ui.svg?)](https://github.com/Skullsneeze/backport-cherry/blob/master/LICENSE)
[![GitHub Release](https://img.shields.io/github/release/tterb/PlayMusic.svg?style=flat)](https://github.com/Skullsneeze/backport-cherry/releases/tag/v1.0.0)

This script was created as tool to make it easier to backport the changes of a commit to several tags.

## Installation

### Homebrew (recommended)
There is a homebrew tap available. use the following commands to install the backport-cherry command

```
$ brew tap Skullsneeze/backport-cherry
$ brew install backport-cherry
```

### Manual installation
You can also manually install this command. To achieve this, download the script, and call it by using the full path.

## How to use?
You can simply call the command, and you will be promted to input the required arguments. You can howerver also choose to supply your arguments beforehand.

### Usage
```
backport-cherry [-h|--help] [-c|--commit abcd1234] [-t|--tags "v1.0.0 v1.0.1 "] [-p|--prefix backport] [-s|--suffix fixed-an-issue] [-r|--remote origin] [-rb|--release-branch] [-pr|--pull-request] [-v|--verbose]
```

### Arguments
| Argument | Description |
| --- | --- |
| `-h\|--help` | Display this help dialog. |
| `-c\|--commit` | The SHA of the commit to cherry-pick. |
| `-t\|--tags` | A list of tags (separated by a single space) to apply the cherry-picked commit to. |
| `-s\|--suffix` | The suffix to use for the branches |
| `-p\|--prefix` | The prefix to use for the branches (defaults to 'backport') |
| `-r\|--remote` | The remote to push the branches to (defaults to 'origin') |
| `-rb\|--release-branch` | Creates release branches if provided (Naming scheme 'release/[TAG]') |
| `-pr\|--pull-request` | Automatically create a PR to the release branch on Github. Requires the 'hub' command. More information: https://github.com/github/hub |
| `-v\|--verbose` | Output additional information during execution |

### Example
```
backport-cherry -c "d71b8b30465019e51e52cf41625c225a315dc63f" -t "v2.1.0 v2.1.2 v2.2.0 v3.8.1 v3.8.5" -p "bugfix/" -s "fix-an-old-bug" -r "my-other-remote" -rb -pr -v
```

1. First this command will create branch based on the first tag in the list of defined tags (`-t`). In this case the first tag is v2.1.0.
2. The branch that is created will be named `bugfix/v2.1.0/fix-an-old-bug`. The naming scheme is a combination of the prefix (`-p`), current tag, and suffix (`-s`).
3. After the branch is created, the commit (`-c`) will be cherry picked, and silently applied to the new branch. By default the commit message will state that the change was cherry-picked.
4. Next the branch will be pushed to the defined remote (`-r`). This automatically sets up trakcing, so your local branch tracks changes on your remote branch.
5. Then we create a release branch (`-rb`) based on the current tag. This follows the naming patters `release/` followed by the tag (minus the letter v if applicable).
6. We also push this branch to our remote (`-r) and setup tracking.
7. Finally we create a pull-request on GitHub. This PR uses the branch created in step 1 as the head branch, and the release branch created in step 5 as the base.

