/**
 * Sanitize frontend copies in lactechsys/@novo by:
 * 1) Removing all <script>...</script> blocks and external <script src> tags
 * 2) Removing inline event handler attributes (onclick, onload, onsubmit, etc.)
 * 3) Injecting a single per-page JS file located in ./assets/{page}.js
 * 4) Creating stub JS files if they don't exist
 *
 * Run: node lactechsys/@novo/tools/sanitize_frontend.js
 */

const fs = require('fs');
const path = require('path');

const baseDir = path.resolve(__dirname, '..');
const assetsDir = path.join(baseDir, 'assets');
if (!fs.existsSync(assetsDir)) fs.mkdirSync(assetsDir, { recursive: true });

const pages = [
  { html: 'index.html', js: 'index.js' },
  { html: 'inicio.html', js: 'inicio.js' },
  { html: 'login.html', js: 'login.js' },
  { html: 'PrimeiroAcesso.html', js: 'primeiroAcesso.js' },
  { html: 'gerente.html', js: 'gerente.js' },
  { html: 'funcionario.html', js: 'funcionario.js' },
  { html: 'veterinario.html', js: 'veterinario.js' },
  { html: 'proprietario.html', js: 'proprietario.js' },
  { html: 'acesso-bloqueado.html', js: 'acesso-bloqueado.js' },
];

// Regex helpers
const reScriptBlock = /<script\b[^>]*>[\s\S]*?<\/script>/gi;
const reEventDouble = /\s(on[a-zA-Z]+)\s*=\s*"[^"]*"/g; // on*="..."
const reEventSingle = /\s(on[a-zA-Z]+)\s*=\s*'[^']*'/g;   // on*='...'

for (const p of pages) {
  const htmlPath = path.join(baseDir, p.html);
  if (!fs.existsSync(htmlPath)) continue;

  let html = fs.readFileSync(htmlPath, 'utf8');

  // 1) Remove any script blocks or external scripts
  html = html.replace(reScriptBlock, '');

  // 2) Remove inline event handlers
  html = html.replace(reEventDouble, '');
  html = html.replace(reEventSingle, '');

  // 3) Inject per-page JS before </body> or </head>
  const injectTag = `    <script src="./assets/${p.js}"></script>`;
  if (/(<\/body>)/i.test(html)) {
    html = html.replace(/<\/body>/i, `${injectTag}\n</body>`);
  } else if (/(<\/head>)/i.test(html)) {
    html = html.replace(/<\/head>/i, `${injectTag}\n</head>`);
  } else {
    html += `\n${injectTag}\n`;
  }

  fs.writeFileSync(htmlPath, html, 'utf8');

  // 4) Create stub JS if missing
  const jsPath = path.join(assetsDir, p.js);
  if (!fs.existsSync(jsPath)) {
    const stub = `// ${p.js} (stub)\ndocument.addEventListener('DOMContentLoaded', ()=>{ console.log('${p.js} loaded'); });\n`;
    fs.writeFileSync(jsPath, stub, 'utf8');
  }
}

console.log('✅ Sanitization completed for @novo.');


