# Loadout repository instructions

## Start here

- Read `PROJECT.md` for product scope and architecture.
- Read `STYLE_GUIDE.md` and the relevant data or feature documentation before
  changing user-facing behavior.
- Read `docs/RESTAURANT_WORKFLOW_RESEARCH.md` before changing a restaurant's
  menu data, configuration model, or ordering flow.
- Preserve existing uncommitted work. Use a separate worktree when another session
  is editing this repository.

## Project management

- Follow the shared workflow in `~/.codex/AGENTS.md`.
- Track this repository in `Dayo Product OS` with `Project = Loadout`.
- The GitHub Project is the sole active backlog. Repository planning and curation
  documents provide specifications and evidence, not a second task queue.
- This repository has a GitHub remote. Codex normally owns the branch, focused
  verification, commit, and pull request for implementation work.

## Engineering workflow

- Keep changes within the goals and non-goals in `PROJECT.md`.
- Prefer the repository's scripts and documented commands. Run focused checks first,
  then the appropriate build or full verification before calling work complete.
- Review the final diff and report what was tested, what was not tested, and any
  remaining device-only verification.
