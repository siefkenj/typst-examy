// The data in examy-regions.json (and `<examy-regions>`), as the
// manual shows it (pages/metadata.typ, which leaves out this
// comment). check-metadata-schema.mjs checks examy's output against
// it. Self-contained, as the manual shows it whole: `Question` is
// also in examy-rubric.ts.

/**
 * A point on a page, in points (pt) from the page's top left, to a
 * tenth of a point.
 */
export type Position = {
  /** Page number, counting from 1. */
  "page": number;
  "x": number;
  "y": number;
};

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

/** A page the exam is on, in points (pt). */
export type Page = {
  /** Page number, counting from 1. */
  "page": number;
  "width": number;
  "height": number;
  /**
   * The page's margins. With mirrored margins, `left` and `right` are
   * this page's.
   */
  "margin": { "top": number; "bottom": number; "left": number; "right": number };
};

/** A line of a `#name-block()`. */
export type NameBlockRegion = {
  /**
   * Markdown representation of the line's prefix. E.g. `"Name:"`;
   * `null` if none.
   */
  "display-name": string | null;
  /** Top left of the line. */
  "start": Position;
  /** Bottom right of the line. */
  "end": Position;
};

/** An answer box, to the outside of its outline as it is drawn. */
export type AnswerBox = {
  /** Top left of the box. */
  "top": Position;
  /** Bottom right of the box. */
  "bottom": Position;
};

/** Where a question/part/subpart is on the page. */
export type QuestionRegion = Question & {
  /** Top left of its label. */
  "start": Position | null;
  /**
   * Bottom right of everything in it, its parts and answer boxes too.
   */
  "end": Position | null;
  /** The answer boxes in its own text, not its parts'. */
  "answer-boxes": AnswerBox[];
};

export type ExamyRegions = {
  /**
   * Identifies the data. An incompatible later version will have
   * another `format`.
   */
  "format": "examy-regions";
  /**
   * Markdown representation of the global `config`'s `exam-name`;
   * `null` if it is not set.
   */
  "exam-name": string | null;
  /** Each page the exam is on, in order. */
  "pages": Page[];
  /** Each line of the exam's `#name-block()`, in order. */
  "name-block-regions": NameBlockRegion[];
  /** Each question/part/subpart, in order. */
  "question-regions": QuestionRegion[];
};
