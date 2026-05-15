# ManaLoom Internal Test Checklist - Non-Scanner - 2026-05-15

Use this checklist for real-user internal testing only. The scope is
**non-scanner**. Scanner, camera, OCR and MLKit physical capture are
**DEFERRED / NOT PROVEN** and must not be tested as release acceptance items.

Do not record secrets, JWTs, full QA e-mails, passwords, raw prompts, complete
decklists, `SENTRY_DSN`, `DATABASE_URL` or `OPENAI_API_KEY`.

## Test session header

| Field | Value |
| --- | --- |
| Tester | |
| Date/time | |
| App build/version | |
| Device and OS | |
| Network | Wi-Fi / cellular / other |
| Backend | `https://evolution-cartinhas.8ktevp.easypanel.host` |
| Backend `/health` | PASS / FAIL / not checked |
| QA account | `qa+...@<redacted>` |

## P0 pre-flight

| Check | Expected | Status | Notes |
| --- | --- | --- | --- |
| App opens | No crash on launch | | |
| Backend reachable | Public `/health` is healthy | | |
| No scanner acceptance | Scanner/camera/OCR left untested and marked deferred | | |
| Redaction | Notes/screenshots contain no full e-mail, token or complete decklist | | |

## Auth and profile

| Check | Expected | Status | Notes |
| --- | --- | --- | --- |
| Register disposable QA user | User is created and logged in | | |
| Logout/login | Same QA user can log in again | | |
| Current user | Profile/current user loads | | |
| Edit display/profile fields | Save works or clear validation error appears | | |
| Bad login | Friendly error; no raw backend/provider text | | |

## Search, cards and sets

| Check | Expected | Status | Notes |
| --- | --- | --- | --- |
| Search a common card | Results load with image/name/set data | | |
| Search empty/rare term | Empty/error state is understandable | | |
| Open card details/printing if available | Details load without crash | | |
| Sets catalog | Future/current/older sets load | | |
| Set detail | Cards in selected set load and paginate/search if available | | |

## Decks

| Check | Expected | Status | Notes |
| --- | --- | --- | --- |
| Create Commander deck manually | Deck saves and appears in list | | |
| Add card by search | Card appears with correct quantity | | |
| Edit quantity/remove card | Deck updates correctly | | |
| Commander slot | Commander remains preserved outside the 99 when applicable | | |
| Public/private toggle | Visibility change is reflected in UI | | |
| Import/paste list if available | Validation result is understandable; do not report full list | | |
| Deck details | Stats, cards and actions render without overflow/crash | | |

## Generate AI

| Check | Expected | Status | Notes |
| --- | --- | --- | --- |
| Generate Commander with commander name | Async/progress UX appears; preview loads | | |
| Preview generated deck | Shows understandable card groups and validation | | |
| Save generated deck | Deck opens in details after save | | |
| Validate generated deck | `validation_ok` equivalent is clear in UI/API result | | |
| Slow generate | User sees progress/retry/error copy, not a frozen screen | | |
| Bad prompt/minimal input | Friendly validation; no raw provider error | | |

## Optimize AI

| Check | Expected | Status | Notes |
| --- | --- | --- | --- |
| Optimize complete deck | Preview or valid no-op/quality message appears | | |
| Light/focused/aggressive choices | Each selectable intensity is understandable | | |
| Apply selected swaps | Only selected changes apply; commander preserved | | |
| Safe no-op | No-op/quality rejection is explained, not shown as success with hidden changes | | |
| Rebuild guidance if offered | CTA/copy is understandable | | |
| Validate after optimize | Deck remains legal/consistent or clear issue is shown | | |

## Validate

| Check | Expected | Status | Notes |
| --- | --- | --- | --- |
| Validate legal Commander deck | Valid result with useful summary | | |
| Validate known issue | Missing/off-identity/quantity issue is explained | | |
| Re-open validation after edits | Result refreshes and does not show stale state | | |

## Binder

| Check | Expected | Status | Notes |
| --- | --- | --- | --- |
| Add binder item | Quantity/condition/foil/trade/sale fields save | | |
| Edit binder item | Updates persist after refresh | | |
| Filter/search binder | Results match selected filters | | |
| Delete binder item | Item is removed with confirmation/safe UX | | |
| Binder stats | Stats load or show clear empty state | | |

## Marketplace and trades

| Check | Expected | Status | Notes |
| --- | --- | --- | --- |
| Marketplace browse/search | Public items load without private data exposure | | |
| Item detail/owner profile | Card/owner info is clear | | |
| Start trade from marketplace | Trade proposal screen opens | | |
| Create trade with two QA users | Offer sends and appears for receiver | | |
| Respond accept/decline | Status changes correctly | | |
| Trade status timeline | Shipped/delivered/completed flow is clear when tested | | |
| Trade messages/attachment URL field | Message sends; no token/private data in UI | | |

## Messages and notifications

| Check | Expected | Status | Notes |
| --- | --- | --- | --- |
| Conversation inbox | Conversations load with unread state | | |
| Send direct message | Receiver sees message | | |
| Mark read | Badge/count updates | | |
| Notifications list/count | Notification badge/list loads | | |
| Notification tap | Navigates to relevant context where supported | | |
| Push delivery | Validate only if build/environment is configured for it | | |

## Life Counter / Lotus

| Check | Expected | Status | Notes |
| --- | --- | --- | --- |
| Open Life Counter/Lotus | Screen opens without WebView/runtime crash | | |
| Adjust players/life | Controls respond correctly | | |
| Reset/new game | State resets as expected | | |
| Rotate/background/return | UI remains usable | | |

## Explicitly deferred

| Item | Status | Notes |
| --- | --- | --- |
| Scanner physical camera | DEFERRED | Not an acceptance item in this cycle. |
| OCR / MLKit capture | DEFERRED | Not an acceptance item in this cycle. |
| Claiming simulator proof as physical scanner proof | FORBIDDEN | Requires separate physical-device scanner proof. |

## Bug report template

```text
Severity: P0/P1/P2/P3/Out of scope
Flow:
Device/OS:
Network:
Build/version:
QA account: qa+...@<redacted>
Steps:
Expected:
Actual:
Retry result:
Attachment path or screenshot note:
Redaction checked: yes/no
```

Severity guide:

| Severity | Use when |
| --- | --- |
| P0 | Crash on launch/login, data loss, private data/secret exposure, backend outage. |
| P1 | Core non-scanner flow unusable for most testers. |
| P2 | Important flow fails intermittently or has workaround. |
| P3 | Visual/copy/accessibility issue without task blocker. |
| Out of scope | Scanner/camera/OCR issue during this cycle; mark deferred. |
