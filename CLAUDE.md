# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a Doom Emacs configuration focused on org-roam note-taking with automated git workflows. The configuration implements a custom Zettelkasten system with automatic file organization, git commits, and journal management.

## Core Files

- **init.el**: Doom module configuration (which Doom features are enabled)
- **packages.el**: Custom package declarations beyond Doom defaults
- **config.el**: Personal configuration, keybindings, and custom functions

## Development Commands

### Syncing Configuration Changes

After modifying `init.el` or `packages.el`:
```bash
doom sync
```

After modifying `config.el` only, reload within Emacs:
- `M-x doom/reload` or `SPC h r r`

### Font and Theme Changes

After changing fonts in config:
- `M-x doom/reload-font`

## Architecture

The notes system is built to favor emergence over processing: daily notes are the entry point, ideas get their own note only when they earn it, and MOCs grow bottom-up. There is no fleeting inbox or tag-driven maturation. Automate mechanical actions (git, linking both sides of a MOC relationship), not decisions about where ideas belong.

### Org-Roam Directory Structure

Notes live in `~/notes`:

- `/journal/`: Daily notes, the primary entry point (`YYYY-MM-DD.org`, ID is the date)
- `/permanent/`: Evergreen notes (new notes are created here directly)
- `/literature/`: Source notes (`/literature/books/` holds older book notes)
- `/maps/`: MOC (Map of Content) files
- `/people/`: Person notes
- `/fleeting/`: Legacy; nothing new is created here and nothing is auto-moved out of it
- `/support/`: `org-roam.db` and the legacy `templates/` files (no longer used by config)

Files are never moved automatically. `SPC n m` (`mason/org-roam-move-file`) moves a file by hand and commits the move.

### Git Automation

All commits go through an async, serialized queue (`mason/notes-git-commit`), prefixed with `#desktop:`:

1. **Saves** (`mason/org-roam-auto-commit-on-save`): UPDATE commit on every save of a file in the notes repo
2. **Captures** (`mason/org-roam-auto-commit-after-capture-h`): commits the captured file after finalize
3. **Moves** (`mason/org-roam-move-file`): MOVE commit with old → new path
4. **Deletions** (`mason/org-roam-auto-commit-deletion-advice`): advice on `delete-file`

### Custom Functions

- `mason/org-roam-node-insert`: Node insertion that places the link after the cursor and re-enters insert mode
- `mason/org-roam-link-to-moc` (`SPC n p`): Follows `#+parent:` if set. Otherwise, picks (or captures) a `:moc:` node or Root (`mason/notes-root-file`), sets `#+parent:` on the note, and appends the note's link to the parent (before any sub-headings; skipped if already linked). Saves both. `C-u` re-picks even if a parent is set.
  - In a MOC, the link goes under `* Notes`. In Root, MOCs go under `* Maps of Content` and other notes under `* Other Higher-Order Notes`.
  - A MOC linked to Root is tagged `:top:`; a MOC linked to another MOC is tagged `:nest:`. Non-MOC tags are untouched.
- `mason/org-roam-dailies-ensure-date-id`: Sets a journal file's file-level ID to its date (org-roam creates a UUID). Runs on `org-roam-dailies-find-file-hook` and `before-save-hook`; idempotent.
- `mason/org-roam-move-file`: Move a file to another folder, keeping the DB in sync, and commit
- `mason/search-org-roam`: ripgrep the whole notes directory (`SPC /`)
- `mason/open-random-journal-note`: Random journal note (`SPC j r`)

### Template System

Capture templates are minimal and defined inline in config.el (title, timestamp, then writing):
- `n`: Note → `/permanent/` (listed first, so it's the default for new nodes from `SPC n f`)
- `l`: Literature → `/literature/` (`:literature:` tag, optional `#+source:`)
- `m`: MOC → `/maps/` (`:moc:` tag, single `* Notes` heading)
- `p`: Person → `/people/`
- Dailies `d`: `/journal/YYYY-MM-DD.org`

`org-roam-extract-new-file-path` is `permanent/${slug}.org`, so `SPC n x` promotes a heading (typically from a daily note) to an evergreen note.

### Key Binding Structure

- `SPC n`: Notes: find `f`, capture `c`, insert `i`, backlinks `l`/`b`, move `m`, MOC `p`, extract `x`, home `h`
- `SPC j`: Journal: today `j`/`t`, yesterday `y`, by date `d`, previous/next `p`/`n`, random `r`
- `C-c i`: Node insert in org-mode (works in insert state)
- `SPC /`: Search all notes (not just CWD)
- `SPC g P/p`: Git push/pull
- `C-x k`: Kill current buffer; `C-x K`: ibuffer

### Advice Extensions

`:after` advice on the org-roam-dailies goto functions (today, yesterday, date, previous, next) jumps to the top of the buffer.

## Package Dependencies

Custom packages (packages.el):
- `sqlite3`: Database connector for org-roam

## Database Configuration

The org-roam DB is at `~/notes/support/org-roam.db`, with the connector set to `'sqlite`. `org-roam-db-autosync-mode` keeps it current through moves and deletions.
