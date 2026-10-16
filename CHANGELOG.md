# Changelog

## Unreleased

- **Breaking:** an answer box with no `height` now fits its content instead
  of always being `default_height` tall. A box holding only a prompt shrinks to
  the prompt; give it a height (e.g. `height: 2cm`) to keep room to write.
- Solutions in a box with no `height` take no space, so the answer key lays
  out exactly like the exam. `height: auto` makes the box grow to hold them.
- `choices(enumerate: ...)` puts labels (A, B, C, … or any numbering pattern)
  inside the bubbles. Set it for the whole document with `choices-enumerate`.
- New `config` options: `bubble-stroke` and `bubble-label-font`.
- Template: start a new exam with `typst init @preview/examy`.

## 0.4.0 — 2026-10-05

- Multiple-choice bubbles: `choice`, `choices`.
- Solutions in an answer box widen automatically to fill it.
- Fixed the spacing of points on a question with no body.

## 0.3.0 — 2026-09-19

- `fr` answer boxes on the same page share the leftover space equally.

## 0.2.0 — 2026-07-14

- Redesign of the package.
