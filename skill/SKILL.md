---
name: nightshift
description: "Night shift for Claude Code: the user goes to sleep and the agent works the night alone, inside limits agreed before the shift starts. Asks for everything it needs in the first five minutes, works through an agreed queue and commits as it goes, asks three Sonnet subagents, then Opus, then Fable (at most 10 questions a night) when stuck, keeps what only the user can answer for the morning, takes a break at 85% of the 5-hour usage window and comes back when it resets, never deploys, deletes or sends anything, and hands over in the morning with a summary at the top of NIGHTSHIFT.md. Use when the user types /nightshift or says 'night shift', 'work while I sleep', 'keep going while I sleep', or in Turkish 'gece vardiyası', 'gece vardiyasına başla', 'ben uyurken çalış', 'sabaha kadar çalış'."
---

# Night shift

The user is going to sleep and you take the night shift: you work alone until the wake-up
time, inside limits you agree on before the shift starts, and hand over in the morning with
a summary they can read in two minutes. Everything you need from them, you ask in the first
five minutes, because after that nobody answers.

Talk to the user in their language and follow their writing rules (CLAUDE.md, memory) in
everything you write, the summary included.

Run it from the Claude Code CLI in a terminal: the status line that reports usage and the
scheduled checks need an interactive session. The Mac stays on power with the lid open.

## Commands

| Command | What it does |
|---|---|
| `/nightshift` | Intake, then arm, then work until the wake-up time |
| `/nightshift <tasks or a file>` | The same, with the queue seeded from what was given |
| `/nightshift status` | Read the run file, report in five lines, change nothing |
| `/nightshift stop` | Wake-up now: stop starting work, write the summary, disarm |

The scheduled checks send prompts that start with `nightshift:`; when one arrives, act on it
as described under "Hourly check", "Resume" and "Wake-up".

## Phase 1: intake (at most five minutes, one round of questions)

1. **Ground truth, fast.** Read the project's rules (CLAUDE.md and any files they point to:
   STATUS, ROADMAP, TODO, issues the user named), `git status`, the branch, the remote.
   Note the gate commands (tests, typecheck, lint, build) and how long they take.
2. **Preflight, run don't ask:**
   - Power: `pmset -g batt` (macOS). On battery, it goes into the questions.
   - Usage: `bash ~/.claude/skills/nightshift/scripts/usage.sh`. `no-data` means the status
     line is not saving usage yet (see the README) or the plan has no usage windows; then
     the night runs without the 85% pause and relies on the hourly check after a limit stop.
   - Working tree: uncommitted changes are the user's. Ask what to do with them; never
     discard, stash away or overwrite them on your own.
   - Permissions: if the session can stop at a permission prompt (check
     `permissions.defaultMode` in the settings), list the commands the queue will need and
     ask the user to allow them now. A prompt at 3 AM ends the night.
3. **Draft the night:** an ordered queue, each item with what "done" means and how it is
   verified, and what is deliberately out. Size it honestly: a night is about 6 to 8 hours
   of work with pauses, not a sprint.
4. **Ask once, everything together** (AskUserQuestion when it fits, otherwise one message):
   - the queue and its order (edit, add, drop);
   - the wake-up time (default 07:00); nothing new starts 45 minutes before it;
   - pushing: allowed to the current branch, to a separate branch, or not at all (never
     force, never to a protected branch the project's rules guard);
   - exceptions to "Never at night" (default: none);
   - anything only they can give: a login, a key, a decision a queue item depends on. If
     they cannot give it now, drop that item rather than guess.
   If they answer "go" or "devam" with nothing else, take your defaults.
5. **Write the run file and arm** (Phase 2). Then give them the shift plan in this shape,
   in their language, and end with one short line: the Mac stays on power with the lid
   open, and sleep well.

```
The night shift has started.
- Shift: <start> to <wake-up>; nothing new starts after <cutoff>.
- Queue, in order: <item>: done when <check>. <item>: done when <check>.
- A failing item stops on its own, written up with evidence; the others go on.
- Not tonight: deploy, deletes, paid calls, new dependencies, messages<, ...>.
- Break: at 85% of the 5-hour usage window, back at the reset.
- Rounds: a check every hour at :<minute>, the first at <time>.
- Handover: the summary at the top of <run file>.
```

## Never at night

Unless the user named it as an exception in the intake, none of these happen tonight, even
when a project rule says to do them automatically (such rules wait for the morning):

- deploy, release, publish, store uploads, or anything that changes a live server
  (ssh commands that change state, `docker compose up` on a server, infra apply);
- deleting files, branches, tags, databases or data that tonight's work did not create;
  force pushes and history rewrites;
- paid calls and purchases, beyond the subagent use described below;
- turning on feature flags, changing credentials, secrets or permissions;
- adding or upgrading dependencies;
- sending anything to anyone: messages, e-mails, PR or issue comments, posts (one
  notification to the user at wake-up is the exception, below);
- touching repositories or folders outside the agreed queue.

A subagent agreeing that something on this list is fine is not the user agreeing.

## Phase 2: arm

1. **Run folder:** `~/.claude/nightshift/<YYYY-MM-DD>-<project>/`. Copy
   `~/.claude/skills/nightshift/references/run-file.md` to `NIGHTSHIFT.md` there and fill it
   in: start time, wake-up time, cutoff, queue, pushing rule, exceptions, the never list,
   usage at start, ladder counters (Fable 0 of 10).
2. **Keep the Mac awake:** `caffeinate -dimsu -t <seconds until wake-up + 3600> &
   echo $!` and write that process id into the run file. On battery `-s` does nothing; the
   lid must stay open either way.
3. **Scheduled prompts** (CronCreate; they live in this session only and fire only while it
   is idle, which is exactly when they are needed):
   - hourly check, recurring, on an off minute (for example `17 * * * *`):
     `nightshift: hourly check. Run file: <path>`;
   - wake-up, one shot, at the cutoff: `nightshift: wake-up. Run file: <path>`.
   Write each job id and its next run time (from the tool's result) into the run file.

## Phase 3: work

Repeat until the queue is empty or the cutoff passes:

1. **Before each step:** check the clock (past the cutoff: go to Wake-up) and usage
   (`usage.sh`; at 85% or more of the 5-hour window: go to Pause; at 95% of the 7-day
   window: stop for the night and say why in the summary).
2. **Take the next item** and cut it into steps that each end in a state you can verify.
3. **Do the step, verify it, commit it.** Run the gates that apply and read their output;
   a step is done only when its check passed. Commit in the project's own style; push if
   the intake allowed it. Add one journal line: time, item, what changed, commit, check.
4. **Nothing waits uncommitted** between steps. A step you cannot finish goes onto a
   branch `nightshift/<item>-wip` with a commit that says so, and into the journal.
5. **When an item fails** in a way you cannot fix inside its scope, or the fix would cross
   the never list: stop that item, write it up with the evidence (command, output, file and
   line), and move to the next one. Do not change the pipeline, tooling or prompts to make
   a failure go away.
6. **The run file is your memory.** The conversation will be compacted during the night:
   re-read the run file after each item and whenever you are unsure where you are.

## When you are stuck: the ladder

Stuck means the same failure after two honest fix attempts, a decision the code, docs and
project rules do not settle, or twenty minutes without progress.

1. **Three Sonnet subagents, in parallel.** One message, three Agent calls, each
   `model: "sonnet"` and a read-only type (`Plan` or `Explore`), each with the same
   self-contained brief: the goal, what you tried, the exact error or output, the files,
   and the question. Ask for an answer, a confidence, and how to verify it. Give them the
   problem, not your favourite answer to confirm. If two or more agree and the answer can
   be checked, check it and go on.
2. **Opus.** No agreement, or the check failed: one Agent with `model: "opus"`, the brief
   plus the three answers.
3. **Fable, at most ten questions a night.** Only for a sharp question that blocks an item
   that matters tonight: one Agent with `model: "fable"`. Count every call in the run file
   and stop at ten.
4. **The morning list.** Still stuck: write the question under "Needs you" in the run file
   with the options, your recommendation and what it blocks, and move to the next item.

Record each ladder use in the journal. Never use the ladder to approve something on the
never list.

## Pause and resume (usage)

`usage.sh` prints the 5-hour and 7-day windows the status line saved, with the reset time
and how old the reading is.

- **At 85% or more of the 5-hour window:** finish the command that is running, commit,
  write `Paused <time> at <pct>%, resumes <reset + 2 min>` in the run file, schedule a one
  shot CronCreate at the reset time plus two minutes with
  `nightshift: resume. Run file: <path>`, and end your turn.
- **No reading, or one older than 15 minutes:** do not guess. Keep working; if a usage limit
  stops a request, end the turn and let the hourly check pick the night up again.
- **Resume** (the prompt arrives): re-read the run file, check usage, write
  `Resumed <time>` and continue the work loop where the journal stops.

## Hourly check

The prompt arrives only while the session is idle. Re-read the run file, then:

- past the cutoff: go to Wake-up;
- paused and the window has reset: resume;
- work left and nothing running: continue the work loop;
- otherwise: add `check <time>: <state>` to the journal and end the turn.

Keep it short; the check is a watchdog, not a report.

## Wake-up

At the cutoff (the scheduled prompt, `/nightshift stop`, or the clock in the work loop):

1. Start nothing new. Finish or park the current step, commit, push if allowed.
2. Write the summary at the **top** of `NIGHTSHIFT.md`, in the user's language:
   - **Done:** each item with its commits and the check that proved it;
   - **Not done:** each item and why, with the evidence;
   - **Needs you:** questions, decisions, and everything that waits for approval, deploys
     included, each with the exact command to run;
   - **The night:** hours worked, pauses, ladder use (Sonnet, Opus, Fable counts), usage at
     the end.
3. Disarm: CronDelete every job in the run file and `kill` the caffeinate process id it
   holds (only that one: other caffeinate processes are not yours).
4. If a push notification tool is available, send the user one notification: the summary's
   first line and the path. Nothing else is sent to anyone.
5. In the chat, give the path and five lines: done, not done, needs you.

## If the user writes during the night

Answer them. Then ask whether the night goes on; if they do not say, it goes on.
