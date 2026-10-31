import assert from "node:assert/strict";
import { test } from "node:test";
import { beginAutomaticDownload, selectAndroidDownload } from "../src/android-download.ts";

const release = {
  version: "1.0.0", build: "1", minimumAndroidApi: 24,
  downloadUrls: { arm64: "https://example.test/arm64.apk", armv7: "https://example.test/armv7.apk", universal: "https://example.test/universal.apk" },
};
const browser = (values, userAgent = "Mozilla/5.0 (Linux; Android 10; K) Chrome/140.0.0.0 Mobile") => ({
  userAgent,
  userAgentData: { platform: "Android", mobile: true, getHighEntropyValues: async () => values },
});

test("Android 7-16 retain all features and choose confirmed ARM64", async () => {
  for (const major of [7, 8, 9, 10, 11, 12, 13, 14, 15, 16]) {
    const result = await selectAndroidDownload(browser({ architecture: "arm", bitness: "64", platformVersion: `${major}.0.0` }), release);
    assert.equal(result.androidMajor, major);
    assert.equal(result.supported, true);
    assert.equal(result.url, release.downloadUrls.arm64);
  }
});

test("confirmed 32-bit ARM receives the smaller ARMv7 APK", async () => {
  assert.equal((await selectAndroidDownload(browser({ architecture: "arm", bitness: "32" }), release)).url, release.downloadUrls.armv7);
});

test("explicit aarch64 is recognized without bitness", async () => {
  assert.equal((await selectAndroidDownload(browser({ architecture: "aarch64" }), release)).abi, "arm64");
});

test("blank, x86 and ambiguous hints use universal rather than guessing ARMv7", async () => {
  for (const values of [{}, { architecture: "x86", bitness: "64" }, { architecture: "arm" }]) {
    assert.equal((await selectAndroidDownload(browser(values), release)).url, release.downloadUrls.universal);
  }
});

test("Android browsers without client hints use universal", async () => {
  assert.equal((await selectAndroidDownload({ userAgent: "Mozilla/5.0 (Android 13) Firefox/120" }, release)).url, release.downloadUrls.universal);
});

test("reduced Chrome user agents do not report a fake Android 10 version", async () => {
  assert.equal((await selectAndroidDownload(browser({}), release)).androidMajor, null);
});

test("older unsupported Android receives no APK", async () => {
  for (const major of [5, 6]) {
    const result = await selectAndroidDownload(browser({ platformVersion: `${major}.0.0` }), release);
    assert.equal(result.supported, false);
    assert.equal(result.url, null);
  }
});

test("iPhone, iPad and desktop browsers never receive an Android download", async () => {
  for (const userAgent of ["Mozilla/5.0 (iPhone; CPU iPhone OS 18_0)", "Mozilla/5.0 (iPad; CPU OS 18_0)", "Mozilla/5.0 (Windows NT 10.0)", "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15)"]) {
    assert.equal((await selectAndroidDownload({ userAgent }, release)).url, null);
  }
  assert.equal((await selectAndroidDownload({ userAgent: "Android", userAgentData: { platform: "Windows" } }, release)).url, null);
});

test("rejected and never-resolving hints fall back within the deadline", async () => {
  for (const getHighEntropyValues of [() => Promise.reject(new Error("Denied")), () => new Promise(() => {})]) {
    const result = await selectAndroidDownload({ userAgent: "Android", userAgentData: { platform: "Android", getHighEntropyValues } }, release, 5);
    assert.equal(result.url, release.downloadUrls.universal);
  }
});

test("missing published universal asset never creates a nonexistent URL", async () => {
  const result = await selectAndroidDownload(browser({}), { ...release, downloadUrls: { arm64: "arm64.apk", armv7: "armv7.apk" } });
  assert.equal(result.url, null);
});

test("automatic download runs once per release and session", async () => {
  const selection = await selectAndroidDownload(browser({ architecture: "arm", bitness: "64" }), release);
  const entries = new Map();
  const storage = { getItem: (key) => entries.get(key), setItem: (key, value) => entries.set(key, value) };
  const downloads = [];
  assert.equal(beginAutomaticDownload(selection, release, storage, (url) => downloads.push(url)), true);
  assert.equal(beginAutomaticDownload(selection, release, storage, (url) => downloads.push(url)), false);
  assert.deepEqual(downloads, [release.downloadUrls.arm64]);
  const next = { ...release, build: "2" };
  assert.equal(beginAutomaticDownload(selection, next, storage, (url) => downloads.push(url)), true);
});

test("unavailable storage and incompatible platforms never auto-download", async () => {
  const storage = { getItem() { throw new Error("Blocked"); }, setItem() {} };
  const download = () => assert.fail("Must not download");
  const selection = await selectAndroidDownload(browser({}), release);
  assert.equal(beginAutomaticDownload(selection, { ...release, build: "3" }, storage, download), false);
  const desktop = await selectAndroidDownload({ userAgent: "Windows" }, release);
  assert.equal(beginAutomaticDownload(desktop, release, storage, download), false);
});