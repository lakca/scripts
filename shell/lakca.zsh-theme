#!/usr/bin/env zsh
# #
# # #README
# #
# # This theme provides two customizable header functionalities:
# # a) displaying a pseudo-random message from a database of quotations
# # (https://en.wikipedia.org/wiki/Fortune_%28Unix%29)
# # b) displaying randomly command line tips from The command line fu
# # (https://www.commandlinefu.com) community: in order to make use of this functionality
# # you will need Internet connection.
# # This theme provides as well information for the current user's context, like;
# # branch and status for the current version control system (git and svn currently
# # supported) and time, presented to the user in a non invasive volatile way.
# #
# # #REQUIREMENTS
# # This theme requires wget::
# # -Homebrew-osx- brew install wget
# # -Debian/Ubuntu- apt-get install wget
# # and fortune ::
# # -Homebrew-osx- brew install fortune
# # -Debian/Ubuntu- apt-get install fortune
# #
# # optionally:
# # -Oh-myzsh vcs plug-ins git and svn.
# # -Solarized theme (https://github.com/altercation/solarized/)
# # -OS X: iTerm 2 (https://iterm2.com/)
# # -font Source code pro (https://github.com/adobe/source-code-pro)
# #
# # This theme's look and feel is based on the Aaron Toponce's zsh theme, more info:
# # https://pthree.org/2008/11/23/727/
# # enjoy!
########## COLOR ###########
for COLOR in CYAN WHITE YELLOW MAGENTA BLACK BLUE RED DEFAULT GREEN GREY; do
    eval PR_$COLOR='%{$fg[${(L)COLOR}]%}'
done
PR_RESET="%{$reset_color%}"
JOINER_COLOR="$FG[240]"
VCS_DIRTY_COLOR="${PR_RESET}${PR_RED}"
VCS_CLEAN_COLOR="${PR_RESET}${PR_GREEN}"
VCS_INFO_COLOR="${PR_RESET}${PR_YELLOW}"
VCS_SUFIX_COLOR="${PR_RESET}"
# ########## COLOR ###########
# ########## GIT ###########
ZSH_THEME_GIT_PROMPT_PREFIX=""
ZSH_THEME_GIT_PROMPT_SUFFIX=""
ZSH_THEME_GIT_PROMPT_DIRTY="${VCS_DIRTY_COLOR}✘${VCS_SUFIX_COLOR}"
ZSH_THEME_GIT_PROMPT_CLEAN="${VCS_CLEAN_COLOR}✔${VCS_SUFIX_COLOR}"

ZSH_THEME_GIT_PROMPT_UNTRACKED="Untracked "
ZSH_THEME_GIT_PROMPT_MODIFIED="Modified "
ZSH_THEME_GIT_PROMPT_ADDED="Added "
ZSH_THEME_GIT_PROMPT_RENAMED="Renamed "
ZSH_THEME_GIT_PROMPT_DELETED="Deleted "
ZSH_THEME_GIT_PROMPT_STASHED="Stashed "
ZSH_THEME_GIT_PROMPT_UNMERGED="Unmerged "
ZSH_THEME_GIT_PROMPT_AHEAD="Ahead "
ZSH_THEME_GIT_PROMPT_BEHIND="Behind "
ZSH_THEME_GIT_PROMPT_DIVERGED="Diverged "
ZSH_THEME_GIT_PROMPT_REMOTE_EXISTS=""
ZSH_THEME_GIT_PROMPT_REMOTE_MISSING=""

# ########## GIT ###########
function precmd {
    return
    #gets the fortune
    ps1_fortune () {
        #Choose from all databases, regardless of whether they are considered "offensive"
        fortune -s
    }
    #obtains the tip
    ps1_command_tip () {
        wget -qO - http://www.commandlinefu.com/commands/random/plaintext | sed 1d | sed '/^$/d'
    }
    prompt_header () {
        if [[ "true" == "$ENABLE_COMMAND_TIP" ]]; then
            ps1_command_tip
        else
            ps1_fortune
        fi
    }
    PROMPT_HEAD="$(prompt_header)"
    # set a simple variable to show when in screen
    if [[ -n "${WINDOW}" ]]; then
        SCREEN=""
    fi
}

function git_current_branch_upstream {
   echo $(__git_prompt_git branch --format="%(upstream:short)" --points-at HEAD)
}

# Context: user@directory or just directory
prompt_context () {
    text+="${JOINER_COLOR}[`jobs | grep '^\[' | wc -l | xargs`]${PR_RESET} " # prevent 'pwd now:...'
    text+="${JOINER_COLOR}%D{%R}${PR_RESET} "
    if [[ -n "$SSH_CLIENT" ]]; then
        text+="${PR_RESET}${PR_RED}$USER@%m "
    else
        text+="${PR_RESET}${PR_BLUE}$USER:"
    fi
    text+="${PR_RESET}${PR_BLUE}%~%<<"
    if [[ -n "$(git_repo_name)" ]]; then
        text+="${PR_RESET} ${VCS_INFO_COLOR}$(git_current_user_name)"
        text+="${PR_RESET} ${JOINER_COLOR}at${PR_RESET} ${VCS_INFO_COLOR}$(git_repo_name)"
        if [[ -n "$(git_current_branch)" ]]; then
            text+="${PR_RESET} ${JOINER_COLOR}on${PR_RESET} ${VCS_INFO_COLOR}$(git_current_branch)"
        fi
        if [[ -n "$(git_prompt_status)" ]]; then
            text+="${PR_RESET} (${VCS_DIRTY_COLOR}${$(git_prompt_status)%\ }${PR_RESET})"
        fi
        if [[ -n "$(git_prompt_short_sha)" ]]; then
            text+="${PR_RESET} ${VCS_INFO_COLOR}$(git_prompt_short_sha)"
        fi
        if [[ $(git_commits_ahead) -gt 0 ]]; then
            text+="${PR_RESET} ${PR_MAGENTA}👆 $(git_commits_ahead)"
        fi
        if [[ $(git_commits_behind) -gt 0 ]]; then
            text+="${PR_RESET} ${PR_MAGENTA}👇 $(git_commits_behind)"
        fi
        if [[ -n "$(git_current_branch_upstream)" ]]; then
            text+="${PR_RESET} ${JOINER_COLOR}to${PR_RESET} ${VCS_INFO_COLOR}$(git_current_branch_upstream)"
        fi
        if [[ -n "$(parse_git_dirty)" ]]; then
            text+="${PR_RESET} $(parse_git_dirty)"
        fi
    fi
    echo -n "$text"
    unset text
}

set_prompt () {
    # required for the prompt
    setopt prompt_subst
    autoload zsh/terminfo

    # ######### PROMPT #########
    # RPROMPT="${PR_RED}$FG[240]%D{%R}${PR_RESET}"

    PROMPT='${PROMPT_HEAD}'$'\n'
    PROMPT+='$(prompt_context)'$'\n'
    PROMPT+='${PR_RESET}${PR_GREEN}~${PR_RESET} '

    # Matching continuation prompt
    PROMPT2='${PR_RESET}${PR_GREEN}~${PR_RESET} %_'
    # ######### PROMPT #########
}

set_prompt
