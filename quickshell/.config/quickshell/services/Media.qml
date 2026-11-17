pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Mpris

// Read-only facade over Mpris. Players are live objects, so there is nothing
// to poll here: every property below re-evaluates when the player changes.
Singleton {
  id: root

  // User-selected player (cyclePlayer); null means "pick automatically".
  property var activePlayer: null

  readonly property var players: Mpris.players ? Mpris.players.values : []

  readonly property var player: {
    const list = root.players;
    if (root.activePlayer && list.indexOf(root.activePlayer) !== -1)
      return root.activePlayer;

    // A stopped player with no track is a dead end for the island: prefer
    // something that is actually playing/paused, then anything alive.
    const playable = (p) => p.playbackState === MprisPlaybackState.Playing
      || p.playbackState === MprisPlaybackState.Paused;

    for (let i = 0; i < list.length; i++) {
      if (playable(list[i]) && list[i].trackTitle)
        return list[i];
    }
    for (let i = 0; i < list.length; i++) {
      if (list[i].playbackState !== MprisPlaybackState.Stopped)
        return list[i];
    }
    return list.length > 0 ? list[0] : null;
  }

  readonly property bool hasPlayer: player !== null
  readonly property bool isPlaying: player !== null && player.isPlaying

  // MprisPlayer exposes flat track fields (no `track` object) in QS 0.3.x.
  readonly property string title: player ? (player.trackTitle || "") : ""
  readonly property string artist: player ? (player.trackArtist || "") : ""
  readonly property string artUrl: player ? (player.trackArtUrl || "") : ""

  // The binding below makes `positionChanged` (the auto-generated notify signal
  // for this property) re-fire on the active player's positionChanged, so an
  // external/nonlinear seek reaches UI through the facade without polling.
  // A second `signal positionChanged()` is illegal in QML: it would collide
  // with this property's change signal ("Duplicate signal name" at load).
  readonly property real position: player ? player.position : 0
  readonly property real length: player ? player.length : 0
  readonly property bool positionSupported: player ? player.positionSupported : false
  readonly property bool canSeek: player ? player.canSeek : false
  readonly property bool canGoNext: player ? player.canGoNext : false
  readonly property bool canGoPrevious: player ? player.canGoPrevious : false
  readonly property string playerLabel: player ? (player.identity || "") : ""

  function togglePlaying() {
    if (player)
      player.togglePlaying();
  }

  function next() {
    if (player && player.canGoNext)
      player.next();
  }

  function previous() {
    if (player && player.canGoPrevious)
      player.previous();
  }

  // MprisPlayer has no setPosition(); writing `position` seeks.
  function seekTo(x) {
    if (!player || !player.canSeek)
      return;
    const max = player.length;
    player.position = Math.max(0, max > 0 ? Math.min(x, max) : x);
  }

  function cyclePlayer() {
    const list = root.players;
    if (list.length < 2)
      return;
    const idx = root.player ? list.indexOf(root.player) : -1;
    root.activePlayer = list[(idx + 1) % list.length];
  }
}
