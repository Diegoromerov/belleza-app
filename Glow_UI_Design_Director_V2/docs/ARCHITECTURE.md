# V2 Architecture

```text
                     GlowApp Repository
                            |
                  +---------v---------+
                  | Discovery Engine  |
                  +---------+---------+
                            |
             +--------------+--------------+
             |                             |
      Static Code Audit              Runtime Renderer
             |                             |
             |                    +--------v--------+
             |                    | Browser/Device  |
             |                    +--------+--------+
             |                             |
             +--------------+--------------+
                            |
                     Evidence Store
                            |
                    +-------v-------+
                    | Design Brain  |
                    | UI / UX / A11Y|
                    +-------+-------+
                            |
                   Proposal Generator
                            |
                     BEFORE snapshot
                            |
                     Temporary worktree
                            |
                    Experimental change
                            |
                     AFTER snapshot
                            |
                     Visual comparator
                            |
                   Regression Gate
                     /           \
                 reject          accept
                   |               |
                revise          patch export
                                   |
                           human review
```

## Principle

The AI is not the source of truth. The source of truth is:
1. existing code;
2. rendered application;
3. explicit project constraints;
4. evidence.

The AI generates hypotheses and implementation proposals that must pass validation.
