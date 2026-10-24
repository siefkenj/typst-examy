// The playground (pages/playground.typ): a whole document, edited on the
// left and compiled on the right as it is edited, in the browser (see
// compiler.ts), the two side by side at widths the reader can change. It
// starts from the package's template, template/main.typ; what is typed is
// kept in the browser's local storage, so that it is still there when the
// page is opened again. The editor completes examy's functions and their
// arguments (see completions.ts). The document can be downloaded as a PDF,
// as the exam or as its answer key, whichever is shown, or as its source.
//
// The document imports examy as a published package
// (`#import "@preview/examy:..."`); the playground compiles it with the
// package's own source, which the site is built from, whatever the version.

import type { Export } from "./completions";
import { describe, element, isLoaded, loadCompiler, siteFile, withSource, type Typst } from "./compiler";
import type { Editor } from "./editor";

/** Where the document is kept, whether the answer key is shown, and the
 *  share of the width the code takes, in percent. */
const SOURCE_KEY = "examy-playground:source";
const KEY_KEY = "examy-playground:answer-key";
const SPLIT_KEY = "examy-playground:split";

/** The code's share of the width, in percent: at first, and at least and at
 *  most. */
const SPLIT = { initial: 50, min: 20, max: 80 };

/** The document's path in the compiler's files. */
const MAIN = "/playground.typ";

/** An import of examy, which is compiled with the package's own source. */
const IMPORT = /"@preview\/examy:[^"]*"/g;

/** A diagnostic, as typst.ts reports it with `diagnostics: "full"`. */
interface Diagnostic {
  path: string;
  severity: string;
  /** `line:column-line:column`, from 0. */
  range: string;
  message: string;
}

function load(key: string): string | null {
  try {
    return localStorage.getItem(key);
  } catch {
    return null;
  }
}

function store(key: string, value: string | null): void {
  try {
    if (value === null) localStorage.removeItem(key);
    else localStorage.setItem(key, value);
  } catch {
    // Without storage, the document lasts as long as the page.
  }
}

/** Compile `source` to `format` (0: vector, for the preview; 1: PDF). */
function compile<F extends 0 | 1>(
  source: string,
  solutions: boolean,
  format: F,
): Promise<{ result?: Uint8Array; diagnostics: Diagnostic[] }> {
  return withSource(MAIN, source.replace(IMPORT, '"/src/lib.typ"'), async ($typst: Typst) => {
    const compiler = await $typst.getCompiler();
    const { result, diagnostics } = await compiler.compile({
      mainFilePath: MAIN,
      inputs: { "show-solutions": String(solutions) },
      format,
      diagnostics: "full",
    });
    return { result, diagnostics: (diagnostics ?? []) as Diagnostic[] };
  });
}

/** Room between the preview's pages, in points. */
const PAGE_GAP = 16;

/**
 * Lay the pages typst.ts draws (`g.typst-page`, one under the other, on a
 * transparent background) out as sheets of paper: each on a white sheet,
 * `PAGE_GAP` apart.
 */
function paginate(svg: SVGSVGElement): void {
  const pages = [...svg.querySelectorAll<SVGGElement>(":scope > g.typst-page")];
  pages.forEach((page, i) => {
    const y = Number(/translate\(\s*[-\d.]+\s*,\s*([-\d.]+)/.exec(page.getAttribute("transform") ?? "")?.[1] ?? 0);
    page.setAttribute("transform", `translate(0, ${y + i * PAGE_GAP})`);
    const sheet = document.createElementNS("http://www.w3.org/2000/svg", "rect");
    sheet.setAttribute("class", "playground-sheet");
    sheet.setAttribute("width", page.dataset.pageWidth ?? "0");
    sheet.setAttribute("height", page.dataset.pageHeight ?? "0");
    page.prepend(sheet);
  });
  const [x, y, width, height] = (svg.getAttribute("viewBox") ?? "").split(/\s+/).map(Number);
  const taller = height + PAGE_GAP * Math.max(pages.length - 1, 0);
  svg.setAttribute("viewBox", `${x} ${y} ${width} ${taller}`);
  svg.setAttribute("height", String(taller));
}

/** Save `data` as a file named `name`. */
function download(data: BlobPart, type: string, name: string): void {
  const url = URL.createObjectURL(new Blob([data], { type }));
  const a = element("a", { href: url, download: name });
  document.body.append(a);
  a.click();
  a.remove();
  setTimeout(() => URL.revokeObjectURL(url), 1000);
}

/** A button for the playground's bars. */
function button(text: string, title: string, className = "live-button"): HTMLButtonElement {
  return element("button", { type: "button", className, textContent: text, title });
}

/** A pane's bar, with `start` at its start and `end` at its end. */
function paneBar(start: Node[], end: Node[]): HTMLElement {
  const bar = element("div", { className: "playground-bar" });
  bar.append(...start, element("span", { className: "playground-spacer" }), ...end);
  return bar;
}

export function mount(root: HTMLElement): void {
  const original = root.dataset.source ?? "";
  const sourcePane = root.querySelector<HTMLElement>(".playground-source");
  const codeBox = root.querySelector<HTMLElement>(".playground-code");
  const outputPane = root.querySelector<HTMLElement>(".playground-output");
  const preview = root.querySelector<HTMLElement>(".playground-preview");
  if (!sourcePane || !codeBox || !outputPane || !preview) return;

  let code = load(SOURCE_KEY) ?? original;
  let solutions = load(KEY_KEY) === "true";

  // The code's bar: the document's name, and what can be done to its code.
  const reset = button("Start over", "Discard your changes and start again from the template");
  reset.hidden = code === original;
  const source = button("Download .typ", "Save the document's code");
  const name = element("span", { className: "playground-file", textContent: "exam.typ" });
  sourcePane.prepend(paneBar([name], [reset, source]));

  // The preview's bar: which version it shows, a switch rather than an
  // action, and the PDF of it.
  const views = element("div", { className: "playground-view" });
  views.setAttribute("role", "group");
  views.setAttribute("aria-label", "Version");
  const examView = button("Exam", "Show the exam, as students get it", "");
  const keyView = button("Answer key", "Show the answer key: the exam with its solutions (show-solutions: true)", "");
  views.append(examView, keyView);
  const status = element("span", { className: "live-status" });
  status.setAttribute("role", "status");
  const pdf = button("Download PDF", "Save the version shown as a PDF", "live-button primary");
  outputPane.prepend(paneBar([views, status], [pdf]));

  const errors = element("ul", { className: "playground-errors", hidden: true });
  preview.before(errors);

  // Between the two, what changes their widths.
  const divider = element("div", { className: "playground-divider", tabIndex: 0 });
  divider.setAttribute("role", "separator");
  divider.setAttribute("aria-orientation", "vertical");
  divider.setAttribute("aria-label", "Width of the code and the preview");
  divider.setAttribute("aria-valuemin", String(SPLIT.min));
  divider.setAttribute("aria-valuemax", String(SPLIT.max));
  divider.title = "Drag to change the widths; double-click to make them equal";
  sourcePane.after(divider);

  // The editor, in place of the highlighted code once it has loaded, with
  // completions once they have too (or without them, if they cannot be).
  let editor: Editor | null = null;
  const exports = fetch(siteFile("live/completions.json"))
    .then((r) => (r.ok ? (r.json() as Promise<Export[]>) : null))
    .catch(() => null);
  void Promise.all([import("./editor"), import("./completions"), exports]).then(
    ([{ createEditor }, { examyCompletions }, exports]) => {
      const holder = element("div", { className: "live-code" });
      const completions = exports ? examyCompletions(exports, siteFile("./")) : undefined;
      editor = createEditor(holder, code, changed, "Document", completions);
      codeBox.replaceChildren(holder);
    },
    (e: unknown) => setStatus(`Could not load the editor: ${describe(e)}`),
  );

  function setStatus(text: string): void {
    status.textContent = text;
  }

  function setSplit(percent: number, save = false): void {
    const split = Math.min(SPLIT.max, Math.max(SPLIT.min, percent));
    root.style.setProperty("--split", `${split}%`);
    divider.setAttribute("aria-valuenow", String(Math.round(split)));
    if (save) store(SPLIT_KEY, split === SPLIT.initial ? null : String(split));
  }
  setSplit(Number(load(SPLIT_KEY) ?? SPLIT.initial));

  divider.addEventListener("pointerdown", (down) => {
    if (down.button !== 0) return;
    down.preventDefault();
    divider.setPointerCapture(down.pointerId);
    root.classList.add("resizing");
    const box = root.getBoundingClientRect();
    const move = (e: PointerEvent) => setSplit(((e.clientX - box.left) / box.width) * 100);
    const up = (e: PointerEvent) => {
      move(e);
      setSplit(parseFloat(root.style.getPropertyValue("--split")), true);
      root.classList.remove("resizing");
      divider.removeEventListener("pointermove", move);
      divider.removeEventListener("pointerup", up);
      divider.removeEventListener("pointercancel", up);
    };
    divider.addEventListener("pointermove", move);
    divider.addEventListener("pointerup", up);
    divider.addEventListener("pointercancel", up);
  });
  divider.addEventListener("dblclick", () => setSplit(SPLIT.initial, true));
  divider.addEventListener("keydown", (e) => {
    const now = parseFloat(root.style.getPropertyValue("--split"));
    const to = { ArrowLeft: now - 5, ArrowRight: now + 5, Home: SPLIT.min, End: SPLIT.max }[e.key];
    if (to === undefined) return;
    e.preventDefault();
    setSplit(to, true);
  });

  function showView(): void {
    examView.setAttribute("aria-pressed", String(!solutions));
    keyView.setAttribute("aria-pressed", String(solutions));
    root.classList.toggle("key", solutions);
  }
  showView();

  function showDiagnostics(diagnostics: Diagnostic[]): void {
    errors.replaceChildren(
      ...diagnostics.map((d) => {
        const item = element("li", { className: d.severity.toLowerCase() === "error" ? "error" : "warning" });
        const [line, column] = d.range.split("-")[0].split(":").map(Number);
        const where = d.path === MAIN ? `line ${line + 1}` : `${d.path.replace(/^\//, "")}:${line + 1}`;
        const at = element("button", { type: "button", className: "playground-at", textContent: where });
        // Only the document's own lines can be gone to.
        if (d.path === MAIN) at.addEventListener("click", () => editor?.goto(line + 1, column + 1));
        else at.disabled = true;
        item.append(at, " ", d.message);
        return item;
      }),
    );
    errors.hidden = diagnostics.length === 0;
  }

  let generation = 0;
  async function update(): Promise<void> {
    const mine = ++generation;
    setStatus(isLoaded() ? "Compiling…" : "Loading the Typst compiler…");
    try {
      const { result, diagnostics } = await compile(code, solutions, 0);
      if (mine !== generation) return; // a newer edit is on its way
      showDiagnostics(diagnostics);
      if (!result) {
        setStatus("Error");
        return;
      }
      const svg = await (await loadCompiler()).svg({ vectorData: result });
      if (mine !== generation) return;
      // Kept where it was scrolled to, across the swap.
      const top = preview!.scrollTop;
      preview!.innerHTML = svg;
      const drawn = preview!.querySelector("svg");
      if (drawn) paginate(drawn);
      preview!.scrollTop = top;
      setStatus("");
    } catch (e) {
      if (mine !== generation) return;
      errors.replaceChildren(element("li", { className: "error", textContent: describe(e) }));
      errors.hidden = false;
      setStatus("Error");
    }
  }

  let timer: ReturnType<typeof setTimeout> | undefined;
  function changed(text: string): void {
    code = text;
    reset.hidden = code === original;
    store(SOURCE_KEY, code === original ? null : code);
    clearTimeout(timer);
    timer = setTimeout(update, 350);
  }

  for (const [view, key] of [[examView, false], [keyView, true]] as const) {
    view.addEventListener("click", () => {
      if (solutions === key) return;
      solutions = key;
      showView();
      store(KEY_KEY, solutions ? "true" : null);
      void update();
    });
  }

  reset.addEventListener("click", () => {
    if (!confirm("Discard your changes and start again from the template?")) return;
    // An edit like any other, which saves and recompiles the document.
    if (editor) editor.replace(original);
    else changed(original);
  });

  source.addEventListener("click", () => download(code, "text/plain", "exam.typ"));

  pdf.addEventListener("click", async () => {
    pdf.disabled = true;
    setStatus("Writing the PDF…");
    try {
      const { result, diagnostics } = await compile(code, solutions, 1);
      if (!result) {
        showDiagnostics(diagnostics);
        setStatus("Could not write the PDF: the document has errors");
        return;
      }
      download(new Uint8Array(result), "application/pdf", solutions ? "exam-key.pdf" : "exam.pdf");
      setStatus("");
    } catch (e) {
      setStatus(`Could not write the PDF: ${describe(e)}`);
    } finally {
      pdf.disabled = false;
    }
  });

  void update();
}
