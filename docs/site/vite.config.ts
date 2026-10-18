// Vite builds the documentation site's script, the live editor
// (docs/site/live.ts), and serves the site in development. The site's pages
// themselves are built by Typst (docs/site.typ):
//
//   npm run build   build.sh writes the pages into _site/, then
//                   `vite build` adds live.js and its assets (the Typst
//                   compiler, as WebAssembly) beside them.
//   npm run dev     `typst watch` rebuilds the pages (and the PDF of them,
//                   docs/manual.typ) into .site-dev/ whenever the package or
//                   the docs change, and this server serves them, reloading
//                   the browser after each rebuild of the pages, with
//                   live.ts compiled on the fly.

import { spawn, type ChildProcess } from "node:child_process";
import { existsSync, mkdirSync, readdirSync, readFileSync, statSync, watch } from "node:fs";
import { extname, join, relative, resolve } from "node:path";
import { defineConfig, type Plugin, type ViteDevServer } from "vite";

/** The repository's root, two levels up: Vite serves and builds from there. */
const ROOT = resolve(import.meta.dirname, "../..");

/** Where `npm run dev` has Typst write the pages, from the root. */
const DEV_OUT = ".site-dev";

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

      // Reload the browser once Typst has written a rebuild of the pages, not
      // of the PDF. (Vite's own watcher leaves them alone; see `server.watch`
      // below.)
      let timer: ReturnType<typeof setTimeout> | undefined;
      const watcher = watch(out, { recursive: true }, (_event, file) => {
        if (file === MANUAL_PDF) return;
        clearTimeout(timer);
        timer = setTimeout(() => server.ws.send({ type: "full-reload" }), 200);
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
          // Vite's client, for the reload after a rebuild.
          body = body.toString().replace("</head>", '<script type="module" src="/@vite/client"></script></head>');
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
    // The built pages are reloaded by `typstSite`, once per rebuild.
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
