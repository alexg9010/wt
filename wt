#!/bin/bash

set -o pipefail 2>/dev/null || true

# Optional: set WORKTREE_ROOT to store worktrees outside the repo (default: <repo>/.worktrees)

wt() {
  local create=false
  local delete=false
  local issue=false
  local pr=false
  local copy_envrc=false
  local tmux_session=false
  local kill_sessions=false
  local name=""
  local target=""
  local root
  local base

  _wt_usage() {
    cat <<USAGE
Usage: wt [-i] [-p] [-c [name]] [-e] [-t] [-d [path]] [-k] [-h]

Options:
  -i          Select and check out a GitHub issue (requires gh)
  -p          Select and check out a GitHub pull request (requires gh)
  -c [name]   Create a worktree; if no name given, select branch via fzf
  -e          Copy .envrc from root and run direnv allow (use with -c)
  -t          Start a new tmux session for the worktree (use with -c, or alone to select)
  -d [path]   Delete a worktree (fuzzy select if no path given, use '.' for current)
  -k          Kill all tmux sessions for this repo's worktrees
  -h          Show this help message
USAGE
  }

  # Portable realpath
  _wt_realpath() {
    if command -v realpath &>/dev/null; then
      realpath "$1"
    else
      cd "$1" 2>/dev/null && pwd || echo "$1"
    fi
  }

  _wt_worktree_paths() {
    git worktree list --porcelain | sed -n 's/^worktree //p'
  }

  _wt_session_name() {
    local wt_path_arg="$1"
    local main_wt
    main_wt=$(_wt_worktree_paths | head -n 1)
    local repo_name
    repo_name=$(basename "$main_wt" | tr '.' '_')
    local branch_name
    branch_name=$(git -C "$wt_path_arg" rev-parse --abbrev-ref HEAD 2>/dev/null | tr '/' '-')
    echo "${repo_name}(${branch_name})"
  }

  _wt_tmux() {
    command -v tmux >/dev/null 2>&1 || { echo "Error: tmux is required for session switching"; return 1; }
    local wt_path_arg="$1"
    local session_name
    session_name=$(_wt_session_name "$wt_path_arg")
    if tmux has-session -t "$session_name" 2>/dev/null; then
      echo "Attaching to existing tmux session: $session_name"
    else
      echo "Starting tmux session: $session_name"
      tmux new-session -d -s "$session_name" -c "$wt_path_arg"
    fi
    tmux switch-client -t "$session_name" 2>/dev/null || tmux attach-session -t "$session_name"
  }

  _wt_is_main() {
    local wt_path_arg="$1"
    local main_wt
    main_wt=$(_wt_worktree_paths | head -n 1)
    [[ "$(_wt_realpath "$wt_path_arg")" == "$(_wt_realpath "$main_wt")" ]]
  }

  _wt_navigate() {
    local wt_path_arg="$1"
    if $tmux_session || [[ -n "$TMUX" ]]; then
      _wt_tmux "$wt_path_arg"
    else
      cd "$wt_path_arg"
    fi
  }


  _wt_init() {
    local wt_dir="$1"
    if [[ ! -d "$wt_dir" ]]; then
      mkdir -p "$wt_dir"
      echo "Created $wt_dir"
    else
      echo "$wt_dir already exists"
    fi
    if [[ "$wt_dir" == "$root/"* ]]; then
      local rel="${wt_dir#"$root/"}"
      local gitignore="$root/.gitignore"
      if ! grep -qxF "$rel/" "$gitignore" 2>/dev/null; then
        echo "$rel/" >> "$gitignore"
        echo "Added $rel/ to .gitignore"
      else
        echo "$rel/ already in .gitignore"
      fi
    fi
  }

  _wt_create() {
    if [[ -z "$name" ]]; then
      command -v fzf >/dev/null 2>&1 || {
        echo "Error: fzf is required when no branch name is provided"; return 1;
      }
      local fzf_out fzf_exit
      fzf_out=$(git branch -a --format='%(refname:short)' \
        | sed 's|^origin/||' \
        | grep -v '^HEAD$' \
        | sort -u \
        | fzf --height 40% --reverse --prompt="branch> " --print-query)
      fzf_exit=$?
      [[ $fzf_exit -ge 130 ]] && return 0
      name=$(printf '%s' "$fzf_out" | tail -1)
      [[ -z "$name" ]] && return 0
    fi
    [[ ! -d "$base" ]] && _wt_init "$base" >/dev/null
    local new_path
    new_path="$base/$name"
    local existing
    existing=$(_wt_worktree_paths | while IFS= read -r wt_path; do
      branch=$(git -C "$wt_path" rev-parse --abbrev-ref HEAD 2>/dev/null)
      [[ "$branch" == "$name" ]] && echo "$wt_path" && break
    done)
    if [[ -n "$existing" ]]; then
      echo "Worktree for '$name' already exists at $existing"
      _wt_navigate "$existing"
      return 0
    fi
    if git show-ref --verify --quiet "refs/heads/$name"; then
      git worktree add "$new_path" "$name" || return 1
    elif git show-ref --verify --quiet "refs/remotes/origin/$name"; then
      git worktree add --track -b "$name" "$new_path" "origin/$name" || return 1
    else
      git worktree add "$new_path" -b "$name" || return 1
    fi
    if $copy_envrc && [[ -f "$root/.envrc" ]]; then
      command -v direnv >/dev/null 2>&1 || { echo "Error: direnv is required for -e"; return 1; }
      cp "$root/.envrc" "$new_path/.envrc"
      direnv allow "$new_path/.envrc"
    fi
    _wt_navigate "$new_path"
  }


  _wt_issue() {
    command -v gh >/dev/null 2>&1 || { echo "Error: gh is required for -i"; return 1; }
    command -v fzf >/dev/null 2>&1 || { echo "Error: fzf is required for -i"; return 1; }
    local selected
    selected=$(gh issue list | fzf --height 40% --reverse --prompt="issue> ")
    [[ -z "$selected" ]] && return 0
    name="issue/$(awk '{print $1}' <<< "$selected")"
    _wt_create
  }

  _wt_pr() {
    command -v gh >/dev/null 2>&1 || { echo "Error: gh is required for -p"; return 1; }
    command -v fzf >/dev/null 2>&1 || { echo "Error: fzf is required for -p"; return 1; }
    local selected
    selected=$(gh pr list | fzf --height 40% --reverse --prompt="pr> ")
    [[ -z "$selected" ]] && return 0
    local pr_num
    pr_num=$(awk '{print $1}' <<< "$selected")
    local pr_branch
    pr_branch=$(gh pr view "$pr_num" --json headRefName --jq '.headRefName' 2>/dev/null)
    [[ -z "$pr_branch" ]] && { echo "Error: could not resolve branch for PR #$pr_num"; return 1; }
    [[ ! -d "$base" ]] && _wt_init "$base" >/dev/null
    local new_path="$base/pr/$pr_num"
    if _wt_worktree_paths | grep -qxF "$new_path"; then
      echo "Worktree for PR #$pr_num already exists at $new_path"
      _wt_navigate "$new_path"
      return 0
    fi
    if git show-ref --verify --quiet "refs/heads/pr/$pr_num"; then
      git worktree add "$new_path" "pr/$pr_num" || return 1
    else
      git worktree add --track -b "pr/$pr_num" "$new_path" "origin/$pr_branch" || return 1
    fi
    _wt_navigate "$new_path"
  }

  _wt_delete() {
    local to_delete
    if [[ -n "$target" ]]; then
      to_delete=$(_wt_realpath "$target")
    else
      command -v fzf >/dev/null 2>&1 || {
        echo "Error: fzf is required when no worktree path is provided"; return 1;
      }
      to_delete=$(_wt_worktree_paths | tail -n +2 | fzf --height 40% --reverse)
    fi
    [[ -z "$to_delete" ]] && return 0
    if _wt_is_main "$to_delete"; then
      echo "Error: cannot delete main worktree"; return 1
    fi
    local main_wt
    main_wt=$(_wt_worktree_paths | head -n 1)
    local session_name
    session_name=$(_wt_session_name "$to_delete")
    local cur_path
    cur_path=$(_wt_realpath .)
    [[ "$cur_path" == "$to_delete" || "$cur_path" == "$to_delete/"* ]] && cd "$main_wt"
    git worktree remove "$to_delete" || return 1
    if tmux has-session -t "$session_name" 2>/dev/null; then
      tmux kill-session -t "$session_name"
      echo "Killed tmux session: $session_name"
    fi
  }

  _wt_kill_sessions() {
    command -v tmux >/dev/null 2>&1 || { echo "Error: tmux is required for -k"; return 1; }
    local killed=0
    while IFS= read -r wt_path; do
      local session_name
      session_name=$(_wt_session_name "$wt_path")
      if tmux has-session -t "$session_name" 2>/dev/null; then
        tmux kill-session -t "$session_name"
        echo "Killed tmux session: $session_name"
        ((killed++))
      fi
    done < <(_wt_worktree_paths)
    [[ $killed -eq 0 ]] && echo "No active tmux sessions found for this repo"
  }

  # --- parse args ---

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -i) issue=true; shift ;;
      -p) pr=true; shift ;;
      -c) create=true; shift; [[ $# -gt 0 && ! "$1" =~ ^- ]] && { name="$1"; shift; } ;;
      -e) copy_envrc=true; shift ;;
      -t) tmux_session=true; shift ;;
      -d) delete=true; shift; [[ $# -gt 0 && ! "$1" =~ ^- ]] && { target="$1"; shift; } ;;
      -k) kill_sessions=true; shift ;;
      -h) _wt_usage; return 0 ;;
      *) _wt_usage; return 1 ;;
    esac
  done

  if ($create || $copy_envrc) && $delete; then
    echo "Error: -c/-e and -d are mutually exclusive"; return 1
  fi

  root=$(_wt_worktree_paths 2>/dev/null | head -n 1)
  [[ -z "$root" ]] && { echo "Error: not in a git repo"; return 1; }
  base="${WORKTREE_ROOT:-$root/.worktrees}"

  # --- dispatch ---

  if $issue;         then _wt_issue;         return $?; fi
  if $pr;            then _wt_pr;            return $?; fi
  if $create;        then _wt_create;        return $?; fi
  if $delete;        then _wt_delete;        return $?; fi
  if $kill_sessions; then _wt_kill_sessions; return $?; fi

  # default: select and navigate to existing worktree
  command -v fzf >/dev/null 2>&1 || {
    echo "Error: fzf is required when no worktree path is provided"; return 1;
  }
  local selected
  selected=$(_wt_worktree_paths | fzf --height 40% --reverse)
  [[ -z "$selected" ]] && return 0
  _wt_navigate "$selected"
}

_wt_sourced=false
if [[ -n "${BASH_VERSION:-}" ]]; then
  [[ "${BASH_SOURCE[0]}" != "$0" ]] && _wt_sourced=true
elif [[ -n "${ZSH_VERSION:-}" ]]; then
  [[ "$ZSH_EVAL_CONTEXT" == *:file ]] && _wt_sourced=true
fi

if ! $_wt_sourced; then
  wt "$@"
fi
