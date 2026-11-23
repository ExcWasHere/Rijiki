/**
 * Test runner backend.
 *
 * Sumber TypeScript memakai import tanpa ekstensi (gaya bundler Cloudflare),
 * jadi tidak bisa dijalankan langsung oleh Node. Skrip ini membundel tiap
 * `test/*.test.ts` dengan esbuild lalu menjalankannya lewat `node --test`.
 *
 *   npm test
 */
import { spawnSync } from 'node:child_process';
import { readdirSync, rmSync } from 'node:fs';
import { build } from 'esbuild';

const OUT_DIR = 'test-build';

const entries = readdirSync('test')
  .filter((name) => name.endsWith('.test.ts'))
  .map((name) => `test/${name}`);

if (entries.length === 0) {
  console.error('Tidak ada berkas test/*.test.ts');
  process.exit(1);
}

rmSync(OUT_DIR, { recursive: true, force: true });

await build({
  entryPoints: entries,
  bundle: true,
  platform: 'node',
  format: 'esm',
  target: 'node22',
  // Dependensi besar tidak perlu dibundel; cukup diresolusi saat runtime.
  external: ['@supabase/supabase-js'],
  outdir: OUT_DIR,
  outExtension: { '.js': '.mjs' },
  logLevel: 'warning',
});

const bundles = readdirSync(OUT_DIR)
  .filter((name) => name.endsWith('.mjs'))
  .map((name) => `${OUT_DIR}/${name}`);

const result = spawnSync(process.execPath, ['--test', ...bundles], { stdio: 'inherit' });
process.exit(result.status ?? 1);
