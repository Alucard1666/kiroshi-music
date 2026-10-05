/*
 * Copyright (C) 2026 SFG545
 *
 * This file is part of Orchard.
 *
 * Orchard is free software: you can redistribute it and/or modify it under the
 * terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, either version 3 of the License, or (at your option) any
 * later version.
 *
 * Orchard is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
 * PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with Orchard. If not, see <https://www.gnu.org/licenses/>.
 */

// Resolves the per-platform binary produced by scripts/build-native-audio*.sh.
// napi-rs resolves every napi_* symbol from the host executable at runtime, so
// the same analysis/transition binary loads under Node and Electron alike.
const path = require('node:path');
const fs = require('node:fs');

const BINARY_DIRECTORY = path.join(__dirname, 'build');

function resolveBinary() {
  const architecture = process.arch === 'arm64' ? 'arm64' : 'x64';
  const names = [
    `orchard-audio-${process.platform}-${architecture}.node`,
    `orchard-audio-transition-${process.platform}-${architecture}.node`,
    `kiroshi-music-audio-${process.platform}-${architecture}.node`
  ];
  const searchDirs = [BINARY_DIRECTORY, __dirname];

  for (const dir of searchDirs) {
    for (const name of names) {
      const full = path.join(dir, name);
      if (fs.existsSync(full)) return full;
    }
  }

  return path.join(BINARY_DIRECTORY, names[0]);
}

module.exports = require(resolveBinary());
