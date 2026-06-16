Output assets/demo.gif

Set Shell "zsh"
Set FontSize 16
Set Width 900
Set Height 520
Set Theme "Catppuccin Mocha"
Set Padding 20
Set TypingSpeed 60ms

# Hidden setup: source wt, simple prompt, clean screen
Hide
Type "source $(git rev-parse --show-toplevel)/wt" Enter
Sleep 300ms
Type "PS1='> '" Enter
Sleep 200ms
Type "cd $(git rev-parse --show-toplevel)" Enter
Sleep 200ms
Type "clear" Enter
Sleep 300ms
Show

# 1. Show help
Type "wt -h" Enter
Sleep 3500ms
Type "clear" Enter
Sleep 300ms

# 2. Create a new worktree for a feature branch
Type "wt -c feature/dark-mode" Enter
Sleep 2500ms

Type "pwd && git branch --show-current" Enter
Sleep 2000ms

# 3. Navigate back to main, then fuzzy-pick the worktree
Hide
Type "cd $(git rev-parse --show-toplevel)" Enter
Sleep 200ms
Type "clear" Enter
Sleep 300ms
Show

Type "wt" Enter
Sleep 900ms
Down
Sleep 500ms
Enter
Sleep 1200ms

Type "pwd" Enter
Sleep 2000ms

# 4. Delete the worktree from within it
Type "wt -d ." Enter
Sleep 2500ms

Type "git worktree list" Enter
Sleep 2500ms
