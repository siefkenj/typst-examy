// The code editor of the live editor (see live.ts): CodeMirror, with Typst
// syntax highlighting from codemirror-lang-typst's Lezer parser of Typst 0.15
// syntax, in the colors of the Typst web app (which the site's own code
// blocks, highlighted by Typst, share). Loaded only once an example is
// first edited, so that a page that is only read stays light; the
// playground (playground.ts) uses it too.

import {
  autocompletion,
  closeBrackets,
  closeBracketsKeymap,
  completionKeymap,
  type CompletionSource,
} from "@codemirror/autocomplete";
import { defaultKeymap, history, historyKeymap, indentWithTab } from "@codemirror/commands";
import { bracketMatching, indentOnInput } from "@codemirror/language";
import { EditorState } from "@codemirror/state";
import { EditorView, drawSelection, highlightActiveLine, keymap } from "@codemirror/view";
import { typst_lezer } from "codemirror-lang-typst/lezer";

/** An example's code editor. */
export interface Editor {
  /** The code as it stands. */
  text(): string;
  /** Replace the code, as an edit (so it can be undone). */
  replace(text: string): void;
  focus(): void;
  /** Put the cursor at `line` and `column` (both from 1), in view, and focus. */
  goto(line: number, column: number): void;
}

/** The editor's look: that of the site's code blocks (see style.css). */
const theme = EditorView.theme({
  "&": { backgroundColor: "#fffdf5", fontSize: ".86rem" },
  "&.cm-focused": { outline: "none" },
  ".cm-scroller": { fontFamily: "var(--mono)", lineHeight: "1.5" },
  ".cm-content": { padding: ".9rem 0", caretColor: "var(--text)" },
  ".cm-line": { padding: "0 1rem" },
  ".cm-activeLine": { backgroundColor: "rgba(29, 95, 180, .05)" },
  ".cm-tooltip": { fontFamily: "var(--font)", fontSize: ".85rem" },
  // A completion's description, beside the list (see completions.ts).
  ".cm-examy-info": { maxWidth: "24rem", whiteSpace: "normal" },
  ".cm-examy-info p": { margin: "0 0 .4rem" },
  ".cm-examy-info code": { fontFamily: "var(--mono)", fontSize: ".8rem" },
  ".cm-examy-detail": { color: "var(--muted)" },
});

/**
 * Make an editor of `doc` in `parent`, calling `onChange` with the code after
 * every edit; `label` names it for screen readers, and `completions`, if
 * given, is what it completes (see completions.ts).
 */
export function createEditor(
  parent: HTMLElement,
  doc: string,
  onChange: (text: string) => void,
  label = "Example code",
  completions?: CompletionSource,
): Editor {
  const view = new EditorView({
    parent,
    state: EditorState.create({
      doc,
      extensions: [
        history(),
        drawSelection(),
        highlightActiveLine(),
        indentOnInput(),
        bracketMatching(),
        closeBrackets(),
        autocompletion(completions ? { override: [completions] } : {}),
        EditorState.tabSize.of(2),
        keymap.of([...closeBracketsKeymap, ...defaultKeymap, ...historyKeymap, ...completionKeymap, indentWithTab]),
        typst_lezer(),
        theme,
        EditorView.contentAttributes.of({ "aria-label": label }),
        EditorView.updateListener.of((update) => {
          if (update.docChanged) onChange(update.state.doc.toString());
        }),
      ],
    }),
  });
  return {
    text: () => view.state.doc.toString(),
    replace: (text) => view.dispatch({ changes: { from: 0, to: view.state.doc.length, insert: text } }),
    focus: () => view.focus(),
    goto: (line, column) => {
      const doc = view.state.doc;
      const at = doc.line(Math.min(Math.max(line, 1), doc.lines));
      const pos = Math.min(at.from + Math.max(column - 1, 0), at.to);
      view.dispatch({ selection: { anchor: pos }, scrollIntoView: true });
      view.focus();
    },
  };
}
