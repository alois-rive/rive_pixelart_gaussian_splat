// The gallery: every sample's signed .riv, decoded from a blob into a tile (a nested artboard bound
// to the Gallery view model). Tiles play in demo mode, dimmed; a click makes one active (white
// border, demo off: it takes the pointer); Escape hands it back to demo. The wheel or a drag on
// the background scrolls. The grid is responsive: this is a layout filling the artboard, so every
// resize lays the tiles out again (as many 640 x 400 columns as fit, centred; one scaled-down
// column when the window is narrower than a tile). Data and the pixel font: gallery_data.as.
import { Layout, Context } from "rive/host";
import { KeyboardEvent, PointerEvent, ScrollEvent } from "rive/events";
import { Renderer } from "rive/renderer";
import { Path } from "rive/path";
import { Paint, PaintStyle } from "rive/paint";
import { Color } from "rive/color";
import { Vector } from "rive/vector";
import { PropertyBoolean, PropertyNumber, ViewModel } from "rive/data";
import {
    COUNT, TILE_W, TILE_H, GAP, LABEL, MARGIN, TOP, WIDTH, HEIGHT, NAMES, GROUPS, PALETTES, FONT
} from "./gallery_data";

const KEY_ESCAPE: f64 = 256;
const DIM: u32 = 0x8C000000;      // 0xAARRGGBB
const BG: u32 = 0xFF0E0E12;
const WHITE: u32 = 0xFFFFFFFF;
const GREY: u32 = 0xFF8A8A96;
const FAINT: u32 = 0xFF4A4A56;

class DemoSwitch {
    prop: PropertyBoolean;
    constructor(prop: PropertyBoolean) { this.prop = prop; }
}

class NumberSlot {
    prop: PropertyNumber;
    last: f64 = -1e9;
    constructor(prop: PropertyNumber) { this.prop = prop; }
    set(v: f64): void {
        if (v != this.last) {
            this.last = v;
            this.prop.value = v;
        }
    }
}

export class Gallery extends Layout {
    context: Context? = null;
    vm: ViewModel? = null;
    started: bool = false;
    demo: Array<DemoSwitch?> = new Array<DemoSwitch?>();
    xs: Array<NumberSlot?> = new Array<NumberSlot?>();
    ys: Array<NumberSlot?> = new Array<NumberSlot?>();
    os: Array<NumberSlot?> = new Array<NumberSlot?>();
    scaleSlot: NumberSlot? = null;
    loaded: i32 = 0;
    active: i32 = -1;
    scroll: f64 = 0;
    target: f64 = 0;
    downX: f32 = 0;
    downY: f32 = 0;
    downScroll: f64 = 0;
    pressed: bool = false;
    dragging: bool = false;
    path: Path = new Path();
    paint: Paint = new Paint();

    // the layout, from the size the window gives
    width: f32 = WIDTH;
    height: f32 = HEIGHT;
    cols: i32 = 3;
    scale: f32 = 1;      // tiles shrink only when one column does not fit
    left: f32 = MARGIN;  // the grid's left edge (centred)
    top: f32 = TOP;      // where the first row starts (the header is taller when narrow)
    narrow: bool = false;

    override init(context: Context): bool {
        this.context = context;
        for (let i = 0; i < COUNT; i++) {
            this.demo.push(null);
            this.xs.push(null);
            this.ys.push(null);
            this.os.push(null);
        }
        this.relayout();
        return true;
    }

    override resize(width: f64, height: f64, scale: f64): void {
        if (width <= 0 || height <= 0) {
            return;
        }
        // keep the same row at the top of the window across a resize
        let rowPitch = <f64>((TILE_H + LABEL) * this.scale + GAP);
        let firstRow = rowPitch > 0 ? this.scroll / rowPitch : 0;
        let firstTile = <i32>Math.floor(firstRow) * this.cols;
        this.width = <f32>width;
        this.height = <f32>height;
        this.relayout();
        let newPitch = <f64>((TILE_H + LABEL) * this.scale + GAP);
        this.target = Math.min(Math.max(<f64>(firstTile / this.cols) * newPitch, 0), this.maxScroll());
        this.scroll = this.target;
    }

    private relayout(): void {
        let avail = this.width - MARGIN * 2;
        let cols = <i32>Mathf.floor((avail + GAP) / (TILE_W + GAP));
        if (cols < 1) {
            cols = 1;
        }
        this.cols = cols;
        this.scale = cols == 1 ? Mathf.min(1, avail / TILE_W) : 1;
        let gridW = <f32>cols * TILE_W * this.scale + <f32>(cols - 1) * GAP;
        this.left = Mathf.floor((this.width - gridW) * 0.5);
        // the header: title, counts, hint; the hint wraps under the counts when it does not fit
        this.narrow = this.width < 1500;
        this.top = this.narrow ? TOP + 36 : TOP;
        let s = this.scaleSlot;
        if (s != null) {
            s.set(<f64>this.scale);
        }
    }

    // The view model is bound after init: start loading on the first advance that has it.
    private begin(): void {
        let context = this.context;
        if (this.started || context == null) {
            return;
        }
        let vm = context.viewModel();
        if (vm == null) {
            return;
        }
        this.vm = vm;
        this.started = true;
        let ts = vm.getNumber("tileScale");
        if (ts != null) {
            this.scaleSlot = new NumberSlot(ts);
            this.scaleSlot!.set(<f64>this.scale);
        }
        for (let i = 0; i < COUNT; i++) {
            let x = vm.getNumber("x" + i.toString());
            let y = vm.getNumber("y" + i.toString());
            let o = vm.getNumber("o" + i.toString());
            if (x != null) { this.xs[i] = new NumberSlot(x); }
            if (y != null) { this.ys[i] = new NumberSlot(y); }
            if (o != null) { this.os[i] = new NumberSlot(o); }
            this.load(context, vm, i);
        }
    }

    async load(context: Context, vm: ViewModel, i: i32): Promise<void> {
        let bytes = context.blob("s" + i.toString());
        if (bytes == null) {
            return;
        }
        let file = await context.decodeFile(bytes);
        let prop = vm.getArtboard("tile" + i.toString());
        let ab = file.bindableArtboard();
        if (prop == null || ab == null) {
            return;
        }
        let data = ab.data;
        if (data != null) {
            let d = data.getBoolean("demo");
            if (d != null) {
                d.value = i != this.active;
                this.demo[i] = new DemoSwitch(d);
            }
        }
        prop.value = ab;
        this.loaded++;
    }

    // --- layout

    private tileW(): f32 { return TILE_W * this.scale; }
    private tileH(): f32 { return TILE_H * this.scale; }
    private rowPitch(): f32 { return this.tileH() + LABEL + GAP; }

    private rows(): i32 {
        return (COUNT + this.cols - 1) / this.cols;
    }

    private maxScroll(): f64 {
        let content = <f64>this.top + <f64>this.rows() * <f64>this.rowPitch() - <f64>GAP + <f64>MARGIN;
        return Math.max(0, content - <f64>this.height);
    }

    private tileX(i: i32): f32 {
        return this.left + <f32>(i % this.cols) * (this.tileW() + GAP);
    }

    private tileY(i: i32): f32 {
        return this.top + <f32>(i / this.cols) * this.rowPitch() - <f32>Math.round(this.scroll);
    }

    private tileAt(x: f32, y: f32): i32 {
        if (y < this.top - 16) {
            return -1; // the header covers what scrolls under it
        }
        let w = this.tileW(), h = this.tileH();
        for (let i = 0; i < COUNT; i++) {
            let tx = this.tileX(i), ty = this.tileY(i);
            if (x >= tx && x < tx + w && y >= ty && y < ty + h) {
                return i;
            }
        }
        return -1;
    }

    // --- activation

    private setDemo(i: i32, on: bool): void {
        if (i < 0 || i >= COUNT) {
            return;
        }
        let d = this.demo[i];
        if (d != null) {
            d.prop.value = on;
        }
    }

    private activate(i: i32): void {
        if (i == this.active) {
            return;
        }
        this.setDemo(this.active, true);
        this.active = i;
        this.setDemo(i, false);
        if (i >= 0) {
            // bring it fully into view
            let row = <f64>this.top + <f64>(i / this.cols) * <f64>this.rowPitch();
            let lo = row - <f64>this.top;
            let hi = row + <f64>(this.tileH() + LABEL) - <f64>this.height + <f64>MARGIN;
            if (this.target > lo) {
                this.target = lo;
            } else if (this.target < hi) {
                this.target = hi;
            }
            this.target = Math.min(Math.max(this.target, 0), this.maxScroll());
        }
    }

    override advance(seconds: f64): bool {
        this.begin();
        this.scroll += (this.target - this.scroll) * Math.min(1, seconds * 14);
        if (Math.abs(this.target - this.scroll) < 0.5) {
            this.scroll = this.target;
        }
        let h = this.tileH();
        for (let i = 0; i < COUNT; i++) {
            let x = this.xs[i], y = this.ys[i], o = this.os[i];
            let ty = this.tileY(i);
            if (x != null) { x.set(<f64>this.tileX(i)); }
            if (y != null) { y.set(<f64>ty); }
            // tiles out of sight stop drawing (their GPU passes are the gallery's cost)
            let visible = ty + h > 0 && ty < this.height;
            if (o != null) { o.set(visible ? 1 : 0); }
        }
        return true;
    }

    // --- input

    override pointerDown(event: PointerEvent): void {
        this.pressed = true;
        this.dragging = false;
        this.downX = event.position.x;
        this.downY = event.position.y;
        this.downScroll = this.target;
    }

    override pointerMove(event: PointerEvent): void {
        if (!this.pressed) {
            return;
        }
        // a drag that starts on the active tile belongs to its sample
        let t = this.tileAt(this.downX, this.downY);
        if (t >= 0 && t == this.active) {
            return;
        }
        let dy = event.position.y - this.downY;
        if (!this.dragging && Mathf.abs(dy) > 8) {
            this.dragging = true;
        }
        if (this.dragging) {
            this.target = Math.min(Math.max(this.downScroll - <f64>dy, 0), this.maxScroll());
            this.scroll = this.target;
            event.hit();
        }
    }

    override pointerUp(event: PointerEvent): void {
        if (!this.pressed) {
            return;
        }
        this.pressed = false;
        if (this.dragging) {
            this.dragging = false;
            return;
        }
        // activate on release, so the game never sees half of the click that woke it
        let t = this.tileAt(event.position.x, event.position.y);
        if (t >= 0 && t != this.active) {
            this.activate(t);
        }
    }

    override pointerScroll(event: ScrollEvent): void {
        this.target = Math.min(Math.max(this.target - <f64>event.delta.y, 0), this.maxScroll());
        event.hit();
    }

    override keyboardEvent(event: KeyboardEvent): bool {
        if (event.key == KEY_ESCAPE && event.phase == "down") {
            this.activate(-1);
            return true;
        }
        return false;
    }

    // --- drawing: covers, dimming, the active border, labels, the header

    private rect(renderer: Renderer, x: f32, y: f32, w: f32, h: f32, c: u32): void {
        let path = this.path;
        path.reset();
        path.moveTo(Vector.xy(x, y));
        path.lineTo(Vector.xy(x + w, y));
        path.lineTo(Vector.xy(x + w, y + h));
        path.lineTo(Vector.xy(x, y + h));
        path.close();
        this.paint.style = PaintStyle.fill;
        this.paint.color = Color.rgba(<i32>((c >> 16) & 0xFF), <i32>((c >> 8) & 0xFF), <i32>(c & 0xFF), <i32>(c >> 24));
        renderer.drawPath(path, this.paint);
    }

    private text(renderer: Renderer, x: f32, y: f32, s: string, c: u32, scale: f32): void {
        let path = this.path;
        path.reset();
        for (let i = 0; i < s.length; i++) {
            let ch = s.charCodeAt(i);
            if (ch >= 97 && ch <= 122) {
                ch -= 32;
            }
            if (ch < 32 || ch > 127) {
                continue;
            }
            let bits = <u32>FONT[ch - 32];
            for (let row = 0; row < 5; row++) {
                for (let col = 0; col < 3; col++) {
                    if ((bits >> <u32>(14 - row * 3 - col)) & 1) {
                        let px = x + (<f32>(i * 4 + col)) * scale;
                        let py = y + <f32>row * scale;
                        path.moveTo(Vector.xy(px, py));
                        path.lineTo(Vector.xy(px + scale, py));
                        path.lineTo(Vector.xy(px + scale, py + scale));
                        path.lineTo(Vector.xy(px, py + scale));
                        path.close();
                    }
                }
            }
        }
        this.paint.style = PaintStyle.fill;
        this.paint.color = Color.rgba(<i32>((c >> 16) & 0xFF), <i32>((c >> 8) & 0xFF), <i32>(c & 0xFF), 255);
        renderer.drawPath(path, this.paint);
    }

    private textWidth(s: string, scale: f32): f32 {
        return <f32>(s.length * 4 - 1) * scale;
    }

    override draw(renderer: Renderer): void {
        let tw = this.tileW(), th = this.tileH();
        let small = this.scale < 1;
        let ls: f32 = small ? 2 : 3; // label scale
        for (let i = 0; i < COUNT; i++) {
            let x = this.tileX(i), y = this.tileY(i);
            if (y + th + LABEL < 0 || y > this.height) {
                continue;
            }
            // the scenes draw a spare art pixel past their edges: cover it
            let m: f32 = 10;
            this.rect(renderer, x - m, y - m, tw + m * 2, m, BG);
            this.rect(renderer, x - m, y + th, tw + m * 2, m, BG);
            this.rect(renderer, x - m, y, m, th, BG);
            this.rect(renderer, x + tw, y, m, th, BG);
            if (i == this.active) {
                let b: f32 = 4;
                this.rect(renderer, x - b, y - b, tw + b * 2, b, WHITE);
                this.rect(renderer, x - b, y + th, tw + b * 2, b, WHITE);
                this.rect(renderer, x - b, y, b, th, WHITE);
                this.rect(renderer, x + tw, y, b, th, WHITE);
            } else {
                this.rect(renderer, x, y, tw, th, DIM);
            }
            let name = NAMES[i].replaceAll("-", " ");
            this.text(renderer, x, y + th + 14, name, i == this.active ? WHITE : GREY, ls);
            let pal = PALETTES[i];
            if (this.textWidth(name, ls) + this.textWidth(pal, ls) + 24 < tw) {
                this.text(renderer, x + tw - this.textWidth(pal, ls), y + th + 14, pal, FAINT, ls);
            }
        }
        // the header, over whatever scrolls under it
        let w = this.width;
        let titleScale: f32 = w < 700 ? 4 : 7;
        let sub: f32 = w < 700 ? 2 : 3;
        this.rect(renderer, 0, 0, w, this.top - 16, BG);
        let lx = this.left < MARGIN ? MARGIN : this.left;
        this.text(renderer, lx, 40, "PIXEL SPLAT SAMPLES", WHITE, titleScale);
        let games = 0;
        for (let i = 0; i < COUNT; i++) {
            if (GROUPS[i] == "games") {
                games++;
            }
        }
        let info = (COUNT - games).toString() + " DIORAMAS  " + games.toString() + " GAMES";
        let iy: f32 = 40 + titleScale * 5 + 16;
        this.text(renderer, lx, iy, info, GREY, sub);
        let built = "BUILT WITH RIVE";
        let bx = lx + this.textWidth(info, sub) + sub * 6;
        this.text(renderer, bx, iy, built, WHITE, sub);
        let after = bx + this.textWidth(built, sub);
        if (this.loaded < COUNT) {
            let ld = "LOADING " + this.loaded.toString() + "/" + COUNT.toString();
            this.text(renderer, after + sub * 6, iy, ld, FAINT, sub);
        }
        let hint = this.active >= 0 ? "ESC: BACK TO THE GALLERY" : "CLICK A SAMPLE TO PLAY IT   SCROLL FOR MORE";
        let hc = this.active >= 0 ? WHITE : GREY;
        let rx = (this.left < MARGIN ? MARGIN : this.left) + <f32>this.cols * tw + <f32>(this.cols - 1) * GAP;
        if (this.narrow) {
            this.text(renderer, lx, iy + sub * 5 + 12, hint, hc, sub);
        } else {
            this.text(renderer, rx - this.textWidth(hint, sub), iy, hint, hc, sub);
        }
    }
}
