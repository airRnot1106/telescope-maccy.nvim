Output vhs/demo.gif

Set Shell "bash"
Set FontSize 18
Set Width 1500
Set Height 900
Set Padding 20
Set TypingSpeed 60ms
Set PlaybackSpeed 1.0

# Start on an empty buffer.
Type "nvim"
Enter
Sleep 1.5s

# Open the Maccy clipboard-history picker.
Type ":Telescope maccy"
Sleep 800ms
Enter
Sleep 2.5s

# Browse the history; the preview pane follows the selection.
Down@500ms 2
Sleep 1.5s

# Fuzzy-filter down to a multi-line snippet (folded as a↵b in the list,
# shown in full in the preview).
Type "greet"
Sleep 2.5s

# Select it: the raw value is copied into the " and + registers.
Enter
Sleep 1s

# Paste it back to prove the entry really landed in the register.
Type "o"
Escape
Type "p"
Sleep 2.5s

Type ":q!"
Enter
Sleep 1s
