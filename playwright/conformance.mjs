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

async function runAccordion(page) {
  const root = page.locator("#fixture-accordion");
  const shipping = page.locator("#fixture-accordion-trigger-shipping");
  const returns = page.locator("#fixture-accordion-trigger-returns");
  const eventCount = async () => (await page.locator("#accordion-events").textContent()).trim().split(";").filter(Boolean).length;
  const revision = async () => Number(await root.getAttribute("data-revision"));
  const waitRevision = async before => page.waitForFunction(value => Number(document.querySelector("#fixture-accordion").dataset.revision) > value, before);
  const reset = async () => {
    const before = await revision();
    await page.locator("#accordion-reset").click();
    await waitRevision(before);
    assert.equal(await eventCount(), 0);
    assert.equal(await shipping.getAttribute("aria-expanded"), "true");
  };
  assert.equal(await shipping.getAttribute("aria-controls"), "fixture-accordion-panel-shipping");
  assert.equal(await page.locator("#fixture-accordion-panel-shipping").getAttribute("aria-labelledby"), await shipping.getAttribute("id"));
  assert.equal(await shipping.getAttribute("aria-expanded"), "true");
  assert.equal(await page.locator("#fixture-accordion-panel-returns").getAttribute("hidden"), "");

  for (const mode of ["click", "Enter", "Space"]) {
    await reset();
    await returns.focus();
    if (mode === "click") await returns.click(); else await page.keyboard.press(mode);
    await page.waitForFunction(() => document.querySelector("#accordion-events").textContent.trim().split(";").filter(Boolean).length === 1);
    assert.equal(await eventCount(), 1);
    assert.equal(await returns.getAttribute("aria-expanded"), "true");
    assert.equal(await shipping.getAttribute("aria-expanded"), "false");
  }
  await returns.click();
  await page.waitForFunction(() => document.querySelector("#accordion-events").textContent.trim().split(";").filter(Boolean).length === 2);
  assert.equal(await returns.getAttribute("aria-expanded"), "false");
  assert.equal(await shipping.getAttribute("aria-expanded"), "false");

  await reset();
  const disabled = page.locator("#fixture-accordion-trigger-disabled");
  await disabled.focus();
  await disabled.evaluate(element => element.click());
  const disabledRevision = await revision();
  await page.locator("#accordion-patch").evaluate(el => el.click());
  await waitRevision(disabledRevision);
  assert.equal(await eventCount(), 0);
  await page.keyboard.press("ArrowDown");
  await focusId(page, "fixture-accordion-trigger-disabled");

  // A nested multiple accordion owns only its own items and composes membership.
  const one = page.locator("#fixture-accordion-multiple-trigger-one");
  const two = page.locator("#fixture-accordion-multiple-trigger-two");
  await one.click();
  await page.waitForFunction(() => document.querySelector("#accordion-multiple-events").textContent.trim() === "1");
  await two.click();
  await page.waitForFunction(() => document.querySelector("#accordion-multiple-events").textContent.trim() === "2");
  assert.equal(await one.getAttribute("aria-expanded"), "true");
  assert.equal(await two.getAttribute("aria-expanded"), "true");
  assert.equal(await shipping.getAttribute("aria-expanded"), "true");
  assert.equal(await eventCount(), 0);
  await one.click();
  await page.waitForFunction(() => document.querySelector("#accordion-multiple-events").textContent.trim() === "3");
  assert.equal(await one.getAttribute("aria-expanded"), "false");
  assert.equal(await two.getAttribute("aria-expanded"), "true");

  // Two intents compose from effective state before either server patch settles.
  await reset();
  await returns.evaluate(element => { element.click(); element.click(); });
  await page.waitForFunction(() => document.querySelector("#accordion-events").textContent.trim().split(";").filter(Boolean).length === 2);
  assert.equal(await returns.getAttribute("aria-expanded"), "false");
  assert.equal(await shipping.getAttribute("aria-expanded"), "false");

  await reset();
  await returns.click();
  await page.waitForFunction(() => document.querySelector("#accordion-events").textContent.trim().split(";").filter(Boolean).length === 1);
  await returns.focus();
  await focusId(page, "fixture-accordion-trigger-returns");
  const itemHandle = await page.locator("[data-lvc-accordion-item][data-lvc-logical-id=returns]").elementHandle();
  const triggerHandle = await returns.elementHandle();
  const panelHandle = await page.locator("#fixture-accordion-panel-returns").elementHandle();
  const patchRevision = await revision();
  await page.locator("#accordion-patch").evaluate(el => el.click());
  await waitRevision(patchRevision);
  assert.equal(await page.evaluate(([a, b]) => a === b, [itemHandle, await page.locator("[data-lvc-accordion-item][data-lvc-logical-id=returns]").elementHandle()]), true);
  assert.equal(await page.evaluate(([a, b]) => a === b, [triggerHandle, await returns.elementHandle()]), true);
  assert.equal(await page.evaluate(([a, b]) => a === b, [panelHandle, await page.locator("#fixture-accordion-panel-returns").elementHandle()]), true);
  await focusId(page, "fixture-accordion-trigger-returns");
  assert.equal(await returns.getAttribute("aria-expanded"), "true");

  const reorderRevision = await revision();
  await page.locator("#accordion-reorder").evaluate(el => el.click());
  await waitRevision(reorderRevision);
  await page.locator("#fixture-accordion-trigger-returns").filter({hasText: "renamed"}).waitFor();
  assert.equal(await page.evaluate(([a, b]) => a === b, [triggerHandle, await returns.elementHandle()]), true);
  await focusId(page, "fixture-accordion-trigger-returns");
  assert.equal(await returns.getAttribute("aria-expanded"), "true");
  const insertRevision = await revision();
  await page.locator("#accordion-insert").evaluate(el => el.click());
  await waitRevision(insertRevision);
  await page.locator("#fixture-accordion-trigger-billing").waitFor();
  assert.equal(await page.evaluate(([a, b]) => a === b, [triggerHandle, await returns.elementHandle()]), true);
  await focusId(page, "fixture-accordion-trigger-returns");
  assert.equal(await returns.getAttribute("aria-expanded"), "true");

  // Removal prunes a pending value instead of leaving a sticky empty pending set.
  await reset();
  await returns.evaluate(element => element.click());
  const removeRevision = await revision();
  await page.locator("#accordion-remove").evaluate(el => el.click());
  await waitRevision(removeRevision);
  await returns.waitFor({state: "detached"});
  const closeAfterRemoveRevision = await revision();
  await page.locator("#accordion-server-close").evaluate(el => el.click());
  await waitRevision(closeAfterRemoveRevision);
  assert.equal(await root.getAttribute("data-lvc-values"), "[]");
  assert.equal(await shipping.getAttribute("aria-expanded"), "false");

  await reset();
  await page.locator("#accordion-panel-input").focus();
  const closeRevision = await revision();
  await page.locator("#accordion-server-close").evaluate(el => el.click());
  await waitRevision(closeRevision);
  await focusId(page, "fixture-accordion-trigger-shipping");

  await reset();
  await page.locator("#accordion-outside").focus();
  const outsideCloseRevision = await revision();
  await page.locator("#accordion-server-close").evaluate(el => el.click());
  await waitRevision(outsideCloseRevision);
  await focusId(page, "accordion-outside");
  assert.equal(await root.locator(":scope > [data-lvc-accordion-item]").count(), 3);
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

async function runTooltip(page) {
  const root = page.locator("#fixture-tooltip");
  const trigger = page.locator("#fixture-tooltip-trigger");
  const popup = page.locator("#fixture-tooltip-popup");
  const isOpen = () => popup.evaluate(el => el.matches(":popover-open"));

  assert.equal(await popup.getAttribute("role"), "tooltip");
  assert.equal(await popup.getAttribute("popover"), "manual");
  assert.equal(await trigger.getAttribute("aria-describedby"), "fixture-help");
  assert.equal(await isOpen(), false);

  const focusBeforeHover = await page.evaluate(() => document.activeElement?.id);
  await trigger.hover();
  await page.waitForTimeout(50);
  assert.equal(await isOpen(), false);
  await page.waitForFunction(() => document.querySelector("#fixture-tooltip-popup").matches(":popover-open"));
  assert.equal(await root.getAttribute("data-lvc-open"), "true");
  assert.equal(await trigger.getAttribute("aria-describedby"), "fixture-help fixture-tooltip-popup");
  await page.keyboard.press("Escape");
  assert.equal(await isOpen(), false);
  assert.equal(await page.evaluate(() => document.activeElement?.id), focusBeforeHover);
  await page.waitForTimeout(140);
  assert.equal(await isOpen(), false);
  await page.mouse.move(0, 0);
  assert.equal(await trigger.getAttribute("aria-describedby"), "fixture-help");

  // A cancelled timer and an older timer from rapid re-entry cannot open it.
  await trigger.hover();
  await page.waitForTimeout(35);
  await page.mouse.move(0, 0);
  await page.waitForTimeout(110);
  assert.equal(await isOpen(), false);
  await trigger.hover();
  await page.waitForTimeout(35);
  await page.mouse.move(0, 0);
  await trigger.hover();
  await page.waitForTimeout(50);
  assert.equal(await isOpen(), false);
  await page.waitForFunction(() => document.querySelector("#fixture-tooltip-popup").matches(":popover-open"));

  // Focus and pointer are independent sources in both directions.
  await trigger.focus();
  await page.mouse.move(0, 0);
  assert.equal(await isOpen(), true);
  await trigger.hover();
  await page.locator("#tooltip-patch").focus();
  assert.equal(await isOpen(), true);
  await page.mouse.move(0, 0);
  await page.waitForFunction(() => !document.querySelector("#fixture-tooltip-popup").matches(":popover-open"));

  // Focus opens immediately. Escape retains focus and suppresses reopening.
  await trigger.focus();
  assert.equal(await isOpen(), true);
  await page.keyboard.press("Escape");
  await focusId(page, "fixture-tooltip-trigger");
  assert.equal(await isOpen(), false);
  await page.waitForTimeout(140);
  assert.equal(await isOpen(), false);
  await page.mouse.move(0, 0);
  await trigger.hover();
  assert.equal(await isOpen(), true);
  await page.mouse.move(0, 0);
  assert.equal(await isOpen(), true);
  await page.keyboard.press("Escape");
  await page.locator("#outside").focus();
  await trigger.focus();
  assert.equal(await isOpen(), true);
  await page.keyboard.press("Enter");
  assert.equal(await isOpen(), false);
  await page.locator("#outside").focus();
  await trigger.focus();
  await page.keyboard.press("Space");
  assert.equal(await isOpen(), false);
  await page.locator("#outside").focus();
  await trigger.hover();
  await page.waitForFunction(() => document.querySelector("#fixture-tooltip-popup").matches(":popover-open"));
  await trigger.locator("span").click();
  assert.equal(await isOpen(), false);
  await page.locator("#outside").focus();
  await trigger.focus();
  await trigger.evaluate(element => element.click());
  assert.equal(await isOpen(), false);

  // Touch pointer entry is ignored.
  await page.locator("#outside").focus();
  await trigger.dispatchEvent("pointerenter", {pointerType: "touch"});
  await page.waitForTimeout(140);
  assert.equal(await isOpen(), false);

  // Open content patches preserve popup and trigger identity, focus, native state, and ARIA.
  await trigger.focus();
  const popupHandle = await popup.elementHandle();
  const triggerHandle = await trigger.elementHandle();
  const revision = Number(await root.getAttribute("data-revision"));
  await page.locator("#tooltip-patch").evaluate(el => el.click());
  await page.waitForFunction(expected => Number(document.querySelector("#fixture-tooltip").dataset.revision) > expected, revision);
  assert.equal(await page.evaluate(([a, b]) => a === b, [popupHandle, await popup.elementHandle()]), true);
  assert.equal(await page.evaluate(([a, b]) => a === b, [triggerHandle, await trigger.elementHandle()]), true);
  await focusId(page, "fixture-tooltip-trigger");
  assert.equal(await isOpen(), true);
  assert.match(await popup.textContent(), /revision 1/);
  assert.equal(await trigger.getAttribute("aria-describedby"), "fixture-help fixture-tooltip-popup");

  await page.locator("#tooltip-base").evaluate(el => el.click());
  await page.waitForFunction(() => document.querySelector("#fixture-tooltip").dataset.lvcBaseDescribedby === "fixture-help-updated");
  assert.equal(await trigger.getAttribute("aria-describedby"), "fixture-help-updated fixture-tooltip-popup");

  await page.locator("#tooltip-disable").evaluate(el => el.click());
  await page.waitForFunction(() => document.querySelector("#fixture-tooltip").dataset.lvcDisabled === "true");
  assert.equal(await isOpen(), false);
  assert.equal(await trigger.getAttribute("aria-describedby"), "fixture-help-updated");

  await page.locator("#tooltip-reset").click();
  await page.locator("#outside").focus();
  await page.locator("#tooltip-delay").click();
  await page.waitForFunction(() => document.querySelector("#fixture-tooltip").dataset.lvcDelay === "80");
  await trigger.hover();
  await page.waitForTimeout(20);
  assert.equal(await isOpen(), false);
  await page.waitForFunction(() => document.querySelector("#fixture-tooltip-popup").matches(":popover-open"));
  await page.mouse.move(0, 0);

  await trigger.hover();
  await page.waitForTimeout(20);
  await page.locator("#tooltip-remove").evaluate(el => el.click());
  await root.waitFor({state: "detached"});
  await page.waitForTimeout(100);
  await page.locator("#tooltip-reset").click();
  await root.waitFor({state: "attached"});
  assert.equal(await root.getAttribute("data-lvc-open"), "false");
  assert.equal(await page.locator("#fixture-tooltip-popup").evaluate(el => el.matches(":popover-open")), false);
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
    await runTooltip(page);
    await runAccordion(page);
    console.log(`PASS ${name} context ${iteration}`);
  } finally {
    await context.close();
    await browser.close();
  }
}

for (const [name, browserType] of Object.entries(engines)) {
  for (let iteration = 1; iteration <= 2; iteration++) await run(browserType, name, iteration);
}
