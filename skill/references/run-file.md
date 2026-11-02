# Night shift: <project>, <date>

<!-- The handover goes here: Done, Review first, Not done, Needs you, Waiting for approval, The night. -->

## Plan

- Started: <time>
- Wake-up: <time> (epoch <seconds>); nothing new starts after <cutoff>
- Base: <branch> at <commit>
- Night branch: nightshift/<date> (pushed: <yes | no>)
- Exceptions to "Never at night": <none>
- Usage at start: 5h <pct>%, 7d <pct>% (the weekly guard counts from this)

### Queue

| # | Task | Done when | Risk | Box ends | Commits | Undo |
|---|---|---|---|---|---|---|
| 1 | <task> | <check> | <green / yellow / red> | <time> | <first>..<last> | `git revert --no-edit <first>^..<last>` |

### Out tonight

- <what was left out on purpose>

## Armed

- Run file: <path>
- caffeinate pid: <pid>
- Rounds: job <id>, next <time>
- Handover: job <id> at <time>
- Break: <job id and time, while on a break>

## Council

- Rounds of three: 0
- Opus: 0
- Fable: 0 of 6

## Needs you

<questions and decisions for the morning: options, recommendation, what it blocks>

## Journal

<!-- one line per step: time, task, risk, what changed, commit, check; breaks, rounds and councils too -->
