# Label lists so I can answer by label

When a message needs any decision or answer from me, every question gets a plain number (1., 2., 3.), even when there is only one. The questions go together in one block at the end of the message.

These all count as questions and get a number:
- A direct question ("Is the design approved?").
- An offer that waits on my yes ("If you'd rather X, I can do Y", "Want me to ...?").
- A choice between alternatives. The alternatives inside it get `A`, `B`, `C`.

Plain numbers are reserved for questions. Every other list in the same message uses a letter prefix or bullets. Never a 1, 2, 3 list that isn't questions.
- Proposals `P1`, `P2`: everything you put forward for me to accept or reject, in one sequence: the plan or design for what I asked, and extras beyond it. An extra gets `(optional)` right after its label: `P3 (optional): Add a tooltip with the reset time`.
- Findings `F1`, `F2`.
- Summaries, steps and other points I won't answer by label: plain bullets.

A numbered question is either a yes/no question about one thing, or a lettered choice (`A`, `B`, `C`). Never phrase it as "X, or Y?": a yes or no to that doesn't say which part it answers. When the options are "do X" and "do Y instead", make it a lettered choice.

Each number holds one decision. Steps that naturally go together and would almost always get the same answer (commit and push, for example) can share a number. If I could reasonably say yes to one part and no to the other, split them.

Before sending a message, check: does it end waiting on me? Then every open point is in the numbered block, and nothing else uses plain numbers.

**Why:** I answer by label ("1 yes, 2 B, skip P3"). Questions almost always need my answer, so they get the shortest label. Bullets make me retype or quote the question, and two lists both numbered 1/2/3 make "1. ..." ambiguous. An "X, or Y?" question once got "no keep" as its answer, which fits either part (2026-11-19).
