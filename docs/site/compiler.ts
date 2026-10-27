// The Typst compiler of the live editor (live.ts) and the playground
// (playground.ts): typst.ts (https://github.com/Myriad-Dreamin/typst.ts),
// loaded once for the page, with the package's own source in place
// (live/files.json, written by site.typ). elembic is fetched from
// packages.typst.org, and the fonts from typst-assets on jsDelivr, by
// typst.ts itself. The compiler (about 11 MB, compressed) is downloaded only
// when something first needs it.
//
// typst.ts 0.8 is the first to bundle Typst 0.15, which examy needs.

/// <reference types="vite/client" />
import compilerWasm from "@myriaddreamin/typst-ts-web-compiler/pkg/typst_ts_web_compiler_bg.wasm?url";
import rendererWasm from "@myriaddreamin/typst-ts-renderer/pkg/typst_ts_renderer_bg.wasm?url";

export type Typst = typeof import("@myriaddreamin/typst.ts/contrib/snippet").$typst;

/**
 * A file of the site by its path from the site's root, where live.js is:
 * found from the page's script tag, so that a page in a folder, such as the
 * reference's, finds it too.
 */
export function siteFile(path: string): string {
  const base = document.querySelector<HTMLScriptElement>('script[src$="live.js"]')?.src ?? document.baseURI;
  return new URL(path, base).href;
}

/** The package's files (see site.typ). */
const FILES = siteFile("live/files.json");

/** The compiler, loaded once, with the package's files in place. */
let compiler: Promise<Typst> | null = null;
/** Whether the compiler has finished loading. */
let loaded = false;

export function isLoaded(): boolean {
  return loaded;
}

export function loadCompiler(): Promise<Typst> {
  if (compiler) return compiler;
  const loading = (async () => {
    const [files, { $typst }] = await Promise.all([
      fetch(FILES).then((r) => {
        if (!r.ok) throw new Error(`${FILES}: ${r.status}`);
        return r.json() as Promise<Record<string, string>>;
      }),
      import("@myriaddreamin/typst.ts/contrib/snippet"),
    ]);
    $typst.setCompilerInitOptions({ getModule: () => compilerWasm });
    $typst.setRendererInitOptions({ getModule: () => rendererWasm });
    for (const [path, text] of Object.entries(files)) {
      await $typst.addSource(path, text);
    }
    loaded = true;
    return $typst;
  })();
  compiler = loading;
  // A failed load can be retried.
  loading.catch(() => {
    if (compiler === loading) compiler = null;
  });
  return loading;
}

/**
 * One compilation at a time: `source` is written to `path` in the
 * compiler's files, then `job` compiles, with no other job between the two.
 */
let queue: Promise<unknown> = Promise.resolve();
export function withSource<T>(path: string, source: string, job: (typst: Typst) => Promise<T>): Promise<T> {
  const run = queue.then(async () => {
    const $typst = await loadCompiler();
    await $typst.addSource(path, source);
    return job($typst);
  });
  queue = run.catch(() => {});
  return run;
}

/** A compiler error as text. typst.ts reports diagnostics in several shapes. */
export function describe(error: unknown): string {
  if (Array.isArray(error)) return error.map(describe).join("\n");
  const text = error instanceof Object && "message" in error ? String(error.message) : String(error);
  // Diagnostics arrive as Rust's debug output of `SourceDiagnostic`s: keep
  // just their messages, with Rust's escapes undone (`\n` a line break, not
  // an "n"; `\u{2060}` the character it names).
  const unescape: Record<string, string> = { n: "\n", t: "\t", r: "\r", "0": "\0" };
  const messages = [...text.matchAll(/message: "((?:[^"\\]|\\.)*)"/g)].map((m) =>
    m[1]
      .replace(/\\u\{([0-9a-fA-F]{1,6})\}|\\(.)/g, (_, hex: string | undefined, c: string | undefined) =>
        hex !== undefined ? String.fromCodePoint(parseInt(hex, 16)) : (unescape[c!] ?? c!),
      )
      .replace(/^assertion failed: /, ""),
  );
  return messages.length ? messages.join("\n") : text;
}

export function element<K extends keyof HTMLElementTagNameMap>(
  tag: K,
  props: Partial<HTMLElementTagNameMap[K]> = {},
): HTMLElementTagNameMap[K] {
  return Object.assign(document.createElement(tag), props);
}
