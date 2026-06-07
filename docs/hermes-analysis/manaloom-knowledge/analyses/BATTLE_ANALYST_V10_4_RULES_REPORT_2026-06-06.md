# Battle Analyst v10.4 Rules Hardening Report

Date: 2026-06-06

## Scope

This pass corrected simulation rules that materially distorted battle outcomes:

- Mana sources no longer refill whenever the pool reaches zero.
- Untapped source mana is refreshed once at the beginning of each player's turn.
- Treasure tokens are tracked and consumed separately.
- Newly played lands and resolved ramp add only their actual current-turn mana.
- Counterspells must exist in hand, be payable, leave the hand, and go to the graveyard.
- A player no longer counters their own spell.
- Countered spells go to their controller's graveyard.
- Counterspells are reserved for responses instead of being cast proactively.
- Combat prioritizes visible lethal and known Approach of the Second Sun casters.
- Only the attacked player can declare blockers.
- Each blocker is assigned once.
- Regular attacker/blocker damage is reciprocal.
- First strike attackers do not also deal regular damage unless they have double strike.
- Replay output now records mana refreshes and real counterspell actions.

## Validation

Focused regression suite:

- 14/14 tests passed locally.
- 14/14 tests passed inside the Hermes container.
- Python compile checks passed for battle, replay, and regression scripts.

Full simulator run:

- 600 four-player games completed.
- Result: 324 wins, 270 losses, 6 stalls.
- Overall win rate: 54.0%.
- The previous validated baseline was 336 wins, 259 losses, 5 stalls.
- The lower win rate is expected because mana can no longer be reused infinitely and combat defense is now legal.

Structured replay:

- Seed 43 completed with an immediate Approach win on turn 13.
- Mana refresh events were present on every active turn.
- Combat events remained structured.
- Cleanup and immediate game termination remained intact.

## Remaining Modeling Limits

These are not blockers for the current hardening pass, but they remain important for future fidelity:

- Colored mana requirements are still modeled as a generic aggregate.
- Mana persists as an untapped-source budget across phases rather than emptying at every step boundary.
- Multiple blockers, trample, deathtouch, and first-strike blockers are not fully modeled.
- Target selection uses visible board state and known alternate-win information, not hidden-information inference.
- Threat evaluation is heuristic and should eventually learn from validated replay outcomes.
