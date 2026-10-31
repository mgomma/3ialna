export type AndroidAbi = "arm64" | "armv7" | "universal";

export type AndroidRelease = {
  version: string;
  build: string;
  minimumAndroidApi?: number;
  downloadUrls: { arm64: string; armv7: string; universal?: string };
};

type BrowserInfo = {
  userAgent: string;
  userAgentData?: {
    platform?: string;
    mobile?: boolean;
    getHighEntropyValues?: (hints: string[]) => Promise<{
      architecture?: string;
      bitness?: string;
      platformVersion?: string;
    }>;
  };
};

export type AndroidDownload = {
  isAndroid: boolean;
  abi: AndroidAbi;
  androidMajor: number | null;
  supported: boolean | null;
  url: string | null;
};

const androidApiByMajor: Record<number, number> = {
  5: 21, 6: 23, 7: 24, 8: 26, 9: 28, 10: 29, 11: 30,
  12: 31, 13: 33, 14: 34, 15: 35, 16: 36,
};

export async function selectAndroidDownload(
  browser: BrowserInfo,
  release: AndroidRelease,
  timeoutMs = 1500,
): Promise<AndroidDownload> {
  const hints = browser.userAgentData;
  const isAndroid = hints?.platform
    ? hints.platform.toLowerCase() === "android"
    : /\bAndroid\b/i.test(browser.userAgent);
  let abi: AndroidAbi = "universal";
  let androidMajor: number | null = null;

  if (isAndroid) {
    const version = /\bAndroid\s+(\d+)/i.exec(browser.userAgent);
    const chromeVersion = /\b(?:Chrome|Chromium)\/(\d+)/.exec(browser.userAgent);
    if (version && (!chromeVersion || Number(chromeVersion[1]) < 110)) {
      androidMajor = Number(version[1]);
    }

    if (hints?.getHighEntropyValues) {
      let timer: ReturnType<typeof setTimeout> | undefined;
      try {
        const values = await Promise.race([
          hints.getHighEntropyValues(["architecture", "bitness", "platformVersion"]),
          new Promise<never>((_, reject) => {
            timer = setTimeout(() => reject(new Error("Device hints timed out")), timeoutMs);
          }),
        ]);
        const architecture = values.architecture?.toLowerCase() ?? "";
        if (/^(arm|arm64|aarch64)$/.test(architecture)) {
          if (values.bitness === "64" || /64/.test(architecture)) abi = "arm64";
          else if (values.bitness === "32") abi = "armv7";
        }
        const platformVersion = /^(\d+)(?:\.|$)/.exec(values.platformVersion ?? "");
        if (platformVersion && Number(platformVersion[1]) > 0) {
          androidMajor = Number(platformVersion[1]);
        }
      } catch {
        abi = "universal";
      } finally {
        clearTimeout(timer);
      }
    }
  }

  const minimumApi = release.minimumAndroidApi ?? 24;
  const api = androidMajor === null ? null : androidApiByMajor[androidMajor];
  const supported = androidMajor === null ? null
    : api == null ? androidMajor > 16 : api >= minimumApi;
  const url = isAndroid && supported !== false ? release.downloadUrls[abi] ?? null : null;
  return { isAndroid, abi, androidMajor, supported, url };
}

let attemptedRelease: string | null = null;

export function beginAutomaticDownload(
  selection: AndroidDownload,
  release: AndroidRelease,
  storage: Pick<Storage, "getItem" | "setItem">,
  download: (url: string) => void,
): boolean {
  if (!selection.isAndroid || selection.supported === false || !selection.url) return false;
  const key = `3ialna-auto-download:${release.version}:${release.build}`;
  if (attemptedRelease === key) return false;
  try {
    if (storage.getItem(key)) return false;
    storage.setItem(key, "1");
  } catch {
    return false;
  }
  attemptedRelease = key;
  download(selection.url);
  return true;
}