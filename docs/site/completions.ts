// What the playground's editor (see playground.ts and editor.ts) completes:
// examy's exports after a `#`, and, in a call's arguments, the arguments the
// function takes by name, each with its type, default and description. Inside
// `exam(..)` or `exam.with(..)`, and `e.set_(config, ..)`, those are
// `config`'s options. The exports and their arguments come from the
// reference's own data (live/completions.json, written by site.typ).

import type { Completion, CompletionContext, CompletionResult, CompletionSource } from "@codemirror/autocomplete";

/** An argument, as the reference documents it. */
interface Arg {
  name: string;
  /** Its type and its default, as Typst code. */
  type: string | null;
  default: string | null;
  doc: string;
}

/** An export of examy, as live/completions.json gives it. */
export interface Export {
  name: string;
  kind: "function" | "element" | "alias" | "value";
  summary: string | null;
  /** Its reference page, from the site's root. */
  page: string;
  /** The arguments it takes by name. */
  args: Arg[];
  /** Whether it also takes `config`'s options by name. */
  options: boolean;
}

/** An identifier, as Typst writes one: with hyphens. */
const IDENT = "[A-Za-z_][\\w-]*";

/** A bracket left open before the cursor: a call's arguments, or a block. */
interface Open {
  char: "(" | "[" | "{";
  /** Where it is. */
  at: number;
  /** Where each argument after the first starts (after its comma). */
  commas: number[];
}

/** The bracket each closing bracket closes. */
const CLOSES: Record<string, Open["char"]> = { ")": "(", "]": "[", "}": "{" };

/**
 * The brackets left open at the end of `text`, innermost last: Typst's
 * strings, comments, raw text, and math are skipped, and brackets escaped in
 * markup. Approximate, as a completion only needs it to be.
 */
function openBrackets(text: string): Open[] {
  const stack: Open[] = [];
  // Code inside `(..)` and `{..}`; markup elsewhere.
  const code = () => stack.length > 0 && stack[stack.length - 1].char !== "[";
  let i = 0;
  while (i < text.length) {
    const c = text[i];
    const next = text[i + 1];
    if (c === "/" && next === "/" && text[i - 1] !== ":") {
      const end = text.indexOf("\n", i);
      i = end < 0 ? text.length : end;
      continue;
    }
    if (c === "/" && next === "*") {
      const end = text.indexOf("*/", i + 2);
      i = end < 0 ? text.length : end + 2;
      continue;
    }
    if (c === "\\" && !code()) {
      i += 2;
      continue;
    }
    if (c === '"' && code()) {
      let j = i + 1;
      while (j < text.length && text[j] !== '"') j += text[j] === "\\" ? 2 : 1;
      i = j + 1;
      continue;
    }
    if (c === "`") {
      // Raw text, closed by as many backticks as open it.
      let n = 1;
      while (text[i + n] === "`") n++;
      const fence = "`".repeat(n);
      const end = text.indexOf(fence, i + n);
      i = end < 0 ? text.length : end + n;
      continue;
    }
    if (c === "$") {
      let j = i + 1;
      while (j < text.length && text[j] !== "$") j += text[j] === "\\" ? 2 : 1;
      i = j + 1;
      continue;
    }
    // In markup, parentheses are text unless they follow a name, as a
    // call's do, and braces unless they follow a `#`.
    const opens = code()
      ? c === "(" || c === "[" || c === "{"
      : c === "[" || (c === "(" && /[\w-]/.test(text[i - 1] ?? "")) || (c === "{" && text[i - 1] === "#");
    if (opens) stack.push({ char: c as Open["char"], at: i, commas: [] });
    else if (c in CLOSES && stack[stack.length - 1]?.char === CLOSES[c]) stack.pop();
    else if (c === "," && stack.length > 0 && stack[stack.length - 1].char === "(") {
      stack[stack.length - 1].commas.push(i + 1);
    }
    i++;
  }
  return stack;
}

/** A description from the reference, as an element: `code` in code. */
function describe(text: string, extra: [string, string | null][] = [], page?: string): HTMLElement {
  const box = document.createElement("div");
  box.className = "cm-examy-info";
  const p = document.createElement("p");
  // Code in backticks, and Markdown links, shown as their text.
  for (const [i, piece] of text.replace(/\[([^\]]+)\]\([^)\s]+\)/g, "$1").split("`").entries()) {
    if (i % 2 === 0) p.append(piece);
    else p.append(Object.assign(document.createElement("code"), { textContent: piece }));
  }
  box.append(p);
  for (const [label, value] of extra) {
    if (value === null) continue;
    const line = document.createElement("p");
    line.className = "cm-examy-detail";
    line.append(`${label}: `, Object.assign(document.createElement("code"), { textContent: value }));
    box.append(line);
  }
  if (page) {
    const link = Object.assign(document.createElement("a"), { href: page, target: "_blank", textContent: "Reference" });
    box.append(link);
  }
  return box;
}

/**
 * The completion source for `exports`, whose reference pages are found from
 * `base`, the site's root.
 */
export function examyCompletions(exports: Export[], base: string): CompletionSource {
  const byName = new Map(exports.map((x) => [x.name, x]));
  const config = byName.get("config");
  const pageOf = (x: Export, arg?: string) => new URL(x.page + (arg ? `#api-${x.name}--${arg}` : ""), base).href;

  const exportOptions: Completion[] = exports.map((x) => ({
    label: x.name,
    type: x.kind === "value" ? "variable" : "function",
    detail: x.kind,
    info: () => describe(x.summary ?? "", [], pageOf(x)),
  }));

  /** The arguments `x` takes by name, `config`'s options among them. */
  const argsOf = (x: Export): [Export, Arg][] => [
    ...x.args.map((a): [Export, Arg] => [x, a]),
    ...(x.options && config ? config.args.map((a): [Export, Arg] => [config, a]) : []),
  ];

  return (context: CompletionContext): CompletionResult | null => {
    const before = context.state.sliceDoc(0, context.pos);
    const word = context.matchBefore(new RegExp(`${IDENT}$`));
    const from = word ? word.from : context.pos;

    // An export, after a `#` or a show rule's colon.
    if (/(#|show:\s*)$/.test(before.slice(0, from)) && (word || context.explicit)) {
      return { from, options: exportOptions, validFor: new RegExp(`^${IDENT}$`) };
    }

    // An argument by name: the cursor is where one starts in a call's
    // arguments, at the start of the call or after a comma.
    const stack = openBrackets(before);
    const call = stack[stack.length - 1];
    if (!call || call.char !== "(") return null;
    const starts = [call.at + 1, ...call.commas];
    const current = before.slice(starts[starts.length - 1], from);
    if (current.trim() !== "" || (!word && !context.explicit)) return null;
    const callee = new RegExp(`(${IDENT}(?:\\.${IDENT})*)$`).exec(before.slice(0, call.at))?.[1];
    if (!callee) return null;
    // The arguments before this one.
    const given = starts.slice(0, -1).map((start, i) => before.slice(start, starts[i + 1] - 1).trim());

    let args: [Export, Arg][] | null = null;
    if (callee === "e.set_" && given.length > 0) {
      // The element set rules give fields to, its first argument.
      const target = byName.get(given[0]);
      if (target) args = argsOf(target);
    } else {
      const target = byName.get(callee.replace(/\.with$/, ""));
      if (target) args = argsOf(target);
    }
    if (!args) return null;

    const named = new Set(given.map((g) => new RegExp(`^(${IDENT})\\s*:`).exec(g)?.[1]).filter(Boolean));
    return {
      from,
      options: args
        .filter(([, a]) => !named.has(a.name))
        .map(([owner, a]) => ({
          label: a.name,
          type: "property",
          detail: a.type ?? undefined,
          apply: `${a.name}: `,
          // `exam`'s own arguments before `config`'s options.
          section: owner === config && callee !== "config" && !callee.startsWith("e.") ? "config options" : undefined,
          info: () => describe(a.doc, [["Default", a.default]], pageOf(owner, a.name)),
        })),
      validFor: new RegExp(`^${IDENT}$`),
    };
  };
}
