// Check that every example on the documentation site, as a whole document
// (its "Full example"), compiles in a document of its own, as a reader would
// paste it: each is taken from the built site (_site/, or the directory
// given), written to a file of its own, and compiled against this checkout
// installed as @preview/examy, at the version in typst.toml.
//
//   npm run check:examples
import { execFileSync } from "node:child_process";
import { mkdirSync, mkdtempSync, readdirSync, readFileSync, rmSync, symlinkSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";

const site = resolve(process.argv[2] ?? join(import.meta.dirname, "../../_site"));
const repo = resolve(import.meta.dirname, "../..");
const version = readFileSync(join(repo, "typst.toml"), "utf8").match(/^version = "(.*)"/m)[1];

const decode = (s) =>
  s.replace(/&#x([0-9a-f]+);/gi, (_, h) => String.fromCodePoint(parseInt(h, 16)))
    .replace(/&#(\d+);/g, (_, d) => String.fromCodePoint(Number(d)))
    .replace(/&quot;/g, '"').replace(/&lt;/g, "<").replace(/&gt;/g, ">").replace(/&amp;/g, "&");

const work = mkdtempSync(join(tmpdir(), "examy-full-"));
const packages = join(work, "packages");
mkdirSync(join(packages, "preview", "examy"), { recursive: true });
symlinkSync(repo, join(packages, "preview", "examy", version));

let checked = 0;
const failures = [];
for (const page of readdirSync(site, { recursive: true }).filter((f) => f.endsWith(".html")).sort()) {
  const html = readFileSync(join(site, page), "utf8");
  // Each example's whole document: its own code, where that is one already.
  // (Attribute by attribute: their values may hold a `>`, as in `=>`.)
  for (const [, attrs] of html.matchAll(/<figure class="example[^"]*"((?:\s+[\w-]+="[^"]*")*)\s*>/g)) {
    const attr = (name) => attrs.match(new RegExp(`\\b${name}="([^"]*)"`))?.[1];
    const full = attr("data-full") ?? attr("data-source");
    if (full === undefined) continue;
    const file = join(work, `${page.replace(/\W/g, "-")}-${++checked}.typ`);
    writeFileSync(file, decode(full));
    try {
      execFileSync("typst", ["compile", "--root", work, file, file.replace(/\.typ$/, ".pdf")], {
        env: { ...process.env, TYPST_PACKAGE_PATH: packages },
        stdio: "pipe",
      });
    } catch (e) {
      failures.push(`${page}, example ${checked}:\n${String(e.stderr).trim()}\n--- the whole document ---\n${decode(full)}`);
    }
  }
}
rmSync(work, { recursive: true, force: true });
for (const f of failures) console.error(`\n${f}`);
console.log(`${checked} whole examples compiled on their own, ${failures.length} failed`);
process.exit(failures.length ? 1 : 0);
