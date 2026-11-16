// The scene's game logic. This default does nothing: a diorama keeps it as is. A game replaces
// this file (and only this file); the renderer calls these four methods. See references/games.md.
import { GameApi } from "./game_api";

export class Game {
    // Once, on the first frame, after the scene's inputs are applied: find bones, set the camera.
    start(api: GameApi): void {}

    // Every frame. api.demo: play yourself (no pointer). Move things with api.place / api.hide,
    // the camera through api's camera fields.
    update(api: GameApi): void {}

    // The pointer, in HUD pixels: kind is POINTER_DOWN, POINTER_MOVE or POINTER_UP. Return true to
    // take it (false lets the scene's orbit have it). Never called in demo mode.
    pointer(api: GameApi, kind: i32, x: f32, y: f32): bool { return false; }

    // Every drawn frame: the HUD, with api.text / api.rect in palette colours.
    hud(api: GameApi): void {}
}
