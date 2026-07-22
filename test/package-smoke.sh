#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
TMP=$(mktemp -d "${TMPDIR:-/tmp}/liveview-continuity-package-smoke.XXXXXX")
cleanup() { rm -rf "$TMP"; }
trap cleanup EXIT

cd "$ROOT"
mix hex.build --unpack --output "$TMP/package" >/dev/null
test -f "$TMP/package/lib/live_view_continuity/menu.ex"
test -f "$TMP/package/lib/live_view_continuity/tabs.ex"
test -f "$TMP/package/lib/live_view_continuity/dialog.ex"
test -f "$TMP/package/lib/live_view_continuity/tooltip.ex"
test ! -e "$TMP/package/fixture"
test ! -e "$TMP/package/playwright"

mkdir "$TMP/consumer"
cat > "$TMP/consumer/mix.exs" <<'EOF'
defmodule ContinuityPackageConsumer.MixProject do
  use Mix.Project

  def project do
    [
      app: :continuity_package_consumer,
      version: "0.1.0",
      elixir: ">= 1.18.0",
      compilers: [:phoenix_live_view] ++ Mix.compilers(),
      deps: [{:liveview_continuity, path: System.fetch_env!("LVC_PACKAGE_PATH")}]
    ]
  end
end
EOF

cat > "$TMP/consumer/app.js" <<'EOF'
import {hooks} from "phoenix-colocated/liveview_continuity";
if (!hooks["LiveViewContinuity.Menu.Menu"]) throw new Error("Menu colocated hook missing");
if (!hooks["LiveViewContinuity.Tabs.Tabs"]) throw new Error("Tabs colocated hook missing");
if (!hooks["LiveViewContinuity.Dialog.Dialog"]) throw new Error("Dialog colocated hook missing");
if (!hooks["LiveViewContinuity.Tooltip.Tooltip"]) throw new Error("Tooltip colocated hook missing");
console.log("package hook ok");
EOF

cd "$TMP/consumer"
LVC_PACKAGE_PATH="$TMP/package" mix deps.get >/dev/null
LVC_PACKAGE_PATH="$TMP/package" mix compile --warnings-as-errors >/dev/null
NODE_PATH="$TMP/consumer/deps:$TMP/consumer/_build/dev" \
  "$ROOT/node_modules/.bin/esbuild" app.js --bundle --target=es2022 --outfile=app.bundle.js >/dev/null
node app.bundle.js | grep -q "package hook ok"
echo "package boundary smoke: ok"
