Output assets/demo-tmux.gif

Set Shell "zsh"
Set FontSize 16
Set Width 900
Set Height 520
Set Theme "Catppuccin Mocha"
Set Padding 20
Set TypingSpeed 60ms

# Hidden setup: source wt, start a named tmux session, set prompt
Hide
Type "source $(git rev-parse --show-toplevel)/wt" Enter
Sleep 200ms
Type "cd $(git rev-parse --show-toplevel)" Enter
Sleep 200ms
Type "tmux new-session -s 'wt(main)'" Enter
Sleep 600ms
Type "source $(git rev-parse --show-toplevel)/wt" Enter
Sleep 200ms
Type "PS1='> '" Enter
Sleep 200ms
Type "clear" Enter
Sleep 300ms
Show

# Create a new worktree and immediately open it in a tmux session
Type "wt -c feature/dark-mode -t" Enter
Sleep 2500ms

# We're now in the new tmux session 'wt(feature/dark-mode)'
# Re-source wt and reset prompt (new shell in the new session)
Hide
Type "source $(git rev-parse --show-toplevel)/wt" Enter
Sleep 200ms
Type "PS1='> '" Enter
Sleep 200ms
Type "clear" Enter
Sleep 300ms
Show

# Show current directory and branch
Type "pwd && git branch --show-current" Enter
Sleep 1500ms

# Show both tmux sessions
Type "tmux ls" Enter
Sleep 2000ms

# Fuzzy-switch back to the main worktree session via wt -t
Type "wt -t" Enter
Sleep 900ms
Enter
Sleep 1500ms

# Confirm we're back on main
Type "pwd && git branch --show-current" Enter
Sleep 2000ms

# Clean up the demo worktree (hidden)
Hide
Type "wt -d" Enter
Sleep 800ms
Down
Sleep 300ms
Enter
Sleep 800ms
