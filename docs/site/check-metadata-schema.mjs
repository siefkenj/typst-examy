// Check that the data examy exports, `<examy-rubric>` and `<examy-regions>`
// (attached to the PDF as examy-rubric.json and examy-regions.json), is what
// the manual says it is: the types in examy-rubric.ts and examy-regions.ts,
// which the manual shows. The data of a sample exam with every field, each
// as `null` and not (tests/schema/metadata.typ), is written into a
// TypeScript file of its own, each exam's as `{..} satisfies ExamyRubric`,
// and checked with `tsc`: a field that examy adds, drops, or renames, or
// whose value is of another type, fails it.
//
//   npm run check:schema
import { execFileSync } from "node:child_process";
import { mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";

const repo = resolve(import.meta.dirname, "../..");
const sample = join(repo, "tests/schema/metadata.typ");
// Each label examy leaves its data at, and the type of that data, in the
// file of the same name.
const TYPES = { "examy-rubric": "ExamyRubric", "examy-regions": "ExamyRegions" };

const query = (label) =>
  JSON.parse(
    execFileSync("typst", ["eval", "--root", repo, "--in", sample, `query(<${label}>).map(m => m.value)`], {
      encoding: "utf8",
    }),
  );

let source = "";
for (const [label, type] of Object.entries(TYPES)) {
  const exams = query(label);
  if (exams.length === 0) {
    console.error(`check:schema: ${sample} leaves no <${label}>`);
    process.exit(1);
  }
  source += `import type { ${type} } from ${JSON.stringify(join(import.meta.dirname, label))};\n`;
  source += `export const ${type.toLowerCase()} = [\n`;
  for (const data of exams) source += `${JSON.stringify(data, null, 2)} satisfies ${type},\n`;
  source += "];\n";
}

const work = mkdtempSync(join(tmpdir(), "examy-schema-"));
try {
  const file = join(work, "check.ts");
  writeFileSync(file, source);
  const tsc = join(repo, "node_modules/.bin/tsc");
  const options = ["--noEmit", "--strict", "--target", "es2022", "--module", "esnext", "--moduleResolution", "bundler"];
  try {
    execFileSync(tsc, [...options, "--skipLibCheck", file], { encoding: "utf8" });
  } catch (e) {
    console.error(`check:schema: the data of ${sample} is not what docs/site/examy-*.ts say it is:\n`);
    console.error(e.stdout || e.message);
    process.exit(1);
  }
  const counts = Object.keys(TYPES).map((label) => `${source.split(`satisfies ${TYPES[label]}`).length - 1} ${label}`);
  console.log(`check:schema: ${counts.join(", ")} match docs/site/examy-*.ts`);
} finally {
  rmSync(work, { recursive: true, force: true });
}
