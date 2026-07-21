import assert from "node:assert/strict";
import {chromium, firefox, webkit} from "playwright";

const baseURL = process.env.BASE_URL || "http://127.0.0.1:4140";
const engines = {chromium, firefox, webkit};

async function ready(page) {
  await page.goto(baseURL);
  await page.locator(".phx-connected").waitFor();
}

async function focusId(page, id) {
  await page.waitForFunction(expected => document.activeElement?.id === expected, id);
}

async function open(page, key = "ArrowDown") {
  await page.locator("#fixture-menu-trigger").focus();
  await page.keyboard.press(key);
  await page.locator("#fixture-menu-popup").waitFor({state: "visible"});
}

async function run(browserType, name, iteration) {
  const browser = await browserType.launch();
  const context = await browser.newContext();
  const page = await context.newPage();
  try {
    await ready(page);
    const trigger = page.locator("#fixture-menu-trigger");
    assert.equal(await trigger.getAttribute("aria-haspopup"), "menu");
    assert.equal(await trigger.getAttribute("aria-controls"), "fixture-menu-popup");
    assert.equal(await page.locator("#fixture-menu-popup").getAttribute("aria-labelledby"), "fixture-menu-trigger");

    await trigger.click();
    await focusId(page, "fixture-menu-item-alpha");
    await page.keyboard.press("Escape");

    await open(page);
    await page.locator("#fixture-menu-trigger[aria-expanded='true']").waitFor();
    await focusId(page, "fixture-menu-item-alpha");
    await page.keyboard.press("ArrowUp");
    await focusId(page, "fixture-menu-item-empty");
    await page.keyboard.press("ArrowDown");
    await focusId(page, "fixture-menu-item-alpha");
    await page.keyboard.press("End");
    await focusId(page, "fixture-menu-item-empty");
    await page.keyboard.press("Home");
    await focusId(page, "fixture-menu-item-alpha");

    await page.keyboard.press("ArrowDown");
    await focusId(page, "fixture-menu-item-disabled");
    await page.keyboard.press("Enter");
    assert.equal(await page.locator("#actions").textContent(), "");
    assert.equal(await page.locator("#fixture-menu-popup").isVisible(), true);

    await page.keyboard.press("b");
    await page.keyboard.press("r");
    await focusId(page, "fixture-menu-item-bravo");
    await page.keyboard.press("Control+x");
    await focusId(page, "fixture-menu-item-bravo");
    await page.keyboard.press("z");
    await focusId(page, "fixture-menu-item-bravo");

    const popupHandle = await page.locator("#fixture-menu-popup").elementHandle();
    const bravoHandle = await page.locator("#fixture-menu-item-bravo").elementHandle();
    // This is the one intentional timing assertion: the documented 500 ms typeahead reset.
    await page.waitForTimeout(550);
    await page.keyboard.press("p");
    await focusId(page, "fixture-menu-item-patch");
    await page.keyboard.press("Enter");
    await page.locator("#fixture-menu[data-revision='1']").waitFor();
    assert.equal(await page.evaluate(([a, b]) => a === b, [popupHandle, await page.locator("#fixture-menu-popup").elementHandle()]), true);
    assert.equal(await page.locator("#fixture-menu-popup").isVisible(), true);
    await focusId(page, "fixture-menu-item-patch");

    await page.keyboard.press("ArrowDown");
    await focusId(page, "fixture-menu-item-reorder");
    await page.keyboard.press("Enter");
    await page.locator("#mode").filter({hasText: "reorder"}).waitFor();
    assert.equal(await page.evaluate(([a, b]) => a === b, [bravoHandle, await page.locator("#fixture-menu-item-bravo").elementHandle()]), true);
    await focusId(page, "fixture-menu-item-reorder");
    assert.match(await page.locator("#fixture-menu-item-bravo").textContent(), /updated/);

    await page.locator("#fixture-menu-item-remove").focus();
    await focusId(page, "fixture-menu-item-remove");
    await page.keyboard.press("Enter");
    await page.locator("#mode").filter({hasText: "remove"}).waitFor();
    await focusId(page, "fixture-menu-item-remove");
    // Active removal fallback: reset, focus Bravo, invoke the in-menu removal action from script.
    await page.locator("#reset").click();
    await page.locator("#mode").filter({hasText: "reset"}).waitFor();
    await open(page);
    await page.locator("#fixture-menu-item-bravo").focus();
    await page.locator("#fixture-menu-item-remove").evaluate(el => el.click());
    await page.locator("#mode").filter({hasText: "remove"}).waitFor();
    await focusId(page, "fixture-menu-item-alpha");

    await page.locator("#fixture-menu-item-empty").evaluate(el => el.click());
    await page.locator("#mode").filter({hasText: "empty"}).waitFor();
    await focusId(page, "fixture-menu-trigger");
    assert.equal(await page.locator("#fixture-menu-popup").isVisible(), false);

    await page.locator("#reset").click();
    await page.locator("#mode").filter({hasText: "reset"}).waitFor();
    await page.locator("#fixture-menu-item-alpha").waitFor({state: "attached"});
    await open(page, "ArrowUp");
    await focusId(page, "fixture-menu-item-empty");
    await page.keyboard.press("Escape");
    await focusId(page, "fixture-menu-trigger");

    await open(page);
    await page.locator("#outside").click();
    await focusId(page, "outside");
    assert.equal(await page.locator("#fixture-menu-popup").isVisible(), false);

    await open(page);
    await page.keyboard.press("Tab");
    await focusId(page, "outside");
    assert.equal(await page.locator("#fixture-menu-popup").isVisible(), false);
    await open(page);
    await page.keyboard.press("Shift+Tab");
    await page.locator("#fixture-menu-popup").waitFor({state: "hidden"});
    assert.equal(await page.evaluate(() => document.querySelector("#fixture-menu-popup").contains(document.activeElement)), false);

    await open(page);
    await page.keyboard.press("b");
    await page.keyboard.press("Enter");
    await page.locator("#actions").filter({hasText: "bravo"}).waitFor();
    assert.equal((await page.locator("#actions").textContent()).split("bravo").length - 1, 1);
    await focusId(page, "fixture-menu-trigger");
    assert.equal(await page.locator("#fixture-menu-popup").isVisible(), false);

    console.log(`PASS ${name} context ${iteration}`);
  } finally {
    await context.close();
    await browser.close();
  }
}

for (const [name, browserType] of Object.entries(engines)) {
  for (let iteration = 1; iteration <= 2; iteration++) await run(browserType, name, iteration);
}
