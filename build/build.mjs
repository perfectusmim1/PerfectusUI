#!/usr/bin/env node
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, "..");
const SRC_DIR = path.join(ROOT, "src");
const DIST_DIR = path.join(ROOT, "dist");
const EXAMPLE_SRC = path.join(ROOT, "examples", "Example.lua");

function walkLuaFiles(dir, base = dir) {
    const entries = fs.readdirSync(dir, { withFileTypes: true });
    const files = [];
    for (const entry of entries) {
        const full = path.join(dir, entry.name);
        if (entry.isDirectory()) {
            files.push(...walkLuaFiles(full, base));
        } else if (entry.isFile() && entry.name.endsWith(".lua")) {
            const rel = path.relative(base, full).replace(/\\/g, "/").replace(/\.lua$/, "");
            files.push({ id: rel, path: full });
        }
    }
    return files;
}

function extractRequires(source) {
    const cleaned = source
        .replace(/--\[(=*)\[[\s\S]*?\]\1\]/g, "")
        .replace(/--[^\n]*/g, "");
    const deps = new Set();
    const regex = /\brequire\s*\(\s*["']([^"']+)["']\s*\)/g;
    let match;
    while ((match = regex.exec(cleaned)) !== null) {
        deps.add(match[1]);
    }
    return [...deps];
}

function main() {
    if (!fs.existsSync(SRC_DIR)) {
        console.error("[build] src/ directory not found");
        process.exit(1);
    }

    const files = walkLuaFiles(SRC_DIR);
    const moduleMap = new Map();
    for (const file of files) {
        const code = fs.readFileSync(file.path, "utf8").replace(/\r\n/g, "\n");
        const deps = extractRequires(code);
        moduleMap.set(file.id, { ...file, code, deps });
    }

    if (!moduleMap.has("init")) {
        console.error("[build] Missing entry module src/init.lua");
        process.exit(1);
    }

    // Check missing modules
    let hasError = false;
    for (const [id, mod] of moduleMap.entries()) {
        for (const dep of mod.deps) {
            if (!moduleMap.has(dep)) {
                console.error(`[build] Module "${id}" requires missing module "${dep}"`);
                hasError = true;
            }
        }
    }
    if (hasError) {
        process.exit(1);
    }

    // Topological sort & cycle check
    const visited = new Map(); // 0 = visiting, 1 = visited
    const ordered = [];

    function visit(id, stack = []) {
        const state = visited.get(id);
        if (state === 1) return;
        if (state === 0) {
            const cycle = [...stack, id].join(" -> ");
            console.error(`[build] Circular dependency detected: ${cycle}`);
            process.exit(1);
        }
        visited.set(id, 0);
        const mod = moduleMap.get(id);
        for (const dep of mod.deps) {
            visit(dep, [...stack, id]);
        }
        visited.set(id, 1);
        ordered.push(mod);
    }

    // Visit reachable from init first, then any remaining modules deterministically
    visit("init");
    const sortedIds = [...moduleMap.keys()].sort();
    for (const id of sortedIds) {
        if (!visited.has(id)) {
            visit(id);
        }
    }

    const timestamp = new Date().toISOString().split("T")[0];
    const header = [
        `--!nocheck`,
        `-- ============================================================================`,
        `-- Perfectus UI v1.0.0 — Premium macOS & iOS Interface Suite for Roblox (Luau)`,
        `-- Built: ${timestamp} | Modules: ${ordered.length} | Author: Perfectus`,
        `-- ============================================================================`,
        ``,
        `local __modules = {}`,
        `local __cache = {}`,
        `local __loading = {}`,
        ``,
        `local function __require(name)`,
        `    local cached = __cache[name]`,
        `    if cached ~= nil then`,
        `        return cached`,
        `    end`,
        `    if __loading[name] then`,
        `        error("[PerfectusUI] Circular require at runtime: " .. tostring(name), 2)`,
        `    end`,
        `    local loader = __modules[name]`,
        `    if not loader then`,
        `        error("[PerfectusUI] Missing module: " .. tostring(name), 2)`,
        `    end`,
        `    __loading[name] = true`,
        `    local ok, result = xpcall(loader, function(err)`,
        `        return debug.traceback("[PerfectusUI:" .. tostring(name) .. "] " .. tostring(err), 2)`,
        `    end, __require)`,
        `    __loading[name] = nil`,
        `    if not ok then`,
        `        error(result, 0)`,
        `    end`,
        `    __cache[name] = if result == nil then true else result`,
        `    return result`,
        `end`,
        ``,
    ];

    const bodyParts = [...header];
    for (const mod of ordered) {
        bodyParts.push(`-- [[ Module: ${mod.id} ]]`);
        bodyParts.push(`__modules["${mod.id}"] = function(require)`);
        bodyParts.push(mod.code.trimEnd());
        bodyParts.push(`end\n`);
    }

    const libSource = [...bodyParts, `return __require("init")\n`].join("\n");

    fs.mkdirSync(DIST_DIR, { recursive: true });
    const distLibPath = path.join(DIST_DIR, "PerfectusUI.lua");
    fs.writeFileSync(distLibPath, libSource, "utf8");
    console.log(`[build] Wrote ${path.relative(ROOT, distLibPath)} (${ordered.length} modules, ${libSource.length} bytes)`);

    if (fs.existsSync(EXAMPLE_SRC)) {
        const exampleCode = fs.readFileSync(EXAMPLE_SRC, "utf8").replace(/\r\n/g, "\n");
        // Replace the library loading stub with the inline bundled library
        const inlineExample = [
            `--!nocheck`,
            `-- ============================================================================`,
            `-- Perfectus UI — Standalone Showcase & Example Hub (Bundled Single-File)`,
            `-- Execute this script directly in Roblox to launch the full showcase UI.`,
            `-- ============================================================================`,
            ``,
            `local PerfectusUI = (function()`,
            ...bodyParts.slice(4), // skip duplicate top comment
            `    return __require("init")`,
            `end)()`,
            ``,
            exampleCode.replace(/local\s+PerfectusUI\s*=\s*[^\n]+/, "-- PerfectusUI inline above"),
        ].join("\n");
        const distExamplePath = path.join(DIST_DIR, "Example.lua");
        fs.writeFileSync(distExamplePath, inlineExample, "utf8");
        console.log(`[build] Wrote ${path.relative(ROOT, distExamplePath)} (${inlineExample.length} bytes)`);
    }
}

main();
