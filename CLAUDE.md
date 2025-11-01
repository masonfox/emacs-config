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

### Org-Roam Directory Structure

The configuration manages notes in `~/notes` with automatic organization:

- `/fleeting/`: New zettel and literature notes (temporary staging)
- `/permanent/`: Mature zettel notes (auto-moved when `:fleeting:` tag removed)
- `/literature/`: Finalized literature notes (auto-moved when `:fleeting:` tag removed)
- `/journal/`: Daily journal entries
- `/maps/`: MOC (Map of Content) files
- `/people/`: Person-specific notes
- `/templates/`: Note templates (excluded from auto-organization)

### Automatic File Organization

Files are automatically moved between directories on save based on tags (config.el:262-335):
- `:zettel:` (without `:fleeting:`) → `/permanent/`
- `:literature:` (without `:fleeting:`) → `/literature/`
- Tagged moves trigger git commits with descriptive messages

### Git Automation

Three auto-commit mechanisms are active:

1. **Regular saves** (config.el:401-407): Commits with timestamp on every save
2. **File moves** (config.el:319-328): Commits showing old → new path
3. **File deletions** (config.el:339-367): Commits deletions automatically via advice on `delete-file`

All commits are prefixed with `#desktop:` for identification.

### Custom Functions

Key custom functions in config.el:

- `mason/org-roam-node-insert` (122-169): Enhanced node insertion that cleans whitespace and maintains insert mode
- `mason/org-roam-dailies-remove-duplicate-id` (174-193): Removes auto-generated IDs from journal entries
- `mason/org-roam-goto-or-insert-parent` (200-227): Navigate to or insert parent links
- `mason/org-roam-move-file` (231-258): Move files while keeping org-roam DB in sync
- `mason/org-roam-auto-organize-by-tag` (262-335): Core auto-organization logic
- `mason/org-roam-auto-commit` (386-410): Git automation for saves
- `mason/search-org-roam` (89-93): Search entire org-roam directory (overrides `SPC /`)

### Template System

Capture templates (config.el:457-477):
- `z`: Zettel notes → `/fleeting/`
- `l`: Literature notes → `/fleeting/`
- `m`: MOC notes → `/maps/`
- `p`: Person notes → `/people/`
- `d`: Daily journal → `/journal/` (YYYY-MM-DD.org format)

Templates are loaded from `~/notes/templates/` directory.

### Key Binding Structure

Custom leader key prefixes:
- `SPC n`: Note operations (find, capture, insert, move, parent navigation)
- `SPC j`: Journal operations (daily notes, random note)
- `SPC /`: Overridden to search all org-roam notes (not just CWD)
- `SPC g P/p`: Git push/pull shortcuts
- `C-x k`: Kill current buffer (overridden from default)
- `C-x K`: Open ibuffer for bulk operations

### Advice Extensions

The config adds `:after` advice to org-roam-dailies functions (config.el:481-485) to jump to top of buffer:
- `org-roam-dailies-goto-date`
- `org-roam-dailies-goto-yesterday`
- `org-roam-dailies-goto-today`
- `org-roam-dailies-find-previous-note`
- `org-roam-dailies-find-next-note`

## Important Behaviors

### Whitespace and Insert Mode

Custom node insertion functions clean up unwanted spaces that org-roam-node-insert creates and automatically re-enter evil insert mode for workflow continuity.

### Template Files Are Protected

The auto-organization function explicitly skips files in the `/templates/` directory to prevent template files from being moved.

### Git Integration

All org-roam operations that modify the filesystem automatically create git commits. The repository at `~/notes` should be a git repository for this to work properly.

## Package Dependencies

Custom packages (packages.el):
- `sqlite3`: Database connector for org-roam
- `everforest`: Alternative theme (from GitHub)

## Database Configuration

Org-roam uses SQLite with database location at `~/notes/org-roam.db`. The connector is explicitly set to 'sqlite (config.el:443).
