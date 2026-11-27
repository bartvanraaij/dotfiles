# Questions: numbered, standalone, typed

When a message needs an answer or decision from me, the questions go in one numbered block at the end of the message.

- Number questions 1, 2, 3 without gaps, starting at 1 in every message. Numbers in my answer ("1 yes, 2 B") always refer to the latest message.
- Each question stands alone: it names its subject in plain words (what, where, what changes) in one or two lines. It never refers to a label or another message ("P13", "the option above", "as discussed"). A question still open from an earlier message is asked again in full, with a new number.
- A question is yes/no about one thing, or a choice between alternatives `A`, `B`, `C`. Never "X, or Y?": a yes or no to that doesn't say which part it answers.
- Every question gives a recommendation: a yes/no question ends with `(recommended: yes)` or `(recommended: no)`; in a choice, one alternative gets `(recommended)` and a short reason. Test checks get none.
- One decision per number. Steps that would almost always get the same answer (commit and push) can share a number; if I could say yes to one part and no to the other, split them.
- An offer that waits on my yes ("Want me to ...?") is a question too.
- Plain numbers are only for questions. Plans, findings, steps and summaries are bullets, without labels like P1 or F1.
- When every item of a list needs my answer (review findings to fix or not, checks to test), that list is the question block: one number per finding or check.
- Keep the text around the questions short; explain more when I ask.
- Ask in text, never with the AskUserQuestion picker.

```
1. sync.ts:42 retries forever when the server returns 401. Stop after 3 tries? (recommended: yes)
2. Which model should subagents use by default?
   A. Sonnet (recommended: cheapest one that handles bounded fixes)
   B. Opus for everything
```

Before sending: does the message end waiting on me? Then every open point is in the block, numbered from 1 without gaps, and each question reads right without anything above it.

**Why:** I answer by number ("1 yes, 2 B"), in sequence, and my sessions are long. Questions numbered to match proposal labels left gaps (1, 4, 5, 9 on 2026-11-26; a first question "4" on 2026-11-27), so I answered the wrong ones. A question "P13: should I change ...?" pointed to a label far up the conversation that I no longer remembered (2026-11-27). An "X, or Y?" question once got "no keep" as its answer, which fits either part (2026-11-19). I type every answer, so I always work the same way; a picker means switching (2026-11-27).
