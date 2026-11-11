# Code comments and docstrings

- Comments explain why, not what, written as if the code had always been this way. No archaeology ("previously", "no longer", "now"); that story belongs in the commit. Name the constraint, not the journey. Say it once; point to the existing rationale instead of copying it.
- Comments and docstrings are plain declaratives: one statement of what happens and, if needed, the condition or reason as a short clause. No storytelling connectives ("X, but Y, so Z"), no passive narration ("are told"), no making code an actor ("let the entities pick").
    - Good: `# Update the price entities at the start of every hour, when prices change.`
    - Not: `# Prices start on the hour, but the coordinator polls every 15 minutes from setup, so the price entities are told when a new hour starts.`
