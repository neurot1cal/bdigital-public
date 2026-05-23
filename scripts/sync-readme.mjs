#!/usr/bin/env node
/**
 * sync-readme.mjs
 *
 * Regenerate the marketplace-derived regions of the root README.md from the
 * single source of truth: .claude-plugin/marketplace.json.
 *
 * The README drifted three times in one week because the plugin list, install
 * commands, directory tree, and per-plugin doc links were all hand-maintained
 * in parallel with marketplace.json. Every plugin-adding PR re-conflicted on
 * the same regions. This script makes those regions generated artifacts.
 *
 * Generated regions are delimited by HTML-comment markers that render
 * invisibly:
 *
 *   <!-- AUTOGEN:plugins-table -->  ... <!-- /AUTOGEN:plugins-table -->
 *   <!-- AUTOGEN:install-block -->  ... <!-- /AUTOGEN:install-block -->
 *   <!-- AUTOGEN:tree -->           ... <!-- /AUTOGEN:tree -->
 *   <!-- AUTOGEN:plugin-docs -->    ... <!-- /AUTOGEN:plugin-docs -->
 *
 * Everything outside the markers (intro prose, the hand-written "Current
 * plugins" descriptions, samples, trust model) is left untouched.
 *
 * Usage:
 *   node scripts/sync-readme.mjs            # write mode: rewrite the regions
 *   node scripts/sync-readme.mjs --check    # CI mode: exit 1 on drift
 *   node scripts/sync-readme.mjs --verbose  # log integrity warnings
 *
 * Integrity warnings (non-fatal, surfaced on stderr in --check):
 *   - a marketplace plugin whose directory lacks .claude-plugin/plugin.json
 *   - a marketplace plugin whose directory lacks a LICENSE
 *   - a marketplace plugin with no "### `plugins/<name>/`" prose section
 * These do not fail the check (they are editorial / pre-existing), but they
 * flag plugins that are published but incomplete.
 */

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const REPO = path.resolve(__dirname, '..');
const args = process.argv.slice(2);
const CHECK = args.includes('--check');
const VERBOSE = args.includes('--verbose');
const OWNER_REPO = 'neurot1cal/bdigital-public';

function warn(...a) { console.error('   warning:', ...a); }

// ---------- load marketplace.json ----------
const manifestPath = path.join(REPO, '.claude-plugin', 'marketplace.json');
if (!fs.existsSync(manifestPath)) {
  console.error('FATAL: .claude-plugin/marketplace.json missing');
  process.exit(2);
}
const marketplace = JSON.parse(fs.readFileSync(manifestPath, 'utf8'));
if (!Array.isArray(marketplace.plugins)) {
  console.error('FATAL: marketplace.json has no plugins array');
  process.exit(2);
}

const plugins = marketplace.plugins.map((p) => {
  const dir = p.source.replace(/^\.\//, '').replace(/\/$/, ''); // ./plugins/x -> plugins/x
  return { name: p.name, category: p.category || 'uncategorized', dir };
});

// ---------- integrity warnings (non-fatal) ----------
const readmePath = path.join(REPO, 'README.md');
const currentReadme = fs.existsSync(readmePath) ? fs.readFileSync(readmePath, 'utf8') : '';
for (const p of plugins) {
  const pjson = path.join(REPO, p.dir, '.claude-plugin', 'plugin.json');
  if (!fs.existsSync(pjson)) warn(`${p.name}: missing ${p.dir}/.claude-plugin/plugin.json (in marketplace but not installable)`);
  if (!fs.existsSync(path.join(REPO, p.dir, 'LICENSE'))) warn(`${p.name}: missing ${p.dir}/LICENSE`);
  if (!currentReadme.includes(`### \`${p.dir}/\``)) warn(`${p.name}: no "### \`${p.dir}/\`" section in README "Current plugins"`);
}

// ---------- count skill mirrors for the tree summary ----------
const skillsRoot = path.join(REPO, 'skills');
const skillCount = fs.existsSync(skillsRoot)
  ? fs.readdirSync(skillsRoot, { withFileTypes: true }).filter((e) => e.isDirectory()).length
  : 0;

// ---------- region bodies ----------
function pad(s, n) { return s + ' '.repeat(Math.max(0, n - s.length)); }

function pluginsTable() {
  const head = '| Plugin | Category | Install | Docs |\n|--------|----------|---------|------|';
  const rows = plugins.map((p) =>
    `| \`${p.name}\` | ${p.category} | \`/plugin install ${p.name}@bdigital-public\` | [README](${p.dir}/README.md) |`
  );
  return [head, ...rows].join('\n');
}

function installBlock() {
  const lines = [
    '```',
    `/plugin marketplace add ${OWNER_REPO}`,
    ...plugins.map((p) => `/plugin install ${p.name}@bdigital-public`),
    '```',
  ];
  return lines.join('\n');
}

function tree() {
  // The plugins/ subtree is generated; the rest of the skeleton is static.
  const pluginLines = plugins.map((p, i) => {
    const branch = i === plugins.length - 1 ? '└──' : '├──';
    return `│   ${branch} ${pad(p.name + '/', 24)}# ${p.category}`;
  });
  const lines = [
    '```',
    'bdigital-public/',
    '├── .claude-plugin/',
    '│   └── marketplace.json        # Makes this repo a Claude Code plugin marketplace',
    '├── plugins/                    # Canonical: full plugin bundles (Claude Code marketplace)',
    ...pluginLines,
    '├── skills/                     # Auto-generated mirrors for `npx openskills install`',
    `│   └── (${skillCount} skill mirrors, one per skill, byte-identical to plugins/<plugin>/skills/<skill>/)`,
    '├── samples/                    # Hand-maintained read-the-source views (tests + evals + blog mirroring)',
    '│   ├── pr-review/              # Claude-skills-based automated PR review + eval runner',
    '│   ├── session-handoff/        # Same skill + tests + scenario fixtures',
    '│   └── cc-context-monitor/     # Same plugin + tests + evals',
    '├── scripts/                    # sync-skills.mjs (skills/) + sync-readme.mjs (this README)',
    '├── site/                       # Astro landing page (Cloudflare Workers)',
    '└── .github/                    # Open-source workflows, templates, ownership',
    '```',
  ];
  return lines.join('\n');
}

function pluginDocs() {
  return plugins.map((p) => `- [\`${p.dir}/README.md\`](${p.dir}/README.md)`).join('\n');
}

const REGIONS = {
  'plugins-table': pluginsTable(),
  'install-block': installBlock(),
  'tree': tree(),
  'plugin-docs': pluginDocs(),
};

// ---------- apply regions ----------
function replaceRegion(text, name, body) {
  const open = `<!-- AUTOGEN:${name} -->`;
  const close = `<!-- /AUTOGEN:${name} -->`;
  const re = new RegExp(`${open}[\\s\\S]*?${close}`);
  if (!re.test(text)) {
    console.error(`FATAL: marker pair for "${name}" not found in README.md`);
    console.error(`Add this block where the generated content should live:`);
    console.error(`  ${open}\n  ${close}`);
    process.exit(2);
  }
  return text.replace(re, `${open}\n${body}\n${close}`);
}

let next = currentReadme;
for (const [name, body] of Object.entries(REGIONS)) {
  next = replaceRegion(next, name, body);
}

// ---------- write or check ----------
if (CHECK) {
  if (next === currentReadme) {
    console.log(`✓ README.md in sync — ${plugins.length} plugins, 4 generated regions match marketplace.json`);
    process.exit(0);
  }
  console.error('✗ README.md out of sync with .claude-plugin/marketplace.json');
  console.error('Fix: run  node scripts/sync-readme.mjs');
  process.exit(1);
}

if (next === currentReadme) {
  console.log(`✓ README.md already in sync — ${plugins.length} plugins`);
} else {
  fs.writeFileSync(readmePath, next);
  console.log(`✓ regenerated README.md regions from marketplace.json (${plugins.length} plugins):`);
  for (const name of Object.keys(REGIONS)) console.log(`  - AUTOGEN:${name}`);
}
