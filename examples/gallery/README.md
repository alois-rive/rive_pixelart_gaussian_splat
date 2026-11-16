# Gallery

Every sample in one Rive file: a scrollable grid of live tiles, each the sample's own signed
`.riv` (in `riv/`), decoded at runtime and shown in a nested artboard.

- The grid follows the window: as many 640 x 400 columns as fit, centred, tiles at 1:1; a
  window narrower than one tile gets one scaled-down column. Resizing keeps the same row at
  the top.
- Tiles play in demo mode, dimmed: dioramas turn, games play themselves.
- Click a tile: it becomes active (white border, full brightness) and takes the pointer: play
  the game, or drag to orbit a diorama.
- Escape hands it back to demo mode. The wheel, or a drag on the background, scrolls.

```sh
cd examples
python3 gallery/build_gallery.py          # sign changed samples into gallery/riv/, regenerate, verify
rive gallery                              # the live preview
rive gallery --publish                    # the gallery's own signed .riv
```

How it works:

- `build_gallery.py` publishes each `dioramas/*/scene` and `games/*/scene` with
  `rive --publish` (a decoded file runs its scripts only when Rive signed them; it needs `rive
  login`), then writes `gallery.rml` (one nested artboard per sample, its artboard, position
  and opacity bound to the `Gallery` view model, and a `BlobAsset` per `.riv`) and
  `gallery_data.as` (names, palettes, the pixel font). Both are generated: edit the script.
- `gallery.as` (the host: a scripted layout filling the artboard, with focus, so `resize`
  tells it the window's size) decodes each blob with
  `context.decodeFile`, assigns `file.bindableArtboard()` to the tile's artboard property,
  and drives each sample through its own `Sample` view model: `demo` true for every tile but
  the active one. It scrolls the tiles by writing their positions, hides those out of sight
  (opacity 0: no GPU passes), and draws the dimming, the active border, the labels and the
  header with the same 3 x 5 pixel font as the games' HUD.
- A click activates on release, so the game never sees half of the click that woke it; the
  host never claims pointer events over the active tile, so they reach the sample.
- Pointer only: Rive forwards pointer, scroll and gamepad events into nested artboards, not
  keys, which is why every game plays with the pointer.
