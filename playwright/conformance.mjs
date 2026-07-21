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

async function actions(page) {
  const value = (await page.locator("#actions").textContent()).trim();
  return value ? value.split(",") : [];
}

async function open(page, key = "ArrowDown") {
  await page.locator("#fixture-menu-trigger").focus();
  await page.keyboard.press(key);
  await page.locator("#fixture-menu-popup").waitFor({state: "visible"});
}

async function runTabs(page) {
  const root = page.locator("#fixture-tabs");
  const tabs = root.locator("[data-lvc-tab]");
  const panels = page.locator("[data-lvc-panel][aria-labelledby^='fixture-tabs-tab-']");
  assert.equal(await root.getAttribute("data-orientation"), "horizontal");
  assert.equal(await root.getAttribute("role"), "tablist");
  assert.equal(await root.getAttribute("aria-orientation"), "horizontal");
  assert.equal(await root.getAttribute("aria-label"), "Fixture sections");

  for (let i = 0; i < await tabs.count(); i++) {
    const tab = tabs.nth(i);
    const panel = page.locator(`#${await tab.getAttribute("aria-controls")}`);
    assert.equal(await panel.count(), 1);
    assert.equal(await panel.getAttribute("aria-labelledby"), await tab.getAttribute("id"));
    const isSelected = await tab.getAttribute("aria-selected") === "true";
    assert.equal(await panel.getAttribute("hidden"), isSelected ? null : "");
    assert.equal(await panel.getAttribute("inert"), isSelected ? null : "");
  }
  assert.equal(await root.locator("[data-lvc-tab][aria-selected=true]").count(), 1);
  assert.equal(await panels.filter({visible: true}).count(), 1);
  assert.equal(await root.locator("[data-lvc-tab][tabindex='0']").count(), 1);

  const alpha = page.locator("#fixture-tabs-tab-alpha");
  await alpha.focus();
  const selected = async () => (await page.locator("#tabs-selected").textContent()).trim();
  assert.equal(await selected(), "alpha");
  await page.keyboard.press("ArrowRight");
  await focusId(page, "fixture-tabs-tab-bravo");
  assert.equal(await selected(), "alpha");
  await page.keyboard.press("ArrowRight");
  await focusId(page, "fixture-tabs-tab-charlie");
  await page.keyboard.press("ArrowRight");
  await focusId(page, "fixture-tabs-tab-alpha");
  await page.keyboard.press("ArrowLeft");
  await focusId(page, "fixture-tabs-tab-charlie");
  await page.keyboard.press("Home");
  await focusId(page, "fixture-tabs-tab-alpha");
  await page.keyboard.press("End");
  await focusId(page, "fixture-tabs-tab-charlie");
  assert.equal(await selected(), "alpha");

  const beforeDisabled = (await page.locator("#tabs-selections").textContent()).trim();
  await page.locator("#fixture-tabs-tab-charlie").focus();
  await page.locator("#fixture-tabs-tab-disabled").click({force: true});
  await focusId(page, "fixture-tabs-tab-charlie");
  assert.equal((await page.locator("#tabs-selections").textContent()).trim(), beforeDisabled);
  assert.equal(await page.locator("#fixture-tabs-tab-disabled").getAttribute("tabindex"), "-1");

  const beforeActivations = ((await page.locator("#tabs-selections").textContent()).trim().split(",").filter(Boolean)).length;
  for (const mode of ["Enter", "Space", "click"]) {
    await page.locator("#fixture-tabs-tab-bravo").focus();
    const before = ((await page.locator("#tabs-selections").textContent()).trim().split(",").filter(Boolean)).length;
    if (mode === "click") await page.locator("#fixture-tabs-tab-bravo").click();
    else await page.keyboard.press(mode);
    await page.waitForFunction(expected => document.querySelector("#tabs-selections").textContent.trim().split(",").filter(Boolean).length === expected, before + 1);
    assert.equal(await selected(), "bravo");
    assert.equal(await root.locator("[data-lvc-tab][aria-selected=true]").count(), 1);
    assert.equal(await panels.filter({visible: true}).count(), 1);
  }

  const bravoHandle = await page.locator("#fixture-tabs-tab-bravo").elementHandle();
  await page.locator("#tabs-patch").evaluate(el => el.click());
  await page.locator("#tabs-mode").filter({hasText: "patch"}).waitFor();
  assert.equal(((await page.locator("#tabs-selections").textContent()).trim().split(",").filter(Boolean)).length, beforeActivations + 3);
  await focusId(page, "fixture-tabs-tab-bravo");
  assert.equal(await page.evaluate(([a, b]) => a === b, [bravoHandle, await page.locator("#fixture-tabs-tab-bravo").elementHandle()]), true);
  await page.locator("#tabs-reorder").evaluate(el => el.click());
  await page.locator("#tabs-mode").filter({hasText: "reorder"}).waitFor();
  await focusId(page, "fixture-tabs-tab-bravo");
  assert.match(await page.locator("#fixture-tabs-tab-bravo").textContent(), /renamed/);

  await page.locator("#tabs-reset").click();
  await page.locator("#fixture-tabs-tab-bravo").focus();
  await page.locator("#tabs-remove-focused").evaluate(el => el.click());
  await page.locator("#tabs-mode").filter({hasText: "remove-focused"}).waitFor();
  await focusId(page, "fixture-tabs-tab-charlie");
  assert.equal(await page.locator("#fixture-tabs-tab-bravo").count(), 0);

  await page.locator("#tabs-reset").click();
  await page.locator("#fixture-tabs-tab-charlie").focus();
  await page.keyboard.press("Enter");
  await page.waitForFunction(() => document.querySelector("#tabs-selected").textContent.trim() === "charlie");
  await page.locator("#tabs-remove-selected").evaluate(el => el.click());
  await page.locator("#tabs-mode").filter({hasText: "remove-selected"}).waitFor();
  assert.equal(await selected(), "alpha");
  assert.equal(await page.locator("#fixture-tabs-tab-charlie").count(), 0);

  await page.locator("#tabs-reset").click();
  await page.locator("#tabs-panel-input").focus();
  await page.locator("#tabs-patch").evaluate(el => el.click());
  await page.locator("#tabs-mode").filter({hasText: "patch"}).waitFor();
  await focusId(page, "tabs-panel-input");

  await page.locator("#tabs-reset").click();
  await page.locator("#tabs-outside").focus();
  await page.locator("#tabs-reorder").evaluate(el => el.click());
  await page.locator("#tabs-mode").filter({hasText: "reorder"}).waitFor();
  await focusId(page, "tabs-outside");
  assert.equal(await root.locator("[data-lvc-tab][tabindex='0']").count(), 1);
  assert.equal(await page.locator("#fixture-tabs-tab-alpha").getAttribute("tabindex"), "0");
}

async function runDialog(page) {
  const root = page.locator("#fixture-dialog");
  const trigger = page.locator("#fixture-dialog-trigger");
  const popup = page.locator("#fixture-dialog-popup");
  const close = page.locator("#fixture-dialog-close");
  assert.equal(await trigger.getAttribute("aria-controls"), "fixture-dialog-popup");
  assert.equal(await popup.getAttribute("aria-labelledby"), "fixture-dialog-title");
  assert.equal(await popup.getAttribute("aria-describedby"), "fixture-dialog-description");
  assert.equal(await popup.getAttribute("open"), null);

  const history = async id => (await page.locator(id).textContent()).trim().split(",").filter(Boolean);
  const originalScrollStyle = await page.evaluate(() => ({overflow: document.documentElement.style.overflow, gutter: document.documentElement.style.scrollbarGutter}));
  await page.evaluate(() => {
    document.documentElement.style.overflow = "clip";
    document.documentElement.style.scrollbarGutter = "stable both-edges";
  });
  const previousOverflow = await page.evaluate(() => document.documentElement.style.overflow);
  const previousGutter = await page.evaluate(() => document.documentElement.style.scrollbarGutter);
  await trigger.click();
  await page.waitForFunction(() => document.querySelector("#fixture-dialog-popup").matches(":modal"));
  assert.equal(await popup.getAttribute("open"), "");
  assert.equal(await trigger.getAttribute("aria-expanded"), "true");
  assert.equal(await root.getAttribute("data-lvc-open"), "true");
  await page.waitForFunction(() => document.querySelector("#dialog-opens").textContent.trim() === "open");
  assert.deepEqual(await history("#dialog-opens"), ["open"]);
  await focusId(page, "dialog-initial");
  assert.equal(await page.evaluate(() => document.documentElement.style.overflow), "hidden");
  assert.equal(await page.evaluate(() => document.documentElement.style.scrollbarGutter), "stable");

  // Native inertness plus the Dialog-local first/last Tab boundary wrap.
  await page.locator("#dialog-positive-first").focus();
  await page.keyboard.press("Shift+Tab");
  await focusId(page, "fixture-dialog-close");
  await close.focus();
  await page.keyboard.press("Tab");
  await focusId(page, "dialog-positive-first");
  await page.locator("#dialog-remove-positive").evaluate(el => el.click());
  await page.locator("#dialog-positive-first").waitFor({state: "detached"});
  await page.locator("#dialog-name").focus();
  await page.keyboard.press("Shift+Tab");
  await focusId(page, "fixture-dialog-close");
  await close.focus();
  await page.keyboard.press("Tab");
  await focusId(page, "dialog-name");
  const beforeBackgroundFocus = await page.evaluate(() => document.activeElement?.id);
  await page.locator("#outside").focus();
  assert.equal(await page.evaluate(() => document.activeElement?.id), beforeBackgroundFocus);
  assert.equal(await popup.evaluate(el => el.contains(document.activeElement)), true);

  await page.locator("#dialog-fake-close").evaluate(el => el.click());
  assert.equal(await popup.evaluate(el => el.open), true);

  const popupHandle = await popup.elementHandle();
  const inputHandle = await page.locator("#dialog-name").elementHandle();
  await page.locator("#dialog-name").focus();
  await page.locator("#dialog-patch").evaluate(el => el.click());
  await page.waitForFunction(() => document.querySelector("#fixture-dialog").dataset.revision === "1");
  assert.equal(await page.evaluate(([a, b]) => a === b, [popupHandle, await popup.elementHandle()]), true);
  assert.equal(await page.evaluate(([a, b]) => a === b, [inputHandle, await page.locator("#dialog-name").elementHandle()]), true);
  await focusId(page, "dialog-name");
  assert.equal(await popup.evaluate(el => el.matches(":modal")), true);

  await close.focus();
  await page.locator("#dialog-patch").evaluate(el => el.click());
  await page.waitForFunction(() => document.querySelector("#fixture-dialog").dataset.revision === "2");
  await focusId(page, "fixture-dialog-close");

  await page.locator("#dialog-remove-focus").evaluate(el => el.click());
  await page.waitForFunction(() => !document.querySelector("#dialog-name"));
  await page.waitForFunction(() => document.activeElement?.matches("[data-lvc-dialog-close]"));

  await close.click();
  await page.waitForFunction(() => !document.querySelector("#fixture-dialog-popup").open);
  await page.waitForFunction(() => document.querySelector("#dialog-closes").textContent.trim() === "close");
  assert.deepEqual(await history("#dialog-closes"), ["close"]);
  assert.equal(await root.getAttribute("data-lvc-close-reason"), "close");
  await focusId(page, "fixture-dialog-trigger");
  assert.equal(await page.evaluate(() => document.documentElement.style.overflow), previousOverflow);
  assert.equal(await page.evaluate(() => document.documentElement.style.scrollbarGutter), previousGutter);
  await page.locator("#dialog-ack-close").click();
  await page.locator("#fixture-dialog[data-lvc-desired-open='false']").waitFor();

  await page.locator("#dialog-reset").click();
  await page.locator("#dialog-name").waitFor({state: "attached"});
  await trigger.focus();
  await page.keyboard.press("Enter");
  await focusId(page, "dialog-initial");
  await page.keyboard.press("Escape");
  await page.waitForFunction(() => !document.querySelector("#fixture-dialog-popup").open);
  await page.waitForFunction(() => document.querySelector("#dialog-closes").textContent.trim() === "close,escape");
  await focusId(page, "fixture-dialog-trigger");
  assert.equal(await page.evaluate(() => document.documentElement.style.overflow), previousOverflow);
  assert.equal(await page.evaluate(() => document.documentElement.style.scrollbarGutter), previousGutter);
  const staleRevision = Number(await root.getAttribute("data-revision"));
  await page.locator("#dialog-stale-patch").click();
  await page.waitForFunction(expected => Number(document.querySelector("#fixture-dialog").dataset.revision) > expected, staleRevision);
  assert.equal(await popup.evaluate(el => el.open), false);
  assert.equal(await popup.evaluate(el => el.matches(":modal")), false);
  assert.equal(await page.evaluate(() => document.documentElement.style.overflow), previousOverflow);
  assert.equal(await page.evaluate(() => document.documentElement.style.scrollbarGutter), previousGutter);
  assert.equal(await root.getAttribute("data-lvc-desired-open"), "true");
  await page.locator("#dialog-ack-close").click();
  await page.locator("#fixture-dialog[data-lvc-desired-open='false']").waitFor();
  assert.deepEqual(await history("#dialog-closes"), ["close", "escape"]);

  const opensBeforeServer = (await history("#dialog-opens")).length;
  await page.locator("#dialog-server-open").click();
  await page.waitForFunction(() => document.querySelector("#fixture-dialog-popup").matches(":modal"));
  assert.equal((await history("#dialog-opens")).length, opensBeforeServer);
  await focusId(page, "dialog-initial");
  const closesBeforeServer = (await history("#dialog-closes")).length;
  await page.locator("#dialog-server-close").evaluate(el => el.click());
  await page.waitForFunction(() => !document.querySelector("#fixture-dialog-popup").open);
  await page.waitForFunction(() => document.querySelector("#fixture-dialog").dataset.lvcOpen === "false");
  assert.equal((await history("#dialog-closes")).length, closesBeforeServer);
  assert.equal(await root.getAttribute("data-lvc-open"), "false");
  await page.evaluate(original => {
    document.documentElement.style.overflow = original.overflow;
    document.documentElement.style.scrollbarGutter = original.gutter;
  }, originalScrollStyle);
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
    for (const key of ["Enter", "Space"]) {
      await trigger.focus();
      await page.keyboard.press(key);
      await focusId(page, "fixture-menu-item-alpha");
      await page.keyboard.press("Escape");
    }

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
    const disabledCount = (await actions(page)).length;
    await page.keyboard.press("Enter");
    await page.keyboard.press("Space");
    await page.locator("#fixture-menu-item-disabled").click({force: true});
    assert.equal((await actions(page)).length, disabledCount);
    assert.equal(await page.locator("#fixture-menu-popup").isVisible(), true);

    await page.keyboard.press("End");
    await page.keyboard.press("a");
    await focusId(page, "fixture-menu-item-alpha");
    await page.waitForTimeout(550);
    await page.keyboard.press("q");
    await focusId(page, "fixture-menu-item-charlie");
    await page.waitForTimeout(550);
    await page.keyboard.press("b");
    await page.keyboard.press("r");
    await focusId(page, "fixture-menu-item-bravo");
    await page.waitForTimeout(550);
    for (const key of ["Control+a", "Alt+a", "Meta+a"]) {
      await page.keyboard.press(key);
      await focusId(page, "fixture-menu-item-bravo");
    }
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
    assert.equal(await trigger.getAttribute("aria-expanded"), "true");
    await focusId(page, "fixture-menu-item-patch");

    await page.keyboard.press("ArrowDown");
    await focusId(page, "fixture-menu-item-reorder");
    await page.keyboard.press("Enter");
    await page.locator("#mode").filter({hasText: "reorder"}).waitFor();
    assert.equal(await page.evaluate(([a, b]) => a === b, [bravoHandle, await page.locator("#fixture-menu-item-bravo").elementHandle()]), true);
    await focusId(page, "fixture-menu-item-reorder");
    assert.match(await page.locator("#fixture-menu-item-bravo").textContent(), /updated/);
    assert.equal(await trigger.getAttribute("aria-expanded"), "true");

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
    await page.waitForFunction(() =>
      document.querySelector("#fixture-menu")?.dataset.lvcOpen === "false" &&
      !document.querySelector("#fixture-menu [data-lvc-active]"));
    assert.equal(await page.locator("#fixture-menu [data-lvc-active]").count(), 0);
    assert.equal(await page.locator("#fixture-menu").getAttribute("data-lvc-dismiss-reason"), "outside");
    await trigger.click();
    await focusId(page, "fixture-menu-item-alpha");
    assert.equal(await page.locator("#fixture-menu").getAttribute("data-lvc-open"), "true");
    assert.equal(await page.locator("#fixture-menu").getAttribute("data-lvc-dismiss-reason"), null);
    await trigger.click();
    await page.locator("#fixture-menu-popup").waitFor({state: "hidden"});
    await page.locator("#fixture-menu[data-lvc-dismiss-reason='trigger']").waitFor();
    assert.equal(await page.locator("#fixture-menu").getAttribute("data-lvc-dismiss-reason"), "trigger");
    assert.equal(await page.locator("#fixture-menu [data-lvc-active]").count(), 0);
    assert.equal(await trigger.getAttribute("aria-expanded"), "false");
    await trigger.click();
    await focusId(page, "fixture-menu-item-alpha");
    await page.locator("#fixture-menu-popup").evaluate(popup => {
      popup.hidePopover();
      popup.showPopover();
    });
    await focusId(page, "fixture-menu-item-alpha");
    assert.equal(await page.locator("#fixture-menu").getAttribute("data-lvc-open"), "true");
    assert.equal(await page.locator("#fixture-menu").getAttribute("data-lvc-dismiss-reason"), null);
    await page.keyboard.press("Escape");

    await open(page);
    await page.keyboard.press("Tab");
    await focusId(page, "outside");
    assert.equal(await page.locator("#fixture-menu-popup").isVisible(), false);
    await open(page);
    await page.keyboard.press("Shift+Tab");
    await page.locator("#fixture-menu-popup").waitFor({state: "hidden"});
    assert.equal(await page.evaluate(() => document.querySelector("#fixture-menu-popup").contains(document.activeElement)), false);

    for (const mode of ["Enter", "Space", "click"]) {
      await open(page);
      await page.keyboard.press("b");
      const before = (await actions(page)).length;
      if (mode === "click") await page.locator("#fixture-menu-item-bravo").click();
      else await page.keyboard.press(mode);
      await page.waitForFunction(expected => {
        const value = document.querySelector("#actions").textContent.trim();
        return (value ? value.split(",") : []).length === expected;
      }, before + 1);
      assert.equal((await actions(page)).length, before + 1);
      assert.equal((await actions(page)).at(-1), "bravo");
      await focusId(page, "fixture-menu-trigger");
      assert.equal(await page.locator("#fixture-menu-popup").isVisible(), false);
    }

    await runTabs(page);
    await runDialog(page);
    console.log(`PASS ${name} context ${iteration}`);
  } finally {
    await context.close();
    await browser.close();
  }
}

for (const [name, browserType] of Object.entries(engines)) {
  for (let iteration = 1; iteration <= 2; iteration++) await run(browserType, name, iteration);
}
