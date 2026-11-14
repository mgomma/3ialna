import assert from "node:assert/strict";
import { test } from "node:test";
import { getInstallationLinks } from "../src/installation-guide.ts";

for (const language of ["ar", "en"]) {
  test(`WhatsApp shares the download and install guide in ${language}`, () => {
    const links = getInstallationLinks(language);
    const whatsapp = new URL(links.whatsappUrl);
    assert.equal(whatsapp.origin, "https://wa.me");
    const message = whatsapp.searchParams.get("text");
    for (const [link, section] of [[links.downloadUrl, "#download"], [links.guideUrl, "#setup"]]) {
      const url = new URL(link);
      assert.equal(url.origin, "https://mgomma.github.io");
      assert.equal(url.pathname, "/3ialna/");
      assert.equal(url.searchParams.get("lang"), language);
      assert.equal(url.hash, section);
      assert.ok(message.includes(link));
    }
    assert.match(message, language === "ar" ? /دليل التثبيت/ : /installation guide/);
  });
}
