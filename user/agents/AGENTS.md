# Emacs project context

When working on code, use the running Emacs session as an additional source
of project context when available. Query it through `emacsclient --eval`,
using `--alternate-editor=false` so an unavailable session fails promptly.
Limit queries to buffers belonging to the project being worked on.

Check live Flymake or Flycheck diagnostics before relevant changes and after
edits have reached the existing Eglot session. Reuse Eglot's connection for
types, definitions, and references when useful; do not start another language
server just to obtain this information.

Account for unsaved buffers when comparing diagnostics with files on disk.
Do not save, revert, or overwrite the user's buffers merely to obtain context.
Diagnostics may be incomplete or delayed and do not replace required builds
or tests. If Emacs or Eglot is unavailable, continue with normal project tools.
