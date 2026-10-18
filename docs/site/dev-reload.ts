/// <reference types="vite/client" />
// In development only (`npm run dev`; see vite.config.ts, which adds this to
// every page it serves): keeps a page up to date as Typst rebuilds the site,
// changing as little of it as it can.
//
// After each rebuild, the server sends the paths of the files whose contents
// changed. A changed stylesheet is swapped in place, without a reload. A
// change to anything else this page shows (its own HTML, an image, the live
// editor's files) reloads it, keeping the scroll position; changes to other
// pages leave it alone. The scroll position is also kept across the reloads
// Vite does itself, as when live.ts changes.

const SCROLL_KEY = `examy-dev-scroll:${location.pathname}`;

/** This page's file, by its path from the site's root, as the server names it. */
function pageFile(): string {
  const path = decodeURIComponent(location.pathname).replace(/^\//, "");
  return path === "" || path.endsWith("/") ? `${path}index.html` : path;
}

/** Load the stylesheets again, each replaced once the new one has loaded, so
 *  that the page is never shown without one. */
function refreshStylesheets(): void {
  for (const link of document.querySelectorAll<HTMLLinkElement>('link[rel="stylesheet"]')) {
    const fresh = link.cloneNode() as HTMLLinkElement;
    const url = new URL(link.href);
    url.searchParams.set("t", String(Date.now()));
    fresh.href = url.href;
    fresh.addEventListener("load", () => link.remove(), { once: true });
    link.after(fresh);
  }
}

function saveScroll(): void {
  try {
    sessionStorage.setItem(SCROLL_KEY, String(window.scrollY));
  } catch {
    // Without storage, the page reloads at its top.
  }
}

function restoreScroll(): void {
  let y: string | null = null;
  try {
    y = sessionStorage.getItem(SCROLL_KEY);
    sessionStorage.removeItem(SCROLL_KEY);
  } catch {
    return;
  }
  if (y === null) return;
  const top = Number(y);
  // Once the page has its full height (its images loaded).
  const scroll = () => window.scrollTo({ top, behavior: "instant" });
  if (document.readyState === "complete") requestAnimationFrame(scroll);
  else window.addEventListener("load", () => requestAnimationFrame(scroll), { once: true });
}

// The scroll position is restored here, not by the browser, which can restore
// it before the page has its full height.
history.scrollRestoration = "manual";
restoreScroll();

if (import.meta.hot) {
  import.meta.hot.on("examy:rebuilt", ({ changed }: { changed: string[] }) => {
    const page = pageFile();
    // Other pages, and the stylesheet (swapped in place), do not need a reload.
    const reload = changed.some((path) => path === page || !(path.endsWith(".html") || path.endsWith(".css")));
    if (reload) {
      saveScroll();
      location.reload();
    } else if (changed.some((path) => path.endsWith(".css"))) {
      refreshStylesheets();
    }
  });
  import.meta.hot.on("vite:beforeFullReload", saveScroll);
}
