// Vite builds the documentation site's script, the live editor
// (docs/site/live.ts), and serves the site in development. The site's pages
// themselves are built by Typst (docs/site.typ):
//
//   npm run build   build.sh writes the pages into _site/, then
//                   `vite build` adds live.js and its assets (the Typst
//                   compiler, as WebAssembly) beside them.
//   npm run dev     `typst watch` rebuilds the pages (and the PDF of them,
//                   docs/manual.typ) into .site-dev/ whenever the package or
//                   the docs change, and this server serves them, with
//                   live.ts compiled on the fly. After each rebuild, it tells
//                   the open pages which files changed, and each updates
//                   itself as little as it can (see dev-reload.ts).

import { spawn, type ChildProcess } from "node:child_process";
import { createHash } from "node:crypto";
import { existsSync, mkdirSync, readdirSync, readFileSync, statSync, watch } from "node:fs";
import { extname, join, relative, resolve } from "node:path";
import { defineConfig, type Plugin, type ViteDevServer } from "vite";

/** The repository's root, two levels up: Vite serves and builds from there. */
const ROOT = resolve(import.meta.dirname, "../..");

/** Where `npm run dev` has Typst write the pages, from the root; another
 *  folder for a second server alongside the first. */
const DEV_OUT = process.env.EXAMY_DEV_OUT ?? ".site-dev";

/** The PDF of the pages, beside them (see MANUAL_PDF in template.typ). */
const MANUAL_PDF = "examy-manual.pdf";

/** The package's files, which the live editor compiles (see docs/site.typ). */
function packageFiles(): string {
  const walk = (dir: string): string[] =>
    readdirSync(dir, { withFileTypes: true }).flatMap((d) =>
      d.isDirectory() ? walk(join(dir, d.name)) : d.name.endsWith(".typ") ? [join(dir, d.name)] : [],
    );
  return walk(join(ROOT, "src"))
    .map((f) => relative(ROOT, f))
    .sort()
    .join(",");
}

const TYPES: Record<string, string> = {
  ".html": "text/html; charset=utf-8",
  ".css": "text/css; charset=utf-8",
  ".json": "application/json",
  ".svg": "image/svg+xml",
  ".png": "image/png",
  ".pdf": "application/pdf",
};

/** A hash of each file Typst has written into `dir`, by its path there (with
 *  `/` between folders), less the PDF, which no page shows. */
function hashFiles(dir: string): Map<string, string> {
  const hashes = new Map<string, string>();
  const walk = (sub: string) => {
    for (const d of readdirSync(join(dir, sub), { withFileTypes: true })) {
      const path = sub ? `${sub}/${d.name}` : d.name;
      if (d.isDirectory()) walk(path);
      else if (path !== MANUAL_PDF) {
        hashes.set(path, createHash("sha1").update(readFileSync(join(dir, path))).digest("hex"));
      }
    }
  };
  walk("");
  return hashes;
}

/** The pages, built and rebuilt by `typst watch`, served with live reload. */
function typstSite(): Plugin {
  const watchers: ChildProcess[] = [];
  return {
    name: "examy-typst-site",
    apply: "serve",
    configureServer(server: ViteDevServer) {
      const root = server.config.root;
      const out = resolve(root, DEV_OUT);
      const typstWatch = (args: string[]) => {
        const typst = spawn("typst", ["watch", "--root", ".", "--no-serve", ...args], {
          cwd: root,
          stdio: ["ignore", "inherit", "inherit"],
        });
        typst.on("exit", (code) => {
          if (code !== null && code !== 0) server.config.logger.error(`typst watch exited with ${code}`);
        });
        watchers.push(typst);
      };
      mkdirSync(out, { recursive: true });
      typstWatch([
        "--features", "bundle,html",
        "--format", "bundle",
        "--input", `live-files=${packageFiles()}`,
        "docs/site.typ",
        DEV_OUT,
      ]);
      typstWatch(["docs/manual.typ", join(DEV_OUT, MANUAL_PDF)]);
      // Stop them with the server, however the server stops.
      const stop = () => watchers.forEach((typst) => typst.kill());
      server.httpServer?.on("close", stop);
      process.once("exit", stop);
      for (const signal of ["SIGINT", "SIGTERM", "SIGHUP"] as const) {
        process.once(signal, () => {
          stop();
          process.exit(130);
        });
      }

      // Once Typst has written a rebuild of the pages (not of the PDF), tell
      // the open pages which files it changed: Typst rewrites every page, so
      // the files are compared by their contents. (Vite's own watcher leaves
      // them alone; see `server.watch` below.)
      let hashes = new Map<string, string>();
      let timer: ReturnType<typeof setTimeout> | undefined;
      const rebuilt = () => {
        const now = hashFiles(out);
        const changed = [...now].filter(([path, hash]) => hashes.get(path) !== hash).map(([path]) => path);
        hashes = now;
        if (changed.length > 0) server.ws.send({ type: "custom", event: "examy:rebuilt", data: { changed } });
      };
      const watcher = watch(out, { recursive: true }, (_event, file) => {
        if (file === MANUAL_PDF) return;
        clearTimeout(timer);
        timer = setTimeout(rebuilt, 200);
      });
      server.httpServer?.on("close", () => watcher.close());

      server.middlewares.use((req, res, next) => {
        const path = decodeURIComponent((req.url ?? "/").split("?")[0]);
        // The pages load live.js, which in development is live.ts itself.
        if (path === "/live.js") {
          res.setHeader("content-type", "text/javascript");
          res.end('import "/docs/site/live.ts";\n');
          return;
        }
        const file = join(out, path.endsWith("/") ? path + "index.html" : path);
        if (!file.startsWith(out) || !existsSync(file) || !statSync(file).isFile()) return next();
        const type = TYPES[extname(file)] ?? "application/octet-stream";
        res.setHeader("content-type", type);
        res.setHeader("cache-control", "no-store");
        let body: string | Buffer = readFileSync(file);
        if (type.startsWith("text/html")) {
          // What updates the page after a rebuild (with Vite's client).
          body = body
            .toString()
            .replace("</head>", '<script type="module" src="/docs/site/dev-reload.ts"></script></head>');
        }
        res.end(body);
      });
    },
  };
}

export default defineConfig({
  root: ROOT,
  base: "./",
  publicDir: false,
  plugins: [typstSite()],
  server: {
    // On every interface, so the site can be opened from outside the dev
    // container.
    host: "0.0.0.0",
    port: 5173,
    // The port the dev container forwards: fail rather than move to another.
    strictPort: true,
    // The built pages are updated by `typstSite`, once per rebuild.
    watch: { ignored: [`**/${DEV_OUT}/**`, "**/_site/**"] },
  },
  preview: { host: "0.0.0.0", port: 4173 },
  build: {
    outDir: resolve(ROOT, "_site"),
    // The pages are there already, from build.sh.
    emptyOutDir: false,
    target: "es2022",
    rollupOptions: {
      input: resolve(ROOT, "docs/site/live.ts"),
      output: {
        entryFileNames: "live.js",
        chunkFileNames: "assets/[name]-[hash].js",
        assetFileNames: "assets/[name]-[hash][extname]",
      },
    },
  },
});
