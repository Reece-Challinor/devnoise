# Master Final Merge Plan (All Worktrees -> One Main Repo)

Date: 2026-03-01
Primary repo: `/Users/reecechallinor/Development/Projects/devnoise`

This document gives you:
- A production-safe merge script to consolidate all thread branches/worktrees.
- A comprehensive `@AI AGENT` prompt for end-to-end conflict resolution and final validation.

## Objective
Merge every thread branch and change (including dirty worktree edits) back into `main`, resolve conflicts, validate the app, and remove extra worktree directories so only the primary repository remains active.

## Important Notes
- This workflow merges via Git history, not by copying files between directories.
- It is designed for your current branch/worktree layout (`codex/t01...t10` plus local variants).
- It commits dirty changes in each worktree branch before merge.
- It enables `rerere` so repeated conflict resolutions are remembered.

## Master Consolidation Script
Save as `scripts/merge_all_threads_to_main.sh` and run from the primary repo.

```bash
#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="${1:-/Users/reecechallinor/Development/Projects/devnoise}"
REMOTE="${REMOTE:-origin}"
AUTO_COMMIT_DIRTY="${AUTO_COMMIT_DIRTY:-1}"        # 1 = commit dirty worktrees automatically
AUTO_COMMIT_CURRENT="${AUTO_COMMIT_CURRENT:-1}"    # 1 = commit dirty current repo before switching to main
RUN_BUILD_CHECK="${RUN_BUILD_CHECK:-1}"            # 1 = run xcodebuild validation after merges
CLEANUP_WORKTREES="${CLEANUP_WORKTREES:-1}"        # 1 = remove codex worktree directories after merge
DELETE_MERGED_BRANCHES="${DELETE_MERGED_BRANCHES:-0}" # 1 = delete merged local codex branches
PUSH_MAIN="${PUSH_MAIN:-0}"                        # 1 = push main to remote at end

KNOWN_ORDER=(
  "codex/t01-state-migration"
  "codex/t02-audio-dsp"
  "codex/t03-audio-engine"
  "codex/t04-global-hotkeys"
  "codex/t05-remap-capture-core"
  "codex/t06-remap-menu-integration"
  "codex/t07-route-sleep-wake"
  "codex/t08-release-scripts"
  "codex/t09-release-workflow"
  "codex/t10-site-docs-qa"
)

log() { printf "\n[%s] %s\n" "$(date +"%H:%M:%S")" "$*"; }
fail() { printf "\nERROR: %s\n" "$*" >&2; exit 1; }

branch_exists() {
  git show-ref --verify --quiet "refs/heads/$1"
}

contains() {
  local needle="$1"; shift
  local item
  for item in "$@"; do
    [[ "$item" == "$needle" ]] && return 0
  done
  return 1
}

worktree_for_branch() {
  local target="$1"
  local wt=""
  local br=""
  while IFS= read -r line; do
    case "$line" in
      worktree\ *) wt="${line#worktree }" ;;
      branch\ refs/heads/*)
        br="${line#branch refs/heads/}"
        if [[ "$br" == "$target" ]]; then
          printf "%s\n" "$wt"
          return 0
        fi
        ;;
    esac
  done < <(git worktree list --porcelain)
  return 1
}

commit_if_dirty() {
  local wt="$1"
  local branch="$2"

  [[ -d "$wt" ]] || { log "Skipping missing worktree path: $wt"; return 0; }

  if [[ -n "$(git -C "$wt" status --porcelain)" ]]; then
    if [[ "$AUTO_COMMIT_DIRTY" != "1" ]]; then
      fail "Dirty worktree detected at $wt ($branch). Set AUTO_COMMIT_DIRTY=1 or commit manually."
    fi

    log "Auto-committing dirty changes in $wt ($branch)"
    git -C "$wt" add -A

    if git -C "$wt" diff --cached --quiet; then
      log "No staged diff found after add in $wt"
      return 0
    fi

    git -C "$wt" commit -m "chore(${branch##*/}): finalize thread worktree changes"
  else
    log "Clean worktree: $wt ($branch)"
  fi
}

ensure_clean_or_commit_current_repo() {
  local current_branch
  current_branch="$(git branch --show-current)"

  if [[ -n "$(git status --porcelain)" ]]; then
    if [[ "$AUTO_COMMIT_CURRENT" != "1" ]]; then
      fail "Current repo has uncommitted changes on $current_branch. Set AUTO_COMMIT_CURRENT=1 or commit manually."
    fi
    log "Auto-committing current repo dirty changes on $current_branch"
    git add -A
    if ! git diff --cached --quiet; then
      git commit -m "chore(${current_branch##*/}): finalize local working changes before consolidation"
    fi
  fi
}

merge_branch_into_main() {
  local branch="$1"

  branch_exists "$branch" || { log "Skipping missing branch: $branch"; return 0; }

  local main_only="0"
  local branch_only="0"
  read -r main_only branch_only < <(git rev-list --left-right --count "main...$branch")

  if [[ "$branch_only" == "0" ]]; then
    log "Skipping already-merged/no-unique-commit branch: $branch"
    return 0
  fi

  log "Merging $branch into main"
  if ! git merge --no-ff "$branch" -m "merge(${branch##*/}): integrate thread changes"; then
    local conflicts
    conflicts="$(git diff --name-only --diff-filter=U || true)"
    printf "%s\n" "$conflicts" > .merge-conflicts.txt

    printf "\nMerge conflict while merging %s\n" "$branch" >&2
    printf "Conflicted files saved to .merge-conflicts.txt\n" >&2
    printf "Resolve conflicts, then run:\n" >&2
    printf "  git add <resolved-files>\n" >&2
    printf "  git commit\n" >&2
    printf "  ./scripts/merge_all_threads_to_main.sh %q\n" "$ROOT_DIR" >&2
    exit 2
  fi
}

cleanup_codex_worktrees() {
  [[ "$CLEANUP_WORKTREES" == "1" ]] || return 0

  log "Cleaning up codex worktrees"

  local wt=""
  local br=""
  while IFS= read -r line; do
    case "$line" in
      worktree\ *) wt="${line#worktree }" ;;
      branch\ refs/heads/*)
        br="${line#branch refs/heads/}"
        if [[ "$wt" != "$ROOT_DIR" && "$br" == codex/* ]]; then
          log "Removing worktree $wt ($br)"
          git worktree remove "$wt" --force || true
        fi
        ;;
    esac
  done < <(git worktree list --porcelain)

  git worktree prune
}

delete_local_codex_branches() {
  [[ "$DELETE_MERGED_BRANCHES" == "1" ]] || return 0

  log "Deleting merged local codex branches"
  local b
  while IFS= read -r b; do
    [[ "$b" == "main" ]] && continue
    [[ "$b" == "" ]] && continue
    git branch -d "$b" || true
  done < <(git for-each-ref --format='%(refname:short)' refs/heads/codex)
}

build_validation() {
  [[ "$RUN_BUILD_CHECK" == "1" ]] || return 0

  log "Running build validation"
  xcodebuild -project DevNoise.xcodeproj -scheme DevNoise -configuration Debug -destination 'platform=macOS' build
}

main() {
  [[ -d "$ROOT_DIR/.git" ]] || fail "Invalid git repo root: $ROOT_DIR"
  cd "$ROOT_DIR"

  log "Repository: $ROOT_DIR"
  git config rerere.enabled true
  git fetch "$REMOTE" --prune || true

  ensure_clean_or_commit_current_repo

  # Construct merge order: known ordered branches + any extra local codex/* branches not listed.
  local merge_order=()
  local known
  for known in "${KNOWN_ORDER[@]}"; do
    branch_exists "$known" && merge_order+=("$known")
  done

  local discovered
  while IFS= read -r discovered; do
    contains "$discovered" "${merge_order[@]}" || merge_order+=("$discovered")
  done < <(git for-each-ref --format='%(refname:short)' refs/heads/codex)

  # Auto-commit dirty changes in branch worktrees before switching to main.
  local b wt
  for b in "${merge_order[@]}"; do
    wt=""
    if wt="$(worktree_for_branch "$b")"; then
      commit_if_dirty "$wt" "$b"
    else
      log "No active worktree found for $b (branch-only merge)"
    fi
  done

  # Ensure main is checked out and current.
  local current_branch
  current_branch="$(git branch --show-current)"
  if [[ "$current_branch" != "main" ]]; then
    log "Switching from $current_branch to main"
    git checkout main
  fi

  # Keep local main current if remote exists.
  git pull --ff-only "$REMOTE" main || true

  # Backup tag before consolidation.
  local backup_tag="pre-consolidation-$(date +%Y%m%d-%H%M%S)"
  git tag "$backup_tag"
  log "Created safety tag: $backup_tag"

  for b in "${merge_order[@]}"; do
    merge_branch_into_main "$b"
  done

  build_validation
  cleanup_codex_worktrees
  delete_local_codex_branches

  if [[ "$PUSH_MAIN" == "1" ]]; then
    log "Pushing main to $REMOTE"
    git push "$REMOTE" main
  fi

  log "Consolidation complete."
  log "Final branch: $(git branch --show-current)"
  log "Final status:\n$(git status --short || true)"
}

main "$@"
```

## How To Run
From `/Users/reecechallinor/Development/Projects/devnoise`:

```bash
chmod +x scripts/merge_all_threads_to_main.sh
./scripts/merge_all_threads_to_main.sh
```

Optional flags (environment variables):

```bash
AUTO_COMMIT_DIRTY=1 AUTO_COMMIT_CURRENT=1 RUN_BUILD_CHECK=1 CLEANUP_WORKTREES=1 DELETE_MERGED_BRANCHES=0 PUSH_MAIN=0 ./scripts/merge_all_threads_to_main.sh
```

## @AI AGENT Prompt (Comprehensive End-to-End)
Use this prompt if you want an agent to run and supervise the entire merge, including conflict resolution.

```text
You are the Merge Coordinator AI for DevNoise.

Goal:
Consolidate all thread worktrees/branches into main in the primary repository at:
/Users/reecechallinor/Development/Projects/devnoise

Current situation:
- Multiple local worktree directories exist (devnoise-t01 ... devnoise-t10).
- Local thread branches are codex/t01...t10 (and possibly additional codex/* variants).
- Some worktrees may contain uncommitted changes.

Non-negotiables:
- Preserve all valid thread work; do not drop changes silently.
- Resolve conflicts by combining behavior, not by blindly choosing ours/theirs.
- Respect docs/prd.md and docs/tech.prd.md constraints.
- Keep app menu-bar-only, no windows, no in-app networking/telemetry/microphone.
- Never persist playback state; keep persistence whitelist rules.

Execution steps:
1) Preflight
- Verify repo clean or commit dirty state in each worktree branch.
- Enable rerere.
- Confirm branch list and worktree list.

2) Consolidation
- Switch to main and fast-forward pull if possible.
- Merge thread branches in deterministic order:
  codex/t01-state-migration
  codex/t02-audio-dsp
  codex/t03-audio-engine
  codex/t04-global-hotkeys
  codex/t05-remap-capture-core
  codex/t06-remap-menu-integration
  codex/t07-route-sleep-wake
  codex/t08-release-scripts
  codex/t09-release-workflow
  codex/t10-site-docs-qa
  then any extra codex/* branches not in list.

3) Conflict resolution policy
- For Swift files: preserve logic from both branches unless contradictory.
- For model/reducer conflicts: maintain deterministic state flow and side-effect boundaries.
- For xcodeproj conflicts: ensure all added source files remain in PBX project and build phases.
- For docs conflicts: keep stricter privacy/security language.
- After each conflict resolution: stage files and continue merge.

4) Verification gates after all merges
- Build command:
  xcodebuild -project DevNoise.xcodeproj -scheme DevNoise -configuration Debug -destination 'platform=macOS' build
- Check no unresolved conflicts:
  git diff --name-only --diff-filter=U
- Check repository status and branch:
  git status --short
  git branch --show-current
- Confirm key file presence:
  DevNoise/
  docs/
  scripts/
  .github/workflows/

5) Cleanup
- Remove extra codex worktrees so primary repo is the single active directory.
- Optionally delete merged local codex branches.
- Keep a safety tag before cleanup.

6) Final report
Provide:
- Merged branch list
- Conflict files and how each was resolved
- Build result
- Remaining TODOs (if any)
- Final git status and current branch

Important:
- Do not use destructive reset commands.
- Do not discard uncommitted changes without first committing them to the corresponding thread branch.
```

## Recommended After Consolidation
1. Run the app once from Xcode and verify menu-bar-only behavior.
2. Update `CHANGELOG.md` with consolidated Phase 1 progress summary.
3. Push `main` and create a checkpoint tag.

