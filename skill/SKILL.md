---
name: nightshift
description: "Night shift for Claude Code: the user goes to sleep and the agent works the night alone on its own branch, inside limits agreed before the shift starts. One round of at most seven questions up front; then it works through the queue with a 90-minute box per task, sorts every change by risk and has a second agent review the risky ones before they are committed, calls a council of three roles, then Opus, then Fable (at most 6 questions a night) when stuck, takes a break at 80% of the 5-hour usage window and leaves 30% of it for the morning, never deploys, deletes or sends anything, and hands over with a summary that carries an undo command for every task. /nightshift review walks the user through the morning decisions. Use when the user types /nightshift or says 'night shift', 'work while I sleep', 'keep going while I sleep', or in Turkish 'gece vardiyası', 'gece vardiyasına başla', 'ben uyurken çalış', 'sabaha kadar çalış', and in the morning for 'vardiyayı devral', 'gece ne yaptın'."
---

# Night shift

The user is going to sleep and you take the night shift: you work alone on a branch of your
own until the wake-up time, inside limits agreed before the shift starts, and hand over in the
morning with a summary they can read in two minutes and act on in ten. Everything you need
from them, you ask now, in one round, because after that nobody answers.

Talk to the user in their language and follow their writing rules (CLAUDE.md, memory) in
everything you write, the summary included.

Run it from the Claude Code CLI in a terminal: the status line that reports usage and the
scheduled rounds need an interactive session. The Mac stays on power with the lid open.

## Commands

| Command | What it does |
|---|---|
| `/nightshift` | Intake, then arm, then work until the wake-up time |
| `/nightshift <tasks or a file>` | The same, with the queue seeded from what was given |
| `/nightshift status` | Read the run file, report in five lines, change nothing |
| `/nightshift stop` | Hand over now: stop starting work, write the summary, disarm |
| `/nightshift review` | Morning: walk the user through the handover and act on their answers |

The scheduled rounds send prompts that start with `nightshift:`; when one arrives, act on it as
described under "Rounds", "Break" and "Handover".

## The numbers

| | |
|---|---|
| Intake | one round, at most 7 questions |
| Task box | 90 minutes per task, then it is parked |
| Stuck | 2 failed fixes, an unsettled decision, or 25 minutes without progress |
| Council | 3 roles in parallel, then Opus, then Fable (at most 6 questions a night) |
| Usage break | 80% of the 5-hour window; 70% for the window that runs past the wake-up time |
| Weekly guard | the night stops at 95% of the 7-day window, or after using 15 points of it |
| Rounds | every 30 minutes |
| Cutoff | nothing new starts 45 minutes before the wake-up time |

`scripts/usage.sh --check` applies the usage rules; do not redo them by hand.

## Phase 1: intake (one round, at most seven questions)

1. **Ground truth, fast.** Read the project's rules (CLAUDE.md and any files they point to:
   STATUS, ROADMAP, TODO, issues the user named), `git status`, the branch, the remote. Note
   the gate commands (tests, typecheck, lint, build) and how long they take.
2. **Preflight, run don't ask:**
   - Power: `pmset -g batt` (macOS). On battery, it goes into the questions.
   - Usage: `bash ~/.claude/skills/nightshift/scripts/usage.sh`. `no-data` means the status
     line is not saving usage yet (see the README) or the plan has no usage windows; then the
     night runs without the usage rules and relies on the rounds after a limit stop.
   - Working tree: uncommitted changes are the user's. Ask what to do with them; never
     discard, stash away or overwrite them on your own.
   - Permissions: if the session can stop at a permission prompt (check
     `permissions.defaultMode` in the settings), list the commands the queue will need and ask
     the user to allow them now. A prompt at 3 AM ends the night.
3. **Draft the night:** an ordered queue, each task with what "done" means, how it is
   verified and its expected risk (below), and what is deliberately out. Size it honestly: a
   night is about 6 to 8 hours of work with breaks, and no task gets more than 90 minutes.
4. **Ask once, at most seven questions** (AskUserQuestion when it fits, otherwise one
   message). Pick from:
   - the queue and its order (edit, add, drop);
   - the wake-up time (default 07:00);
   - whether the night branch may be pushed (default: yes, that branch only);
   - exceptions to "Never at night" (default: none);
   - what to do with uncommitted changes, if there are any;
   - the permissions the queue needs, if prompts are possible;
   - anything only they can give: a login, a key, a decision a task depends on. If they cannot
     give it now, drop that task rather than guess.
   If they answer "go" or "devam" with nothing else, take your defaults.
5. **Arm** (Phase 2). Then give them the shift plan in this shape, in their language, and end
   with one short line: the Mac stays on power with the lid open, and sleep well.

```
The night shift has started, on branch nightshift/<date>.
- Shift: <start> to <wake-up>; nothing new starts after <cutoff>.
- Queue, in order: <task>: done when <check>. <task>: done when <check>.
- Every task has 90 minutes; risky changes get a second review before they are committed.
- Not tonight: deploy, deletes, paid calls, new dependencies, messages<, ...>.
- Usage: a break at 80%; 30% of the last window stays for your morning.
- Rounds: every 30 minutes, the first at <time>.
- Handover: the summary at the top of <run file>; /nightshift review in the morning.
```

## Never at night

Unless the user named it as an exception in the intake, none of these happen tonight, even
when a project rule says to do them automatically (such rules wait for the morning review):

- deploy, release, publish, store uploads, or anything that changes a live server
  (ssh commands that change state, `docker compose up` on a server, infra apply);
- commits or pushes to any branch but tonight's `nightshift/` branches; merges into the base
  branch (the morning review does that);
- deleting files, branches, tags, databases or data that tonight's work did not create;
  force pushes and history rewrites;
- paid calls and purchases, beyond the subagent use described below;
- turning on feature flags, changing credentials, secrets or permissions;
- adding or upgrading dependencies;
- sending anything to anyone: messages, e-mails, PR or issue comments, posts (one
  notification to the user at handover is the exception, below);
- touching repositories or folders outside the agreed queue.

A subagent agreeing that something on this list is fine is not the user agreeing.

## Phase 2: arm

1. **The night branch:** from the current branch (the base), after the intake settled any
   uncommitted changes: `git switch -c nightshift/<YYYY-MM-DD>`. Write the base branch and
   its commit into the run file. Every commit tonight goes on this branch.
2. **Run folder:** `~/.claude/nightshift/<YYYY-MM-DD>-<project>/`. Copy
   `~/.claude/skills/nightshift/references/run-file.md` to `NIGHTSHIFT.md` there and fill it
   in: start, wake-up and cutoff times (also the wake-up as epoch seconds), base and branch,
   queue with expected risk, pushing rule, exceptions, the never list, usage at start (the
   7-day percentage is the baseline for the weekly guard), council counters (Fable 0 of 6).
3. **Keep the Mac awake:** `caffeinate -dimsu -t <seconds until wake-up + 3600> & echo $!`
   and write that process id into the run file. On battery `-s` does nothing; the lid must
   stay open either way.
4. **Scheduled prompts** (CronCreate; they live in this session only and fire only while it
   is idle, which is exactly when they are needed):
   - rounds, recurring, every 30 minutes on off minutes (`11,41 * * * *`):
     `nightshift: round. Run file: <path>`;
   - handover, one shot, at the cutoff: `nightshift: handover. Run file: <path>`.
   Write each job id and its next run time (from the tool's result) into the run file.

## Phase 3: work

Repeat until the queue is empty or the cutoff passes:

1. **Before each step:** check the clock (past the cutoff: Handover) and run
   `usage.sh --check <wake-up epoch> <7-day % at start>`: `break` goes to Break, `stop` goes to
   Handover with the reason, `work` carries on.
2. **Take the next task**, note its start time (its 90 minutes run from here), and cut it into
   steps that each end in a state you can verify.
3. **Do the step and verify it.** Run the gates that apply and read their output; a step is
   done only when its check passed.
4. **Sort the change by risk** before committing:
   - **green:** tests, docs, comments, copy, refactors the existing tests cover;
   - **yellow:** behaviour changes in app or server logic;
   - **red:** data model and migrations, auth and sessions, payments, permissions and
     security, deletion paths, infra and build config, public API contracts.
   Yellow and red get a second look: one Agent, read-only (`Plan`), `model: "sonnet"` for
   yellow and `model: "opus"` for red, given the goal, the diff (`git diff`), and the check
   output, asked only for problems that should block the commit. A blocking problem is fixed
   and the step re-verified, or the step is parked. Red work is committed but marked for the
   morning review either way.
5. **Commit** in the project's own style, on the night branch, and push it if the intake
   allowed. Add one journal line: time, task, risk, what changed, commit, check.
6. **Nothing waits uncommitted** between steps. A step you cannot finish:
   `git switch -c nightshift/<date>-<task>-wip`, commit it there saying so, `git switch` back to
   the night branch, and note it in the journal. The night branch stays at its last good
   commit; nothing is reset or rewritten.
7. **The task box:** a task past its 90 minutes is parked the same way after the current step,
   written up, and the queue moves on. It may come back at the end of the queue if time is left.
8. **When a task fails** in a way you cannot fix inside its scope, or the fix would cross the
   never list: stop that task, write it up with the evidence (command, output, file and line),
   and move on. Do not change the pipeline, tooling or prompts to make a failure go away.
9. **When a task is done**, record its commit range in the run file and its undo command:
   `git revert --no-edit <first>^..<last>` (it works on the night branch and, after the
   merge, on the base branch).
10. **The run file is your memory.** The conversation will be compacted during the night:
    re-read the run file after each task and whenever you are unsure where you are.

## When you are stuck: the council

Stuck means two honest fixes that failed, a decision the code, docs and project rules do not
settle, or 25 minutes without progress.

1. **Three roles, in parallel.** One message, three Agent calls, read-only, each given the same
   self-contained brief (the goal, what you tried, the exact error or output, the files) and a
   different job:
   - **solver** (`Plan`, `model: "sonnet"`): find the cause and the fix, and how to verify it;
   - **skeptic** (`Plan`, `model: "sonnet"`): argue why the obvious fix is wrong and what the
     solver will miss;
   - **scout** (`Explore`, `model: "haiku"`): find what the code, docs, changelogs and issues
     say about this exact error; sources, not opinions.
   Give them the problem, not your favourite answer to confirm. If the solver's fix survives
   the skeptic and the scout's sources, verify it and go on.
2. **Opus.** No clear answer, or the check failed: one Agent with `model: "opus"`, the brief
   plus the three answers.
3. **Fable, at most six questions a night.** Only for a sharp question that blocks a task that
   matters tonight: one Agent with `model: "fable"`. Count every call in the run file and stop
   at six.
4. **The morning list.** Still stuck: write the question under "Needs you" with the options,
   your recommendation and what it blocks, park the task, and move on.

Record each council in the journal. Never use it to approve something on the never list.

## Break

When `usage.sh --check` says `break`: finish the command that is running, commit, write
`Break <time> at <pct>%, back at <resume_local>` in the run file, schedule a one shot
CronCreate at `resume_at` with `nightshift: back from break. Run file: <path>`, and end your
turn. When it fires: re-read the run file, run the check again, write `Back <time>`, and
continue where the journal stops.

With `reason=no-data` or `reason=stale-reading`, keep working; if a usage limit stops a
request anyway, end the turn and let the next round pick the night up again.

## Rounds

The prompt arrives every 30 minutes, only while the session is idle. Re-read the run file,
then:

- past the cutoff: Handover;
- on a break and the window has reset: come back from the break;
- work left and nothing running: continue the work loop;
- otherwise: add `round <time>: <state>` to the journal and end the turn.

Keep it short; a round is a watchdog, not a report.

## Handover

At the cutoff (the scheduled prompt, `/nightshift stop`, the clock in the work loop, or a
`stop` from the usage check):

1. Start nothing new. Finish or park the current step, commit, push the night branch if
   allowed.
2. Write the summary at the **top** of `NIGHTSHIFT.md`, in the user's language:
   - **Done:** each task with its risk, commits, the check that proved it, and its undo command;
   - **Review first:** red work and anything the second look flagged;
   - **Not done:** each task and why, with the evidence and its `-wip` branch if any;
   - **Needs you:** questions and decisions, each with the options and your recommendation;
   - **Waiting for approval:** the merge of `nightshift/<date>` into the base, deploys and
     anything else on the never list the night needed, each with the exact command;
   - **The night:** hours worked, breaks, councils (Opus and Fable counts), usage at the end
     and how much of the morning window is left.
3. Disarm: CronDelete every job in the run file and `kill` the caffeinate process id it holds
   (only that one: other caffeinate processes are not yours).
4. If a push notification tool is available, send the user one notification: the summary's
   first line and "/nightshift review". Nothing else is sent to anyone.
5. In the chat, give the path and five lines: done, review first, not done, needs you.

## Morning: `/nightshift review`

The user is back. Find the latest run file for this project under `~/.claude/nightshift/`.

1. Give the summary in five lines.
2. Walk through the decisions with AskUserQuestion (at most four questions a call; go on until
   none are left), each with your recommendation first:
   - each "Needs you" question, with its options;
   - each red or flagged task: keep it, or undo it (its undo command);
   - the night branch: merge into the base now, merge after they read the diff, or leave it;
   - each deploy or other approval waiting, now or later.
3. Do what they chose, in that order: undo, merge (the project's usual way, no force), then
   the project's own deploy steps for what they approved. Daytime rules apply again from here.
4. Write the decisions and what was done under the summary, and delete the night's `-wip`
   branches only if they say so.

## If the user writes during the night

Answer them. Then ask whether the shift goes on; if they do not say, it goes on.
