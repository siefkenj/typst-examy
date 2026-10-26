// The live editor: an "Edit" button on every example, which turns its code
// into a code editor (editor.ts) and recompiles the example as it is edited,
// in the browser, with typst.ts (see compiler.ts).
//
// The site works without it: every example is rendered when the site is
// built. The compiler is only downloaded once an example is first edited. It
// compiles live-main.typ, which renders the edited code with the same
// render.typ the site is built with, from the package's own source.
//
// Bundled by Vite (see vite.config.ts) into live.js, which also starts the
// playground on the page that has one (see playground.ts).

import { describe, element, isLoaded, loadCompiler, withSource, type Typst } from "./compiler";
import type { Editor } from "./editor";

/** The inputs live-main.typ reads: see the `data-` attributes of `example`. */
type Inputs = Record<"solutions" | "wrap" | "width" | "height" | "inset" | "margin", string>;

/** The editor's state, also as `data-live` on the example's figure. */
type State = "loading" | "compiling" | "ready" | "error";

/** Compile `source` as the example, /example.typ, with `job`. */
function withExample<T>(source: string, job: (typst: Typst) => Promise<T>): Promise<T> {
  return withSource("/example.typ", source, job);
}

/** One view of an example (see live-main.typ). */
function compile(source: string, inputs: Inputs): Promise<string> {
  return withExample(source, ($typst) => $typst.svg({ mainFilePath: "/docs/site/live-main.typ", inputs }));
}

/**
 * An example's code as a whole document, which compiles in a document of its
 * own: written by the same Typst code as the site's build writes it (see
 * live-full.typ).
 */
function fullDocument(source: string, wrap: string): Promise<string> {
  return withExample(source, async ($typst) => {
    // Compiled first, then queried, in one snapshot of the files: the
    // snippet's own `query` searches a document it has not compiled.
    const compiler = await $typst.getCompiler();
    const found = await compiler.runWithWorld(
      { mainFilePath: "/docs/site/live-full.typ", inputs: { wrap } },
      async (world) => {
        const result = await world.compile();
        if (result.hasError) throw result.diagnostics ?? new Error("could not compile the whole document");
        return world.query<unknown>({ selector: "<full-source>", field: "value" });
      },
    );
    const value = Array.isArray(found) ? found[0] : found;
    if (typeof value !== "string") throw new Error("could not write the whole document");
    return value;
  });
}

function enhance(figure: HTMLElement): void {
  const codeBox = figure.querySelector<HTMLElement>(".example-code");
  // The example's code as shown, and as a whole document (see `example` in
  // template.typ), highlighted by the site's build.
  const shortCode = codeBox?.querySelector<HTMLElement>(".code-short");
  const fullCode = codeBox?.querySelector<HTMLElement>(".code-full");
  const output = figure.querySelector(".example-output");
  if (!codeBox || !shortCode || !output) return;
  const original = figure.dataset.source ?? "";
  const originalFull = figure.dataset.full ?? original;
  const papers = [...figure.querySelectorAll<HTMLElement>(".paper")];

  const edit = element("button", { type: "button", className: "live-button", textContent: "Edit" });
  const reset = element("button", { type: "button", className: "live-button", textContent: "Reset", hidden: true });
  const whole = element("button", { type: "button", className: "live-button live-toggle", textContent: "Full example" });
  whole.title = "Show the example as a whole document, to copy into a blank one";
  whole.setAttribute("aria-pressed", "false");
  const status = element("span", { className: "live-status" });
  status.setAttribute("role", "status");
  const bar = element("div", { className: "live-bar" });
  // An example that is a whole document already has none to switch to.
  bar.append(status, reset, ...(fullCode ? [whole] : []), edit);
  codeBox.prepend(bar);

  // The code editor, made on the first edit (see editor.ts), in place of the
  // highlighted code while editing.
  const holder = element("div", { className: "live-code", hidden: true });
  codeBox.append(holder);
  let editor: Promise<Editor> | null = null;
  let code = original;
  // Whether the whole document is shown; the code as shown when it was asked
  // for, to go back to; and the whole document as it was written then, to
  // tell whether it has been edited since.
  let full = false;
  let shortText = original;
  let fullWritten = originalFull;

  const error = element("pre", { className: "live-error", hidden: true });
  output.before(error);

  const setState = (state: State, text: string) => {
    figure.dataset.live = state;
    status.textContent = text;
  };
  const showError = (text: string | null) => {
    error.textContent = text ?? "";
    error.hidden = text === null;
  };

  let generation = 0;
  async function update(): Promise<void> {
    const mine = ++generation;
    setState("compiling", isLoaded() ? "Compiling…" : "Loading the Typst compiler…");
    try {
      const svgs: string[] = [];
      for (const paper of papers) {
        svgs.push(
          await compile(code, {
            solutions: paper.dataset.solutions ?? "false",
            // A whole document is compiled as it is.
            wrap: full ? "false" : (figure.dataset.wrap ?? "auto"),
            width: figure.dataset.width ?? "12cm",
            height: figure.dataset.height ?? "none",
            inset: figure.dataset.inset ?? "0pt",
            margin: figure.dataset.margin ?? "none",
          }),
        );
      }
      if (mine !== generation) return; // a newer edit is on its way
      papers.forEach((paper, i) => {
        // The build's rendering: an inline SVG, or the image of a paged one
        // (an example shown `paged-name`; see template.typ).
        const old = paper.querySelector<HTMLElement>("svg, img");
        const holder = element("div", { innerHTML: svgs[i] });
        const svg = holder.querySelector("svg");
        if (!svg) return;
        // As wide as the build's own rendering, which is the same page.
        if (old?.style.width) svg.style.width = old.style.width;
        if (old) old.replaceWith(svg);
        else paper.append(svg);
      });
      showError(null);
      setState("ready", "");
    } catch (e) {
      if (mine !== generation) return;
      showError(describe(e));
      setState("error", "Error");
    }
  }

  let timer: ReturnType<typeof setTimeout> | undefined;
  const changed = (text: string) => {
    code = text;
    reset.hidden = code === (full ? originalFull : original);
    clearTimeout(timer);
    timer = setTimeout(update, 350);
  };
  // Whether the example is being edited. The highlighted code stays in place
  // until the editor is ready, so that the code box keeps its height while
  // the editor loads, and is swapped for it then.
  let editing = false;
  // Swap the two, then `then` (focusing the editor), keeping the page where
  // it was: the buttons stay put on screen, whatever the swap, the focus, or
  // the editor's first layout (a frame later) would scroll.
  const showEditor = (on: boolean, then?: () => void) => {
    const top = edit.getBoundingClientRect().top;
    const steady = () => {
      const drift = edit.getBoundingClientRect().top - top;
      if (Math.abs(drift) >= 1) window.scrollBy(0, drift);
    };
    holder.hidden = !on;
    shortCode.hidden = on || full;
    if (fullCode) fullCode.hidden = on || !full;
    then?.();
    steady();
    requestAnimationFrame(steady);
  };
  edit.addEventListener("click", () => {
    editing = !editing;
    edit.textContent = editing ? "Done" : "Edit";
    figure.classList.toggle("editing", editing);
    if (!editing) {
      showEditor(false);
      return;
    }
    editor ??= import("./editor").then(({ createEditor }) => createEditor(holder, code, changed));
    editor.then(
      (e) => {
        // Unless editing was done with before the editor was ready.
        if (!editing) return;
        showEditor(true, () => e.focus());
      },
      (e: unknown) => showError(`Could not load the editor: ${describe(e)}`),
    );
    if (!isLoaded()) setState("loading", "Loading the Typst compiler…");
    loadCompiler().then(
      () => {
        if (figure.dataset.live === "loading") setState("ready", "");
      },
      (e: unknown) => {
        showError(describe(e));
        setState("error", "Could not load the compiler");
      },
    );
  });
  reset.addEventListener("click", () => {
    // An edit like any other, which recompiles the example.
    void editor?.then((e) => e.replace(full ? originalFull : original));
  });

  // Switch between the code as shown and the whole document. Once the code
  // has been edited, the editor switches too: to the whole document of the
  // code as edited, and back to the code as it was before.
  whole.addEventListener("click", async () => {
    const toFull = !full;
    let text: string | null = null;
    // Not edited yet: the editor, when it is made, starts from the code shown.
    if (!editor) code = toFull ? originalFull : original;
    else {
      if (toFull) {
        shortText = code;
        try {
          if (code !== original) setState("compiling", isLoaded() ? "Writing the whole document…" : "Loading the Typst compiler…");
          fullWritten = code === original ? originalFull : await fullDocument(code, figure.dataset.wrap ?? "auto");
        } catch (e) {
          showError(describe(e));
          setState("error", "Error");
          return;
        }
        text = fullWritten;
      } else {
        if (code !== fullWritten && !confirm("Going back to the example as shown loses your changes to the whole document. Go back?")) {
          return;
        }
        text = shortText;
      }
    }
    full = toFull;
    whole.setAttribute("aria-pressed", String(full));
    if (!editing) showEditor(false);
    if (text !== null) {
      const e = await editor!;
      e.replace(text);
    }
  });
}

document.querySelectorAll<HTMLElement>("figure.example").forEach(enhance);

// The playground (pages/playground.typ), loaded only where there is one.
const playground = document.querySelector<HTMLElement>(".playground");
if (playground) void import("./playground").then(({ mount }) => mount(playground));
