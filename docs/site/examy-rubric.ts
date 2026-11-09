// The data in examy-rubric.json (and `<examy-rubric>`), as the manual
// shows it (pages/metadata.typ, which leaves out this comment).
// check-metadata-schema.mjs checks examy's output against it.
// Self-contained, as the manual shows it whole: `Question` is also in
// examy-regions.ts.

export type Question = {
  /**
   * Position among its siblings at each level, from 0. E.g. `[0, 2]`
   * for question 1 (c).
   */
  "address": number[];
  /** Label as printed on the exam. E.g. `"1 (c)"`. */
  "display-name": string;
  /** `1` for a question, `2` for a part, and `3` for a subpart. */
  "level": 1 | 2 | 3;
  /**
   * Points given to it directly, not counting its parts; `null` if
   * none are given.
   */
  "points": number | null;
  /**
   * Bonus points given to it directly, not counting its parts; `null`
   * if none are given.
   */
  "bonus-points": number | null;
};

export type RubricItem = {
  "type": "item";
  /**
   * Points the item awards (negative for a deduction); `null` if none
   * are given.
   */
  "points": number | null;
  /** Markdown representation of the item's text, with LaTeX math. */
  "description": string;
  /**
   * Markdown representation of the item's annotation, with LaTeX
   * math; `null` if none.
   */
  "annotation": string | null;
};

export type RubricNote = {
  "type": "note";
  /** Markdown representation of the note's text, with LaTeX math. */
  "text": string;
};

export type RubricGroup = {
  "type": "group";
  /**
   * Markdown representation of the group's title (its first
   * paragraph), with LaTeX math.
   */
  "title": string;
  /**
   * Markdown representation of the text from the title to the first
   * item; `null` if none.
   */
  "note": string | null;
  /**
   * Markdown representation of the group's annotation. E.g.
   * `"pick one"`; `null` if none.
   */
  "annotation": string | null;
  /** The items, groups, and notes in the group, in order. */
  "items": RubricEntry[];
};

/** An entry of a rubric: an item, a group of entries, or a note. */
export type RubricEntry = RubricItem | RubricGroup | RubricNote;

/** The rubric of a question/part/subpart. */
export type Rubric = Question & {
  /** The rubric's items, groups, and notes, in order. */
  "rubric": RubricEntry[];
};

export type ExamyRubric = {
  /**
   * Identifies the data. An incompatible later version will have
   * another `format`.
   */
  "format": "examy-rubric";
  /**
   * Markdown representation of the global `config`'s `exam-name`;
   * `null` if it is not set.
   */
  "exam-name": string | null;
  /** Each question/part/subpart that has a rubric, in order. */
  "rubrics": Rubric[];
};
