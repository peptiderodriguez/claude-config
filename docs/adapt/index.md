# Make it yours

This repo is one researcher's brain, not a framework. Forking it usefully means keeping the *machinery* and replacing the *content*.

## 1. Fork and install

```bash
git clone <your-fork-url> ~/code/claude-config
cd ~/code/claude-config
./install.sh
```

`install.sh` rewrites the `__CLAUDE_HOME__` placeholder to your `$HOME` and derives your memory directory automatically — no manual path edits needed.

## 2. Prune the memory (do this first)

`memory/*.md` is the most personal layer — it names projects, collaborators, and domain facts that are not yours. Delete what doesn't apply and let your own [scar-tissue rules](../philosophy/index.md) accumulate via the correction-frequency gate. Update `memory/MEMORY.md` to match.

## 3. Rewrite `CLAUDE.md` from the method, not the text

Keep the structure (driving philosophies with falsifiable triggers, house style, the meta-rule) but swap the incidents for your own. Copying someone else's scars wholesale gives you rules that never fire.

## 4. Edit the two hardcoded spots in `sync.sh`

- **Skills whitelist** (`sync.sh:14`) — add the skills you author, or `sync.sh` won't pull them back.
- **`MEM_SRC`** — points at the directory derived from `$HOME/data/code`; repoint it if your durable memory lives elsewhere.

## 5. Drop the cluster pieces if you're not on HPC

`squeue_inject`, `pre_sbatch_guard`, and `scancel_guard` are inert (or noisy) off a SLURM cluster. Remove their wiring from `settings.json` if they don't apply.

## 6. Decide public vs private

The memory and `CLAUDE.md` carry personal context even after pruning. A **private repo is recommended** unless you've deliberately genericized everything.

## Where to go next

- **Build a config like this from your own usage** → [The `/onboard` meta-analysis](meta-analysis.md) (mine your transcripts → reframe → install).
- **Give one of your pipelines a guided Claude UI** → [Writing an `/analyze` guide](analyze-pattern.md) (+ a copy-paste template).
- **Grab the domain-free reusable tier** → [Building blocks](building-blocks.md) (the anti-rot CI/hygiene drop-in).
