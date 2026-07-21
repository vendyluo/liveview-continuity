import {Socket} from "phoenix";
import {LiveSocket} from "phoenix_live_view";
import {hooks as continuityHooks} from "phoenix-colocated/liveview_continuity";

const csrfToken = document.querySelector("meta[name='csrf-token']").content;
const liveSocket = new LiveSocket("/live", Socket, {
  hooks: {...continuityHooks},
  params: {_csrf_token: csrfToken}
});

liveSocket.connect();
window.liveSocket = liveSocket;
