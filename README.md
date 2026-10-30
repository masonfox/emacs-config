# Emacs Config

A [Doom Emacs](https://github.com/doomemacs/doomemacs) configuration built around a personal note-taking system: [org-roam](https://www.orgroam.com/) notes in plain text, with a daily journal as the entry point and every change committed to git automatically.

**The idea:** write in today's journal first. Give an idea its own note only when it earns one, then connect notes through Maps of Content (MOCs) that grow from the bottom up. There's no inbox to process and no tags to maintain. The config handles the mechanical work (git commits, linking both sides of a MOC relationship) and leaves decisions about where ideas belong to you.

## Contents

- [Installation](#installation)
- [Emacs basics](#emacs-basics)
- [A typical workflow](#a-typical-workflow)
- [Commands](#commands)
- [Note types](#note-types)
- [How your notes are organized](#how-your-notes-are-organized)
- [Maps of Content](#maps-of-content)
- [Automatic git commits](#automatic-git-commits)
- [Making it your own](#making-it-your-own)
- [What else is included](#what-else-is-included)

## Installation

### Requirements

- **Emacs** built with SQLite support (Emacs 29 or newer, within the range Doom supports). Last used with Emacs 30.2 and Doom as of October 2026.
- **git**, with `user.name` and `user.email` configured. Commits to your notes fail without them.
- **[ripgrep](https://github.com/BurntSushi/ripgrep)** and **[fd](https://github.com/sharkdp/fd)**
- **[JetBrains Mono](https://www.jetbrains.com/lp/mono/)** font

### 1. Install the config and Doom

```bash
git clone https://github.com/masonfox/emacs-config ~/.config/doom
git clone --depth 1 https://github.com/doomemacs/core ~/.config/emacs
~/.config/emacs/bin/doom install --no-config
```

`--no-config` tells Doom to use the config you just cloned instead of creating its own starter files. If you already have a `~/.config/doom`, move it out of the way first.

Add `~/.config/emacs/bin` to your `PATH` to get the `doom` command, then run `doom doctor` to check for missing dependencies. It may also list tools for optional features, such as a spell checker.

### 2. Create your notes folder

Notes live in `~/notes`, which must be a git repository:

```bash
mkdir -p ~/notes/journal && cd ~/notes
git init
printf '.orgids\n/support/org-roam.db\n' > .gitignore
printf '#+title: Root\n' > root.org
git add . && git commit -m "Initial notes"
```

The `.gitignore` keeps out two files that Emacs regenerates. `root.org` is the home page of your notes.

To back your notes up to a remote, add one and push once with `git push -u origin HEAD`. This sets the upstream that `SPC g P` pushes to.

### 3. First launch

1. Start Emacs. If icons show up as empty boxes, run `M-x nerd-icons-install-fonts` and restart.
2. Press `SPC n h` to open `root.org`.
3. With the cursor at the very top of the file, run `M-x org-id-get-create` and save with `C-x C-s`. This registers Root as a note so it can be linked to later.
4. Press `SPC j t` to open today's journal and start writing.

## Emacs basics

If you're new to Doom, this is enough to get started:

- Editing uses Vim keys. Press `i` to type and `Esc` to go back to normal mode.
- `SPC` opens the command menu in normal mode. Pause after pressing it, or after any prefix like `SPC n`, to see the available keys.
- **`SPC` commands don't work while you're typing.** Press `Esc` first. To link a note mid-sentence, use `C-c i`, which works while typing.
- `C-` means Ctrl and `M-` means Alt, so `C-c i` is Ctrl+C followed by `i`.
- In a new note's capture window, `C-c C-c` saves and `C-c C-k` discards.

## A typical workflow

1. **Write in the journal.** `SPC j j` opens today's note, creating it if needed. Everything starts here.
2. **Link as you go.** `C-c i` links to an existing note, or creates a new one if you type a title that doesn't exist.
3. **Promote ideas that earn it.** Put the cursor on a journal heading and press `SPC n x` to turn it into its own note in `permanent/`.
4. **Connect notes to a map.** In a note, press `SPC n p` to link it to a MOC, which is created if it doesn't exist yet.
5. **Find things.** `SPC n f` finds a note by title, `SPC /` searches the text of all notes, and `SPC n l` shows what links to the current note.
6. **Back up.** Each save is already committed, so press `SPC g P` to push when you want a copy on the remote.

## Commands

### Notes (`SPC n`)

| Keys | What it does |
|------|--------------|
| `SPC n f` | Find a note by title. Typing a new title creates it. |
| `SPC n c` | Add a new entry to a note, creating the note if needed |
| `SPC n i` | Insert a link to a note, then return to typing |
| `SPC n l` or `SPC n b` | Show or hide the panel of notes that link here |
| `SPC n x` | Turn the heading under the cursor into its own note in `permanent/` |
| `SPC n p` | Go to this note's parent MOC, or link it to one if it has none ([details](#maps-of-content)) |
| `SPC u SPC n p` | Choose a different parent MOC for this note |
| `SPC n m` | Move this file to another folder and commit the move |
| `SPC n h` | Open your home page, `root.org` |

Doom's own org-roam commands are still available under `SPC n r`, including the note graph (`SPC n r g`) and a database rebuild (`SPC n r s`).

### Journal (`SPC j`)

| Keys | What it does |
|------|--------------|
| `SPC j j` or `SPC j t` | Open today's journal note |
| `SPC j y` | Open yesterday's note |
| `SPC j d` | Pick a date from a calendar |
| `SPC j p` / `SPC j n` | Go to the previous / next existing note |
| `SPC j r` | Open a random journal note, handy for resurfacing old writing |

Journal notes always open at the top of the file.

### Search

| Keys | What it does |
|------|--------------|
| `SPC /` | Search the text of all notes, wherever you are |
| `SPC .` | Browse files, starting from the current folder. Selecting a file opens it, and selecting a folder opens it in `dired`, Emacs's file manager. |

### Git

| Keys | What it does |
|------|--------------|
| `SPC g P` | Push the current repository to its upstream |
| `SPC g p` | Pull the current repository from its upstream |

### Editing and windows

| Keys | Works in | What it does |
|------|----------|--------------|
| `C-c i` | Org files, normal or insert mode | Insert a link to a note, then keep typing |
| `C-M-i` | Org files | Complete at the cursor, including note titles |
| `C-x C-s` | Any mode | Save |
| `C-x k` | Any mode | Close the current buffer without asking which one |
| `C-x K` | Any mode | Open the buffer list (`ibuffer`) to close several at once |
| `SPC t t` | Normal mode | Show or hide the file tree |

**Coming from Doom?** These bindings replace Doom's defaults: `SPC /` searches notes rather than the current project, and `SPC n f`, `SPC n c`, `SPC n l` and `SPC n m` now run the commands above rather than find-in-notes, clock toggle, store-link and tag view.

## Note types

When you create a note with `SPC n f`, `SPC n c`, `SPC n i` or `C-c i`, Emacs asks which type you want:

| Key | Type | Saved in | Adds to the note |
|-----|------|----------|------------------|
| `n` | Note | `permanent/` | Title and creation time |
| `l` | Literature | `literature/` | Those, a `:literature:` tag and a `#+source:` line for the reference |
| `m` | MOC | `maps/` | Those, a `(MOC)` title suffix, a `:moc:` tag and a `* Notes` heading |
| `p` | Person | `people/` | Those and a `:person:` tag |

Files are named after the title, so "My Idea" becomes `my_idea.org`.

## How your notes are organized

```
~/notes/
├── root.org      Home page, linking to your top-level MOCs
├── journal/      Daily notes, named YYYY-MM-DD.org
├── permanent/    Evergreen notes
├── literature/   Notes on sources
├── maps/         Maps of Content
├── people/       Notes on people
└── support/      The search database (created automatically)
```

Files never move on their own. Use `SPC n m` when you want to move one.

## Maps of Content

A MOC is a note that lists related notes. `SPC n p` connects a note to one from both sides in a single step:

- The note gets a `#+parent:` line linking up to the MOC.
- The MOC gets a link back to the note under its `* Notes` heading, unless it's already listed.
- Both files are saved and committed.

If the note already has a parent, `SPC n p` takes you there instead, so pressing it repeatedly walks up your map. Use `SPC u SPC n p` to choose a different parent. This adds the note to the new MOC but doesn't remove it from the old one, so delete that link by hand.

**Linking to Root.** Root also appears in the `SPC n p` list, which is how a note reaches your home page. MOCs are listed under `* Maps of Content` and other notes under `* Other Higher-Order Notes`.

**Automatic tags.** A MOC linked to Root is tagged `:top:`, and a MOC linked to another MOC is tagged `:nest:`. Other notes' tags aren't changed.

## Automatic git commits

Everything in `~/notes` is versioned without you doing anything:

| When you... | Commit message |
|-------------|----------------|
| Save a file or finish a capture | `#desktop: UPDATE my_idea.org - 2026-10-30 09:15 AM` |
| Move a file with `SPC n m` | `#desktop: MOVE permanent/a.org → maps/a.org` |
| Delete a `.org` file from within Emacs | `#desktop: DELETE permanent/a.org` |

- Commits run in the background, so saving never makes you wait.
- Only the file in question is committed. Anything else you have in progress is left alone.
- **Nothing is pushed automatically.** Use `SPC g P` when you want to push.
- If a commit fails, a message appears in the echo area and the details are in the ` *notes-git*` buffer. To open it, press `SPC b B` and type the name, including the leading space.

## Making it your own

Everything below is in `config.el`. After editing it, run `M-x doom/reload` (`SPC h r r`). After editing `init.el` or `packages.el`, run `doom sync` in a terminal and restart Emacs.

| To change | Edit |
|-----------|------|
| Your name and email | `user-full-name` and `user-mail-address`, at the top. **Set these first**, since they're the author's. |
| The `#desktop:` commit prefix | The `format` strings in the git functions. It labels which machine made a commit. |
| The notes location | `org-directory`, `org-roam-directory` and `mason/notes-root-file` |
| Font and size | `doom-font` and related settings. Run `M-x doom/reload-font` afterwards. |
| Theme | `doom-theme` (currently Gruvbox) |
| Note types | `org-roam-capture-templates` |
| The dashboard menu | `+dashboard-menu-sections` |
| The window title bar | The `undecorated` line at the bottom of the file, which hides it |

## What else is included

The Doom modules enabled in `init.el` also provide:

- **Editing:** Vim keys everywhere (`evil`), code folding, snippets, and automatic whitespace cleanup
- **Completion:** `vertico` for menus and `corfu` for in-buffer completion
- **Interface:** Doom dashboard with shortcuts to your notes, modeline, file tree (`neotree`), workspaces, and git changes in the margin
- **Tools:** `magit` for git, Docker, remote file editing (`tramp`), persistent undo, syntax, spelling and grammar checking
- **Languages:** Org, Markdown, Emacs Lisp, JavaScript, JSON, HTML/CSS, YAML, and shell

See [Doom's documentation](https://github.com/doomemacs/doomemacs) for the features and keybindings that come with these modules.
