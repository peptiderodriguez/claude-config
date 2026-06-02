Show current the lab cluster state — queue, partition availability, and what the operator's jobs are doing. Use as the canonical "what's running?" answer instead of running squeue inline ad-hoc.

TRIGGER when user asks: "how are the jobs?", "how are the pending jobs?", "what's running?", "cluster status", "is anything queued?", "is X still running?", "are my jobs done?", "anything in the queue?", "did Y finish?", "what does the cluster look like?", "is the cluster busy?", "what partitions are free?", "any GPUs available?", "show me squeue". Also trigger proactively when about to recommend a SLURM submission (so the user sees free partitions first).

SKIP when: not on the cluster (no `squeue` in PATH — fall through silently); the user just asked the same question in the previous turn; jobs were just submitted in this same turn (give them ≥30s before polling).

## Sequence

1. **Check we're on the cluster.** `command -v squeue` — if missing, say "not on a cluster host (no squeue in PATH)" and stop.

2. **Pull the user's jobs.** `squeue -u $USER --format='%.10i %.20j %.10P %.8T %.10M %.6D %R' --sort=+T,+i`. Show only if there are rows; otherwise say "no jobs queued or running."

3. **Pull partition availability** for `b_mann`-eligible partitions: `p.hpcl93`, `p.hpcl8`, `p.hpcl92`. Use `sinfo -p p.hpcl93,p.hpcl8,p.hpcl92 -h --format='%P %a %F %G'` (P=partition, a=avail, F=A/I/O/T node counts, G=GRES). Surface idle node counts per partition; flag GPU partitions specifically.

4. **One-line recommendation** if relevant: if the user is about to submit GPU work and `p.hpcl93` has 0 idle nodes, suggest queue + ETA or fallback to `p.hpcl8` (smaller GPUs). If asking about a specific job ID that's PENDING, show its `--start` estimate via `squeue -j <id> --start`.

5. **Tone — sober, matter-of-fact.** From the operator's CLAUDE.md guidance: don't catastrophize cluster ops. Lead with state, not narration. Bad: *"Let me check the cluster for you..."* — good: *"4 jobs running, 0 pending. p.hpcl93: 0/19 idle. p.hpcl8: 12/55 idle. First tile of job 42199 in 8s."*

## Output format

```
SQUEUE (user $USER):
  <job-id>  <job-name>  <partition>  <state>  <runtime>  <nodes>  <reason-or-host>
  ...

PARTITIONS:
  p.hpcl93  up   <idle>/<total> idle  GPU: L40S x4/node
  p.hpcl8   up   <idle>/<total> idle  GPU: RTX5000 x2/node
  p.hpcl92  up   <idle>/<total> idle  CPU

[optional one-line recommendation]
```

Keep under 12 lines. The point is fast visibility, not a full report.

## Notes

- This skill exists because *"how are the jobs?"* recurred 3+ distinct times in a single May-17 session — cluster opacity is the operator's #1 friction. Surfacing this proactively (per global CLAUDE.md guidance) reduces it.
- The `binder-design` repo's `design-cli traffic` CLI subcommand is the local origin of this pattern; this skill hoists it to global so it works in any project on the cluster.
- For long pipelines, consider running this every few turns even unprompted (when the user's prior turn launched jobs) — but don't spam; ≥4-turn cadence unless something changes.
