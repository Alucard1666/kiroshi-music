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
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with Orchard. If not, see <https://www.gnu.org/licenses/>.
 */

export const ORCHARD_APP_USER_MODEL_ID = 'kiroshi-music';
export const KIROSHI_APP_USER_MODEL_ID = 'kiroshi-music';

function quotedWindowsArgument(value) {
  return `"${String(value).replaceAll('"', '\\"')}"`;
}

export function windowsRelaunchCommand({ appPath, executablePath }) {
  if (!appPath || !executablePath) return '';
  return `${quotedWindowsArgument(executablePath)} ${quotedWindowsArgument(appPath)}`;
}

export function setWindowsAppDetails(window, {
  appPath,
  appIconPath,
  executablePath = process.execPath,
  platform = process.platform,
  relaunchDisplayName = 'Kiroshi Music'
} = {}) {
  if (platform !== 'win32') return;

  const details = { appId: ORCHARD_APP_USER_MODEL_ID };
  const relaunchCommand = windowsRelaunchCommand({ appPath, executablePath });
  if (relaunchCommand) {
    details.appIconPath = appIconPath;
    details.appIconIndex = 0;
    details.relaunchCommand = relaunchCommand;
    details.relaunchDisplayName = relaunchDisplayName;
  }
  window.setAppDetails(details);
}
