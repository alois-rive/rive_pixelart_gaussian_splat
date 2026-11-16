// The gallery: every sample's signed .riv, decoded from a blob into a tile (a nested artboard bound
// to the Gallery view model). Tiles play in demo mode, dimmed; a click or tap makes one active
// (white border, demo off: it takes the pointer); Escape or STOP hands it back to demo.
//
// Two layouts, chosen from the window's width on every resize:
//   grid    as many 640 x 400 columns as fit (2 or more), centred, scrolled by the wheel or a drag
//   single  one column (phones, narrow windows): ONE sample fitted to the screen, with PREV /
//           RANDOM / NEXT buttons and left/right swipes to move between samples
// A sample is bound to its tile (and so starts running) only when first shown; tiles out of
// sight are paused and hidden, so a phone runs one sample at a time. Data and the pixel font:
// gallery_data.as.
import { Layout, Context } from "rive/host";
import { KeyboardEvent, PointerEvent, ScrollEvent } from "rive/events";
import { Renderer } from "rive/renderer";
import { Path } from "rive/path";
import { Paint, PaintStyle } from "rive/paint";
import { Color } from "rive/color";
import { Vector } from "rive/vector";
import { PropertyArtboard, PropertyBoolean, PropertyNumber, ViewModel } from "rive/data";
import { BindableArtboard, RiveFile } from "rive/file";
import {
    COUNT, TILE_W, TILE_H, GAP, LABEL, MARGIN, TOP, WIDTH, HEIGHT, NAMES, GROUPS, PALETTES, FONT
} from "./gallery_data";

const KEY_ESCAPE: f64 = 256;
const DIM: u32 = 0x8C000000;      // 0xAARRGGBB
const BG: u32 = 0xFF0E0E12;
const WHITE: u32 = 0xFFFFFFFF;
const GREY: u32 = 0xFF8A8A96;
const FAINT: u32 = 0xFF4A4A56;
const BUTTON: u32 = 0xFF24242E;
const BUTTON_HI: u32 = 0xFF3A3A48;

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

class BoolSlot {
    prop: PropertyBoolean;
    last: i32 = -1;
    constructor(prop: PropertyBoolean) { this.prop = prop; }
    set(v: bool): void {
        let n = v ? 1 : 0;
        if (n != this.last) {
            this.last = n;
            this.prop.value = v;
        }
    }
}


class Button {
    x: f32 = 0; y: f32 = 0; w: f32 = 0; h: f32 = 0;
    label: string = "";
    hit(px: f32, py: f32): bool {
        return px >= this.x && px < this.x + this.w && py >= this.y && py < this.y + this.h;
    }
}

export class Gallery extends Layout {
    context: Context? = null;
    vm: ViewModel? = null;
    started: bool = false;
    demo: Array<DemoSwitch?> = new Array<DemoSwitch?>();
    // the window: a sample is decoded when its tile comes near, bound (made, running) when shown,
    // and released again when it scrolls far away; at most MAX_INFLIGHT decodes at a time
    files: Array<RiveFile?> = new Array<RiveFile?>();
    abs: Array<BindableArtboard?> = new Array<BindableArtboard?>();
    props: Array<PropertyArtboard?> = new Array<PropertyArtboard?>();
    state: StaticArray<i32> = new StaticArray<i32>(COUNT);   // 0 idle, 1 decoding, 2 decoded, 3 bound
    inflight: i32 = 0;
    xs: Array<NumberSlot?> = new Array<NumberSlot?>();
    ys: Array<NumberSlot?> = new Array<NumberSlot?>();
    os: Array<NumberSlot?> = new Array<NumberSlot?>();
    ps: Array<BoolSlot?> = new Array<BoolSlot?>();
    scaleSlot: NumberSlot? = null;
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
    seed: u32 = 2463534242;

    // the layout, from the size the window gives
    width: f32 = WIDTH;
    height: f32 = HEIGHT;
    cols: i32 = 3;
    single: bool = false;
    cur: i32 = 0;        // the sample shown in single mode
    scale: f32 = 1;      // tile scale: 1 in the grid; fitted (whole steps above 1) in single mode
    left: f32 = MARGIN;  // the grid's left edge (centred), or the single tile's
    top: f32 = TOP;      // where the first row (or the single tile) starts
    narrow: bool = false;
    compact: bool = false;  // single mode on a short screen (a phone in landscape): a one-line header
    tileTop: f32 = TOP;     // the single tile's top (centred vertically when there is room)
    ui: f32 = 3;         // pixel-font scale for labels
    prev: Button = new Button();
    rnd: Button = new Button();
    next: Button = new Button();
    stop: Button = new Button();

    override init(context: Context): bool {
        this.context = context;
        for (let i = 0; i < COUNT; i++) {
            this.demo.push(null);
            this.files.push(null);
            this.abs.push(null);
            this.props.push(null);
            this.xs.push(null);
            this.ys.push(null);
            this.os.push(null);
            this.ps.push(null);
        }
        this.prev.label = "< PREV";
        this.rnd.label = "RANDOM";
        this.next.label = "NEXT >";
        this.stop.label = "STOP";
        this.relayout();
        return true;
    }

    override resize(width: f64, height: f64, scale: f64): void {
        if (width <= 0 || height <= 0) {
            return;
        }
        // keep the same sample in view across a resize
        let keep = this.single ? this.cur : this.firstVisible();
        this.width = <f32>width;
        this.height = <f32>height;
        this.relayout();
        if (this.single) {
            this.cur = this.active >= 0 ? this.active : keep;
        } else {
            let row = <f64>(keep / this.cols) * <f64>this.rowPitch();
            this.target = Math.min(Math.max(row, 0), this.maxScroll());
            this.scroll = this.target;
        }
    }

    private firstVisible(): i32 {
        for (let i = 0; i < COUNT; i++) {
            if (this.tileY(i) + this.tileH() > this.top) {
                return i;
            }
        }
        return 0;
    }

    private relayout(): void {
        let avail = this.width - MARGIN * 2;
        let cols = <i32>Mathf.floor((avail + GAP) / (TILE_W + GAP));
        this.single = cols < 2;
        this.cols = cols < 1 ? 1 : cols;
        this.narrow = this.width < 1500;
        this.ui = this.width < 700 ? 2 : 3;
        if (this.single) {
            this.cols = 1;
            this.compact = this.height < 600;
            let m: f32 = this.width < 700 || this.compact ? 12 : MARGIN;
            this.top = this.compact ? 44 : (this.width < 700 ? 96 : TOP + 20);
            let btnH: f32 = this.compact ? 44 : (this.width < 700 ? 56 : 64);
            let label: f32 = this.compact ? 28 : LABEL;
            let below = label + 8 + btnH + m;
            let fw = (this.width - m * 2) / TILE_W;
            let fh = (this.height - this.top - below) / TILE_H;
            let s = Mathf.max(0.2, Mathf.min(fw, fh));
            this.scale = s >= 1 ? Mathf.floor(s) : s; // whole steps up keep the pixels even
            this.left = Mathf.floor((this.width - TILE_W * this.scale) * 0.5);
            // centre the tile, its label and the buttons in the room under the header
            let block = TILE_H * this.scale + below;
            let free = this.height - this.top - block;
            this.tileTop = this.top + (free > 0 ? Mathf.floor(free * 0.4) : 0);
            // the buttons, under the tile's label, as wide as the tile (at least 300)
            let bw = Mathf.max(TILE_W * this.scale, Mathf.min(this.width - m * 2, 300));
            let bx = Mathf.floor((this.width - bw) * 0.5);
            let by = this.tileTop + TILE_H * this.scale + label + 8;
            let gap: f32 = 8;
            let w3 = Mathf.floor((bw - gap * 2) / 3);
            this.prev.x = bx; this.prev.y = by; this.prev.w = w3; this.prev.h = btnH;
            this.rnd.x = bx + w3 + gap; this.rnd.y = by; this.rnd.w = w3; this.rnd.h = btnH;
            this.next.x = bx + (w3 + gap) * 2; this.next.y = by; this.next.w = w3; this.next.h = btnH;
            // STOP sits in the header's right corner while a sample is played
            let sw: f32 = this.width < 700 || this.compact ? 96 : 140;
            this.stop.w = sw; this.stop.h = this.compact ? 32 : (this.width < 700 ? 40 : 48);
            this.stop.x = this.width - m - sw; this.stop.y = this.compact ? 6 : 16;
        } else {
            this.compact = false;
            this.scale = 1;
            let gridW = <f32>this.cols * TILE_W + <f32>(this.cols - 1) * GAP;
            this.left = Mathf.floor((this.width - gridW) * 0.5);
            this.top = this.narrow ? TOP + 36 : TOP;
        }
        let s = this.scaleSlot;
        if (s != null) {
            s.set(<f64>this.scale);
        }
    }

    // The view model is bound after init: start decoding on the first advance that has it.
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
            let p = vm.getBoolean("p" + i.toString());
            if (x != null) { this.xs[i] = new NumberSlot(x); }
            if (y != null) { this.ys[i] = new NumberSlot(y); }
            if (o != null) { this.os[i] = new NumberSlot(o); }
            if (p != null) { this.ps[i] = new BoolSlot(p); }
            this.props[i] = vm.getArtboard("tile" + i.toString());
        }
    }

    async decode(context: Context, i: i32): Promise<void> {
        this.state[i] = 1;
        this.inflight++;
        let bytes = context.blob("s" + i.toString());
        if (bytes == null) {
            this.inflight--;
            this.state[i] = 0;
            return;
        }
        let file = await context.decodeFile(bytes);
        this.inflight--;
        if (this.state[i] != 1) {
            file.release(); // released while decoding: it scrolled away
            return;
        }
        this.files[i] = file;
        this.state[i] = 2;
    }

    // Binds a decoded sample to its tile: its artboard is made and starts running.
    private bind(i: i32): void {
        if (this.state[i] != 2) {
            return;
        }
        let file = this.files[i];
        let prop = this.props[i];
        if (file == null || prop == null) {
            return;
        }
        let ab = file.bindableArtboard();
        if (ab == null) {
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
        this.abs[i] = ab;
        this.state[i] = 3;
    }

    // Unbinds and frees a sample that scrolled far away (never the one being played).
    private release(i: i32): void {
        if (i == this.active || this.state[i] == 0) {
            return;
        }
        if (this.state[i] == 3) {
            let prop = this.props[i];
            if (prop != null) {
                prop.value = null;
            }
            let ab = this.abs[i];
            if (ab != null) {
                ab.release();
            }
            this.abs[i] = null;
            this.demo[i] = null;
        }
        let file = this.files[i];
        if (file != null) {
            file.release();
        }
        this.files[i] = null;
        this.state[i] = 0; // a decode still running sees this and drops its result
    }

    // How far a tile is from the view: 0 shown, 1 the next row (or the next sample), and so on.
    private distance(i: i32): i32 {
        if (this.single) {
            let d = i - this.cur;
            if (d < 0) {
                d = -d;
            }
            return d < COUNT - d ? d : COUNT - d;
        }
        let pitch = this.rowPitch();
        let y = this.tileY(i);
        let h = this.tileH();
        if (y + h <= 0) {
            return <i32>Mathf.ceil((-(y + h)) / pitch) + 1;
        }
        if (y >= this.height) {
            return <i32>Mathf.ceil((y - this.height) / pitch) + 1;
        }
        return 0;
    }

    // --- layout

    private tileW(): f32 { return TILE_W * this.scale; }
    private tileH(): f32 { return TILE_H * this.scale; }
    private rowPitch(): f32 { return this.tileH() + LABEL + GAP; }

    private rows(): i32 {
        return (COUNT + this.cols - 1) / this.cols;
    }

    private maxScroll(): f64 {
        if (this.single) {
            return 0;
        }
        let content = <f64>this.top + <f64>this.rows() * <f64>this.rowPitch() - <f64>GAP + <f64>MARGIN;
        return Math.max(0, content - <f64>this.height);
    }

    private tileX(i: i32): f32 {
        if (this.single) {
            return i == this.cur ? this.left : -100000;
        }
        return this.left + <f32>(i % this.cols) * (this.tileW() + GAP);
    }

    private tileY(i: i32): f32 {
        if (this.single) {
            return i == this.cur ? this.tileTop : -100000;
        }
        return this.top + <f32>(i / this.cols) * this.rowPitch() - <f32>Math.round(this.scroll);
    }

    private visible(i: i32): bool {
        if (this.single) {
            return i == this.cur;
        }
        let ty = this.tileY(i);
        return ty + this.tileH() > 0 && ty < this.height;
    }

    private tileAt(x: f32, y: f32): i32 {
        if (y < this.top - 16 && !this.single) {
            return -1; // the header covers what scrolls under it
        }
        let w = this.tileW(), h = this.tileH();
        for (let i = 0; i < COUNT; i++) {
            if (!this.visible(i)) {
                continue;
            }
            let tx = this.tileX(i), ty = this.tileY(i);
            if (x >= tx && x < tx + w && y >= ty && y < ty + h) {
                return i;
            }
        }
        return -1;
    }

    // --- activation and navigation

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
        if (i >= 0 && !this.single) {
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

    private go(i: i32): void {
        this.activate(-1);
        this.cur = ((i % COUNT) + COUNT) % COUNT;
    }

    private random(): i32 {
        this.seed ^= this.seed << 13;
        this.seed ^= this.seed >> 17;
        this.seed ^= this.seed << 5;
        let n = <i32>(this.seed % <u32>(COUNT - 1));
        return (this.cur + 1 + n) % COUNT; // never the one shown
    }

    override advance(seconds: f64): bool {
        this.begin();
        this.seed += 1;
        this.scroll += (this.target - this.scroll) * Math.min(1, seconds * 14);
        if (Math.abs(this.target - this.scroll) < 0.5) {
            this.scroll = this.target;
        }
        // the window: start one decode a frame (shown tiles first, then their neighbours), bind
        // what is shown, release what is far
        let context = this.context;
        if (this.started && context != null) {
            let started = false;
            for (let pass = 0; pass < 2 && !started; pass++) {
                for (let i = 0; i < COUNT && !started; i++) {
                    if (this.state[i] == 0 && this.inflight < 2 && this.distance(i) <= pass) {
                        this.decode(context, i);
                        started = true;
                    }
                }
            }
            for (let i = 0; i < COUNT; i++) {
                let d = this.distance(i);
                if (d == 0) {
                    this.bind(i);
                } else if (d >= 3) {
                    this.release(i);
                }
            }
        }
        for (let i = 0; i < COUNT; i++) {
            let x = this.xs[i], y = this.ys[i], o = this.os[i], p = this.ps[i];
            let vis = this.visible(i);
            if (x != null) { x.set(<f64>this.tileX(i)); }
            if (y != null) { y.set(<f64>this.tileY(i)); }
            // out of sight: hidden (no GPU passes) and paused (no game logic)
            if (o != null) { o.set(vis ? 1 : 0); }
            if (p != null) { p.set(!vis); }
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
        let dx = event.position.x - this.downX;
        let dy = event.position.y - this.downY;
        if (this.single) {
            if (!this.dragging && Mathf.abs(dx) > 12) {
                this.dragging = true; // a swipe: decided on release
            }
            if (this.dragging) {
                event.hit();
            }
            return;
        }
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
        let x = event.position.x, y = event.position.y;
        if (this.single) {
            let wasDrag = this.dragging;
            this.dragging = false;
            let downOnActive = this.active >= 0 && this.tileAt(this.downX, this.downY) == this.active;
            if (wasDrag && !downOnActive) {
                let dx = x - this.downX;
                if (Mathf.abs(dx) > 60 && Mathf.abs(dx) > Mathf.abs(y - this.downY)) {
                    this.go(dx < 0 ? this.cur + 1 : this.cur - 1);
                }
                return;
            }
            if (this.active >= 0 && this.stop.hit(x, y) && this.stop.hit(this.downX, this.downY)) {
                this.activate(-1);
                return;
            }
            if (this.prev.hit(x, y) && this.prev.hit(this.downX, this.downY)) {
                this.go(this.cur - 1);
                return;
            }
            if (this.rnd.hit(x, y) && this.rnd.hit(this.downX, this.downY)) {
                this.go(this.random());
                return;
            }
            if (this.next.hit(x, y) && this.next.hit(this.downX, this.downY)) {
                this.go(this.cur + 1);
                return;
            }
        } else if (this.dragging) {
            this.dragging = false;
            return;
        }
        // activate on release, so the game never sees half of the click that woke it
        let t = this.tileAt(x, y);
        if (t >= 0 && t != this.active) {
            this.activate(t);
        }
    }

    override pointerScroll(event: ScrollEvent): void {
        if (this.single) {
            return;
        }
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

    // --- drawing: covers, dimming, the active border, labels, the header, the buttons

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

    private button(renderer: Renderer, b: Button, hot: bool): void {
        this.rect(renderer, b.x, b.y, b.w, b.h, hot ? BUTTON_HI : BUTTON);
        let s: f32 = b.h >= 60 ? 4 : 3;
        let tw = this.textWidth(b.label, s);
        this.text(renderer, b.x + Mathf.floor((b.w - tw) * 0.5), b.y + Mathf.floor((b.h - s * 5) * 0.5), b.label, WHITE, s);
    }

    private drawTile(renderer: Renderer, i: i32): void {
        let tw = this.tileW(), th = this.tileH();
        let x = this.tileX(i), y = this.tileY(i);
        let ls = this.ui;
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
            if (this.single && (this.state[i] == 3)) {
                let hint = "TAP TO PLAY";
                let hs: f32 = Mathf.max(2, Mathf.min(4, Mathf.floor(th / 60)));
                let hw = this.textWidth(hint, hs);
                let hx = x + Mathf.floor((tw - hw) * 0.5), hy = y + Mathf.floor(th * 0.5 - hs * 2.5);
                this.rect(renderer, hx - hs * 2, hy - hs * 2, hw + hs * 4, hs * 9, 0xC0000000);
                this.text(renderer, hx, hy, hint, WHITE, hs);
            }
        }
        if (!(this.state[i] == 3)) {
            let ld = "LOADING";
            this.text(renderer, x + Mathf.floor((tw - this.textWidth(ld, ls)) * 0.5), y + Mathf.floor(th * 0.5), ld, GREY, ls);
        }
        let name = NAMES[i].replaceAll("-", " ");
        if (this.single) {
            name = (i + 1).toString() + "/" + COUNT.toString() + "  " + name;
        }
        let ly = y + th + (this.compact ? 8 : 14);
        if (this.compact) {
            ls = 2;
        }
        this.text(renderer, x, ly, name, i == this.active ? WHITE : GREY, ls);
        let pal = PALETTES[i];
        if (this.textWidth(name, ls) + this.textWidth(pal, ls) + 24 < tw) {
            this.text(renderer, x + tw - this.textWidth(pal, ls), ly, pal, FAINT, ls);
        }
    }

    override draw(renderer: Renderer): void {
        let th = this.tileH();
        if (this.single) {
            this.drawTile(renderer, this.cur);
        } else {
            for (let i = 0; i < COUNT; i++) {
                let y = this.tileY(i);
                if (y + th + LABEL < 0 || y > this.height) {
                    continue;
                }
                this.drawTile(renderer, i);
            }
        }
        // the header, over whatever scrolls under it
        let w = this.width;
        if (this.compact) {
            // one line: title, counts, BUILT WITH RIVE
            this.rect(renderer, 0, 0, w, this.top - 8, BG);
            this.text(renderer, 12, 12, "PIXEL SPLAT SAMPLES", WHITE, 3);
            let g = 0;
            for (let i = 0; i < COUNT; i++) {
                if (GROUPS[i] == "games") {
                    g++;
                }
            }
            let cinfo = (COUNT - g).toString() + " DIORAMAS  " + g.toString() + " GAMES";
            let cx = 12 + this.textWidth("PIXEL SPLAT SAMPLES", 3) + 18;
            this.text(renderer, cx, 16, cinfo, GREY, 2);
            let bx2 = cx + this.textWidth(cinfo, 2) + 12;
            if (bx2 + this.textWidth("BUILT WITH RIVE", 2) < this.stop.x - 8 || this.active < 0) {
                this.text(renderer, bx2, 16, "BUILT WITH RIVE", WHITE, 2);
            }
            this.button(renderer, this.prev, false);
            this.button(renderer, this.rnd, false);
            this.button(renderer, this.next, false);
            if (this.active >= 0) {
                this.button(renderer, this.stop, true);
            }
            return;
        }
        let titleScale: f32 = w < 700 ? 4 : 7;
        let sub: f32 = w < 700 ? 2 : 3;
        let lx: f32 = this.single ? (w < 700 ? <f32>12 : MARGIN) : (this.left < MARGIN ? MARGIN : this.left);
        let ty: f32 = this.single && w < 700 ? 16 : 40;
        this.rect(renderer, 0, 0, w, this.top - 16, BG);
        this.text(renderer, lx, ty, "PIXEL SPLAT SAMPLES", WHITE, titleScale);
        let games = 0;
        for (let i = 0; i < COUNT; i++) {
            if (GROUPS[i] == "games") {
                games++;
            }
        }
        let info = (COUNT - games).toString() + " DIORAMAS  " + games.toString() + " GAMES";
        let iy: f32 = ty + titleScale * 5 + (w < 700 ? 10 : 16);
        this.text(renderer, lx, iy, info, GREY, sub);
        let built = "BUILT WITH RIVE";
        let bx = lx + this.textWidth(info, sub) + sub * 6;
        this.text(renderer, bx, iy, built, WHITE, sub);
        if (this.single) {
            // the buttons; STOP while a sample is played
            this.button(renderer, this.prev, false);
            this.button(renderer, this.rnd, false);
            this.button(renderer, this.next, false);
            if (this.active >= 0) {
                this.button(renderer, this.stop, true);
            } else if (w >= 700) {
                let hint = "TAP THE SAMPLE TO PLAY  -  SWIPE OR USE THE BUTTONS";
                this.text(renderer, lx, iy + sub * 5 + 12, hint, GREY, sub);
            }
            return;
        }
        let hint = this.active >= 0 ? "ESC: BACK TO THE GALLERY" : "CLICK A SAMPLE TO PLAY IT   SCROLL FOR MORE";
        let hc = this.active >= 0 ? WHITE : GREY;
        let rx = (this.left < MARGIN ? MARGIN : this.left) + <f32>this.cols * this.tileW() + <f32>(this.cols - 1) * GAP;
        if (this.narrow) {
            this.text(renderer, lx, iy + sub * 5 + 12, hint, hc, sub);
        } else {
            this.text(renderer, rx - this.textWidth(hint, sub), iy, hint, hc, sub);
        }
    }
}
