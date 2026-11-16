// A pixel-art gaussian-splat scene: loads a blob baked by splat_bake.py and
// draws it in three GPU passes into a small canvas, shown with nearest pixels.
//
//   shadow   splats seen from the sun -> depth (optional)
//   gbuffer  splats seen from the camera -> palette indices + depth, at 2x the art grid
//   resolve  2x2 vote, silhouette ink, dithered fog and sky -> the art grid (W x H)
//   blit     the art grid scaled by `pixelSize` with a nearest sampler
//
// Inputs come from the scene (ScriptInput* in RML; the defaults below otherwise)
// and every one can be overridden at launch with `--arg name=value` (applyArgs),
// which is how golden.py renders turntables without editing the scene.
import { Layout, Context } from "rive/host";
import { PointerEvent, ScrollEvent } from "rive/events";
import { Renderer } from "rive/renderer";
import { ImageSampler, ImageWrap, ImageFilter } from "rive/image";
import { BlendMode } from "rive/paint";
import { Mat2D } from "rive/mat2d";
import { Mat4 } from "rive/mat4";
import { Path } from "rive/path";
import { Paint, PaintStyle } from "rive/paint";
import { Color } from "rive/color";
import { Vector } from "rive/vector";
import { Audio, AudioHandle } from "rive/audio";
import { Ring } from "rive/shared";
import { SfxEvent, SfxSynth } from "./sfx";
import { Game } from "./game";
import { GameApi, POINTER_DOWN, POINTER_MOVE, POINTER_UP } from "./game_api";
import {
    GPUBindGroup, GPUBindGroupTexture, GPUBindGroupUBO, GPUBuffer, GPUCanvas,
    GPUColorAttachment, GPUColorTargetDesc, GPUDepthStencilDesc, GPUPassDesc,
    GPUPipeline, GPUPipelineDesc, GPUShaderModule, GPUTexture,
    GPUTextureDesc, GPUTextureView, GPUTextureViewDesc, GPUVertexAttribute,
    GPUVertexBufferLayout,
} from "rive/gpu";
import {
    BufferUsage, CompareFunction, LoadOp, StoreOp, TextureAspect, TextureFormat,
    VertexFormat, VertexStepMode,
} from "rive/gpu_enums";

const HEADER: u32 = 672;   // blob v3: 640 bytes of header + 32 of dequantization (splat_bake.py)
const STRIDE: u32 = 16;
const MAX_BONES: i32 = 64;
const BONE_BYTES: i32 = 48;   // 3 rows of vec4
const FRAME_BYTES: i32 = 1520;
const LOOK_BYTES: i32 = 2256;

export class SplatScene extends Layout {
    // --- what to draw
    @input blobName: string = "splats";
    // --- the pixel grid
    @input pixelSize: f64 = 4;       // screen points per art pixel
    @input orthoHeight: f64 = 0;     // world units the view shows vertically; 0 = fit the scene
    @input perspective: bool = false;
    @input fov: f64 = 35;            // degrees, perspective only
    // --- the camera. Orbit (default): yaw, pitch and distance around the target. Look-at
    // (lookAt true): from eye to target, for a camera a game drives (follow, side view,
    // top-down, first or third person) through bound inputs. Both snap to the art grid when
    // orthographic, so a moving camera slides by whole pixels.
    @input lookAt: bool = false;
    @input eyeX: f64 = 0;
    @input eyeY: f64 = 3;
    @input eyeZ: f64 = 10;
    @input yaw: f64 = 35;            // degrees (orbit)
    @input pitch: f64 = 30;          // degrees above the horizon (orbit)
    @input distance: f64 = 0;        // orbit distance; 0 = from the scene's size
    @input spin: f64 = 0;            // orbit: degrees per second
    @input targetX: f64 = 0;
    @input targetY: f64 = 0;
    @input targetZ: f64 = 0;
    @input useTarget: bool = false;  // orbit: false = the centre of the bounds (look-at always uses it)
    // --- light and shade
    @input sunYaw: f64 = -40;
    @input sunPitch: f64 = 40;
    @input keyLight: f64 = 0.45;      // direct light below which a surface steps DOWN its ramp
    @input highlight: f64 = 0.8;     // direct light above which it steps UP (faces the sun)
    @input shadeSteps: f64 = 1.5;    // ramp steps down in full shade
    @input lightSteps: f64 = 1;      // ramp steps up in full sun
    @input bandDither: f64 = 0.35;   // 0 hard bands .. 1 a full ordered gradient
    @input shadows: bool = true;
    @input shadowSize: f64 = 1024;
    @input shadowOffset: f64 = 1.5;  // receiver pushed along its normal, in splat spacings (acne)
    @input shadowBias: f64 = 0.5;    // depth bias, in splat spacings
    // --- the splats
    @input splatScale: f64 = 1;
    @input threshold: f64 = 0.5;     // gaussian alpha test
    @input flatness: f64 = 0.3;
    @input jitter: f64 = 0;          // random tone per splat, in ramp steps (painterly mottling)
    @input splatDither: bool = true; // band edges dithered per splat (world-stable) instead of Bayer
    // --- the resolve
    @input ink: f64 = 1;             // outline: steps down its own ramp, 0 = none
    @input edgeDepth: f64 = 0.4;     // world units of depth that count as an outline
    @input fogStart: f64 = 0;        // world units behind the orbit target where fog begins (negative: in front)
    @input fogEnd: f64 = 0;          // ... where it reaches fogMax; 0 = 1.5 x the scene's radius
    @input fogMax: f64 = 0;          // 0 = no fog
    @input minCoverage: f64 = 2;     // samples of 4 a pixel needs to be drawn
    @input horizon: f64 = 0.55;
    @input skyBlend: f64 = 0.12;
    @input windAmp: f64 = 0.03;
    @input windFreq: f64 = 1.5;
    @input debug: f64 = 0;           // 1 vote only, 2 depth
    @input maskSky: bool = false;    // paint the sky pure magenta (in no palette): clean masks for golden.py
    // --- animation (tracks baked by splat_bake.py)
    @input animate: bool = true;
    @input animSpeed: f64 = 1;
    // --- pointer orbit, a preview convenience (off by default: a game handles its own input):
    // drag to turn and tilt, wheel / trackpad to zoom
    @input orbit: bool = false;
    @input orbitSpeed: f64 = 0.35;   // degrees per point dragged
    @input pitchMin: f64 = 5;
    @input pitchMax: f64 = 85;
    @input zoomMin: f64 = 0.4;       // view size factor, smaller = closer
    @input zoomMax: f64 = 2.5;
    // --- a turntable for captures (asset reviews, videos): `tourLoops` turns around the target in
    // `tour` seconds, eased in and out (0 = off); orbit camera only, set with --arg
    // --- the shader FX hook on splats flagged `fx` (splat_bake.py): `fxApply` in splat.wgsl gets
    // the time in a `fxPeriod` loop, the FX splats' bounds and two ramp ids to recolour with
    // (fxRampA, fxRampB; -1 = none). The template's fxApply does nothing: write your effect there.
    @input fx: bool = true;
    @input fxPeriod: f64 = 12;
    // the FX clock: shifted by fxOffset seconds, and frozen from scene time fxStopAt on (0: never), to
    // start a cycle mid-way or end a capture on a chosen state
    @input fxOffset: f64 = 0;
    @input fxStopAt: f64 = 0;
    @input fxRampA: f64 = -1;
    @input fxRampB: f64 = -1;
    // demo mode (gallery tiles, video captures): a game plays itself and ignores the pointer; a
    // diorama turns at demoSpin degrees a second. Bound to the Sample view model's `demo`
    @input demo: bool = false;
    // the game's sound effects (sfx.as): never in demo mode
    @input sound: bool = true;
    @input soundVolume: f64 = 0.6;
    @input demoSpin: f64 = 12;
    @input tour: f64 = 0;
    @input tourLoops: f64 = 2;
    // a continuous turntable shared by several captures (a reel with transitions): tourRate degrees a
    // second on a timeline `tourLength` s long that eases in over the first `tourEase` s and out over the
    // last; this capture's time 0 sits at `tourOffset` on it, so consecutive scenes turn in step
    @input tourRate: f64 = 0;
    @input tourOffset: f64 = 0;
    @input tourLength: f64 = 0;
    @input tourEase: f64 = 1.5;

    context: Context? = null;
    ready: bool = false;
    count: u32 = 0;
    spacing: f32 = 0.05;
    fxCount: i32 = 0;
    fxBox: StaticArray<f32> = new StaticArray<f32>(4);
    quant: StaticArray<f32> = new StaticArray<f32>(8);   // box min xyz, sigma min, box step xyz, sigma step
    time: f64 = 0;
    spinTime: f64 = 0;
    argsReapplied: bool = false;
    game: Game = new Game();
    api: GameApi = new GameApi();
    started: bool = false;
    demoYaw: f64 = 0;
    sfxRing: Ring<SfxEvent>? = null;
    sfxHandle: AudioHandle? = null;
    sfxStarts: i32 = 0;
    sfxEvent: SfxEvent = new SfxEvent();
    gameBones: ArrayBuffer = new ArrayBuffer(MAX_BONES * BONE_BYTES);
    hudPath: Path = new Path();
    hudPaint: Paint = new Paint();               // the auto spin's clock: it holds while the pointer drags
    dragging: bool = false;
    dragId: f64 = -1;
    lastX: f32 = 0;
    lastY: f32 = 0;
    userYaw: f64 = 0;                // degrees the pointer added
    userPitch: f64 = 0;
    yawVelocity: f64 = 0;            // degrees per second, for the throw after release
    pitchVelocity: f64 = 0;
    zoom: f64 = 1;
    width: f64 = 0;
    height: f64 = 0;
    artW: u32 = 0;
    artH: u32 = 0;
    blitX: f32 = 0;
    blitY: f32 = 0;

    boundsMin: StaticArray<f32> = new StaticArray<f32>(3);
    boundsMax: StaticArray<f32> = new StaticArray<f32>(3);
    roles: StaticArray<u32> = new StaticArray<u32>(4);
    palette: StaticArray<u32> = new StaticArray<u32>(64);
    ramps: StaticArray<u32> = new StaticArray<u32>(256);
    rampLen: StaticArray<u32> = new StaticArray<u32>(32);

    splats: GPUBuffer? = null;
    blob: ArrayBuffer = new ArrayBuffer(0);
    boneCount: i32 = 1;
    trackCount: i32 = 0;
    trackFirst: StaticArray<i32> = new StaticArray<i32>(64);
    trackBones: StaticArray<i32> = new StaticArray<i32>(64);
    trackFrames: StaticArray<i32> = new StaticArray<i32>(64);
    trackFps: StaticArray<f64> = new StaticArray<f64>(64);
    trackPhase: StaticArray<f64> = new StaticArray<f64>(64);
    trackSpeed: StaticArray<f64> = new StaticArray<f64>(64);
    trackData: StaticArray<i32> = new StaticArray<i32>(64);
    trackShown: StaticArray<i32> = new StaticArray<i32>(64);
    bonesUBO: GPUBuffer? = null;
    frameUBO: GPUBuffer? = null;
    shadowUBO: GPUBuffer? = null;
    lookUBO: GPUBuffer? = null;
    frameData: ArrayBuffer = new ArrayBuffer(FRAME_BYTES);
    shadowData: ArrayBuffer = new ArrayBuffer(FRAME_BYTES);
    lookData: ArrayBuffer = new ArrayBuffer(LOOK_BYTES);

    splatShader: GPUShaderModule? = null;
    resolveShader: GPUShaderModule? = null;
    gbufPipe: GPUPipeline? = null;
    shadowPipe: GPUPipeline? = null;
    resolvePipe: GPUPipeline? = null;

    canvas: GPUCanvas? = null;
    gbuf: GPUTexture? = null;
    gbufView: GPUTextureView? = null;
    depth: GPUTexture? = null;
    depthView: GPUTextureView? = null;
    depthRead: GPUTextureView? = null;
    shadowTex: GPUTexture? = null;
    shadowView: GPUTextureView? = null;
    shadowRead: GPUTextureView? = null;
    frameGroup: GPUBindGroup? = null;
    shadowMapGroup: GPUBindGroup? = null;
    shadowGroup: GPUBindGroup? = null;
    resolveGroup: GPUBindGroup? = null;
    sampler: ImageSampler = ImageSampler(ImageWrap.clamp, ImageWrap.clamp, ImageFilter.nearest);

    override init(context: Context): bool {
        this.context = context;
        this.applyArgs(context);
        let blob = context.blob(this.blobName);
        if (blob == null) {
            context.log("splat_scene: no blob named " + this.blobName);
            return false;
        }
        if (!this.readHeader(blob)) {
            return false;
        }
        let splats = new GPUBuffer(BufferUsage.vertex, this.count * STRIDE);
        splats.update(0, blob, this.count * STRIDE, HEADER);
        this.splats = splats;
        this.blob = blob; // kept: animation frames are copied from it into the bone buffer
        // every bone starts as identity; tracks overwrite theirs each frame
        let identity = new ArrayBuffer(MAX_BONES * BONE_BYTES);
        let f = Float32Array.wrap(identity);
        for (let b = 0; b < MAX_BONES; b++) {
            f[b * 12] = 1;
            f[b * 12 + 5] = 1;
            f[b * 12 + 10] = 1;
        }
        let bones = new GPUBuffer(BufferUsage.uniform, <u32>(MAX_BONES * BONE_BYTES), identity);
        this.bonesUBO = bones;
        for (let t = 0; t < this.trackCount; t++) {
            this.trackShown[t] = -1;
        }
        this.splatShader = context.shader("splat");
        this.resolveShader = context.shader("resolve");
        if (this.splatShader == null || this.resolveShader == null) {
            context.log("splat_scene: shaders 'splat' and 'resolve' are missing");
            return false;
        }
        this.frameUBO = new GPUBuffer(BufferUsage.uniform, <u32>FRAME_BYTES);
        this.shadowUBO = new GPUBuffer(BufferUsage.uniform, <u32>FRAME_BYTES);
        this.lookUBO = new GPUBuffer(BufferUsage.uniform, <u32>LOOK_BYTES);
        this.canvas = context.gpuCanvas();
        this.buildPipelines();
        context.log("splat_scene: " + this.count.toString() + " splats");
        return true;
    }

    // `rive . --screenshot --arg yaw=90 --arg blobName=tree`: every input can be
    // overridden from the command line, for turntables, goldens and comparisons
    private applyArgs(context: Context): void {
        let name = context.arg("blobName");
        if (name != null) { this.blobName = name; }
        let a_pixelSize = context.arg("pixelSize");
        if (a_pixelSize != null) { this.pixelSize = parseFloat(a_pixelSize); }
        let a_orthoHeight = context.arg("orthoHeight");
        if (a_orthoHeight != null) { this.orthoHeight = parseFloat(a_orthoHeight); }
        let a_fov = context.arg("fov");
        if (a_fov != null) { this.fov = parseFloat(a_fov); }
        let a_yaw = context.arg("yaw");
        if (a_yaw != null) { this.yaw = parseFloat(a_yaw); }
        let a_pitch = context.arg("pitch");
        if (a_pitch != null) { this.pitch = parseFloat(a_pitch); }
        let a_distance = context.arg("distance");
        if (a_distance != null) { this.distance = parseFloat(a_distance); }
        let a_spin = context.arg("spin");
        if (a_spin != null) { this.spin = parseFloat(a_spin); }
        let a_targetX = context.arg("targetX");
        if (a_targetX != null) { this.targetX = parseFloat(a_targetX); }
        let a_targetY = context.arg("targetY");
        if (a_targetY != null) { this.targetY = parseFloat(a_targetY); }
        let a_targetZ = context.arg("targetZ");
        if (a_targetZ != null) { this.targetZ = parseFloat(a_targetZ); }
        let a_sunYaw = context.arg("sunYaw");
        if (a_sunYaw != null) { this.sunYaw = parseFloat(a_sunYaw); }
        let a_sunPitch = context.arg("sunPitch");
        if (a_sunPitch != null) { this.sunPitch = parseFloat(a_sunPitch); }
        let a_highlight = context.arg("highlight");
        if (a_highlight != null) { this.highlight = parseFloat(a_highlight); }
        let a_keyLight = context.arg("keyLight");
        if (a_keyLight != null) { this.keyLight = parseFloat(a_keyLight); }
        let a_shadeSteps = context.arg("shadeSteps");
        if (a_shadeSteps != null) { this.shadeSteps = parseFloat(a_shadeSteps); }
        let a_lightSteps = context.arg("lightSteps");
        if (a_lightSteps != null) { this.lightSteps = parseFloat(a_lightSteps); }
        let a_bandDither = context.arg("bandDither");
        if (a_bandDither != null) { this.bandDither = parseFloat(a_bandDither); }
        let a_shadowOffset = context.arg("shadowOffset");
        if (a_shadowOffset != null) { this.shadowOffset = parseFloat(a_shadowOffset); }
        let a_shadowBias = context.arg("shadowBias");
        if (a_shadowBias != null) { this.shadowBias = parseFloat(a_shadowBias); }
        let a_shadowSize = context.arg("shadowSize");
        if (a_shadowSize != null) { this.shadowSize = parseFloat(a_shadowSize); }
        let a_splatScale = context.arg("splatScale");
        if (a_splatScale != null) { this.splatScale = parseFloat(a_splatScale); }
        let a_threshold = context.arg("threshold");
        if (a_threshold != null) { this.threshold = parseFloat(a_threshold); }
        let a_jitter = context.arg("jitter");
        if (a_jitter != null) { this.jitter = parseFloat(a_jitter); }
        let a_splatDither = context.arg("splatDither");
        if (a_splatDither != null) { this.splatDither = a_splatDither == "1" || a_splatDither == "true"; }
        let a_flatness = context.arg("flatness");
        if (a_flatness != null) { this.flatness = parseFloat(a_flatness); }
        let a_ink = context.arg("ink");
        if (a_ink != null) { this.ink = parseFloat(a_ink); }
        let a_edgeDepth = context.arg("edgeDepth");
        if (a_edgeDepth != null) { this.edgeDepth = parseFloat(a_edgeDepth); }
        let a_fogStart = context.arg("fogStart");
        if (a_fogStart != null) { this.fogStart = parseFloat(a_fogStart); }
        let a_fogEnd = context.arg("fogEnd");
        if (a_fogEnd != null) { this.fogEnd = parseFloat(a_fogEnd); }
        let a_fogMax = context.arg("fogMax");
        if (a_fogMax != null) { this.fogMax = parseFloat(a_fogMax); }
        let a_minCoverage = context.arg("minCoverage");
        if (a_minCoverage != null) { this.minCoverage = parseFloat(a_minCoverage); }
        let a_horizon = context.arg("horizon");
        if (a_horizon != null) { this.horizon = parseFloat(a_horizon); }
        let a_skyBlend = context.arg("skyBlend");
        if (a_skyBlend != null) { this.skyBlend = parseFloat(a_skyBlend); }
        let a_windAmp = context.arg("windAmp");
        if (a_windAmp != null) { this.windAmp = parseFloat(a_windAmp); }
        let a_windFreq = context.arg("windFreq");
        if (a_windFreq != null) { this.windFreq = parseFloat(a_windFreq); }
        let a_animate = context.arg("animate");
        if (a_animate != null) { this.animate = a_animate == "1" || a_animate == "true"; }
        let a_animSpeed = context.arg("animSpeed");
        if (a_animSpeed != null) { this.animSpeed = parseFloat(a_animSpeed); }
        let a_orbit = context.arg("orbit");
        if (a_orbit != null) { this.orbit = a_orbit == "1" || a_orbit == "true"; }
        let a_orbitSpeed = context.arg("orbitSpeed");
        if (a_orbitSpeed != null) { this.orbitSpeed = parseFloat(a_orbitSpeed); }
        let a_zoom = context.arg("zoom");
        if (a_zoom != null) { this.zoom = parseFloat(a_zoom); }
        let a_maskSky = context.arg("maskSky");
        if (a_maskSky != null) { this.maskSky = a_maskSky == "1" || a_maskSky == "true"; }
        let a_tour = context.arg("tour");
        if (a_tour != null) { this.tour = parseFloat(a_tour); }
        let a_pitchMin = context.arg("pitchMin");
        if (a_pitchMin != null) { this.pitchMin = parseFloat(a_pitchMin); }
        let a_pitchMax = context.arg("pitchMax");
        if (a_pitchMax != null) { this.pitchMax = parseFloat(a_pitchMax); }
        let a_demo = context.arg("demo");
        if (a_demo != null) { this.demo = a_demo == "true" || a_demo == "1"; }
        let a_demoSpin = context.arg("demoSpin");
        if (a_demoSpin != null) { this.demoSpin = parseFloat(a_demoSpin); }
        let a_tourRate = context.arg("tourRate");
        if (a_tourRate != null) { this.tourRate = parseFloat(a_tourRate); }
        let a_tourOffset = context.arg("tourOffset");
        if (a_tourOffset != null) { this.tourOffset = parseFloat(a_tourOffset); }
        let a_tourLength = context.arg("tourLength");
        if (a_tourLength != null) { this.tourLength = parseFloat(a_tourLength); }
        let a_tourEase = context.arg("tourEase");
        if (a_tourEase != null) { this.tourEase = parseFloat(a_tourEase); }
        let a_tourLoops = context.arg("tourLoops");
        if (a_tourLoops != null) { this.tourLoops = parseFloat(a_tourLoops); }
        let a_fx = context.arg("fx");
        if (a_fx != null) { this.fx = a_fx == "1" || a_fx == "true"; }
        let a_fxOffset = context.arg("fxOffset");
        if (a_fxOffset != null) { this.fxOffset = parseFloat(a_fxOffset); }
        let a_fxStopAt = context.arg("fxStopAt");
        if (a_fxStopAt != null) { this.fxStopAt = parseFloat(a_fxStopAt); }
        let a_fxPeriod = context.arg("fxPeriod");
        if (a_fxPeriod != null) { this.fxPeriod = parseFloat(a_fxPeriod); }
        let a_fxRampA = context.arg("fxRampA");
        if (a_fxRampA != null) { this.fxRampA = parseFloat(a_fxRampA); }
        let a_fxRampB = context.arg("fxRampB");
        if (a_fxRampB != null) { this.fxRampB = parseFloat(a_fxRampB); }
        let a_lookAt = context.arg("lookAt");
        if (a_lookAt != null) { this.lookAt = a_lookAt == "1" || a_lookAt == "true"; }
        let a_eyeX = context.arg("eyeX");
        if (a_eyeX != null) { this.eyeX = parseFloat(a_eyeX); }
        let a_eyeY = context.arg("eyeY");
        if (a_eyeY != null) { this.eyeY = parseFloat(a_eyeY); }
        let a_eyeZ = context.arg("eyeZ");
        if (a_eyeZ != null) { this.eyeZ = parseFloat(a_eyeZ); }
        let a_debug = context.arg("debug");
        if (a_debug != null) { this.debug = parseFloat(a_debug); }
        let a_time = context.arg("time");
        if (a_time != null) { this.time = parseFloat(a_time); }
        let a_perspective = context.arg("perspective");
        if (a_perspective != null) { this.perspective = a_perspective == "1" || a_perspective == "true"; }
        let a_useTarget = context.arg("useTarget");
        if (a_useTarget != null) { this.useTarget = a_useTarget == "1" || a_useTarget == "true"; }
        let a_shadows = context.arg("shadows");
        if (a_shadows != null) { this.shadows = a_shadows == "1" || a_shadows == "true"; }
    }

    private readHeader(blob: ArrayBuffer): bool {
        let v = new DataView(blob);
        if (blob.byteLength < <i32>HEADER || v.getUint32(0, true) != 0x544C5053) {
            this.context!.log("splat_scene: not a SPLT blob");
            return false;
        }
        if (v.getUint32(4, true) != 3) {
            this.context!.log("splat_scene: blob version " + v.getUint32(4, true).toString() + ", this renderer reads 3: re-bake it, or `splat_bake.py --upgrade` it");
            return false;
        }
        this.count = v.getUint32(8, true);
        this.spacing = Mathf.max(v.getFloat32(40, true), 1e-4);
        if (blob.byteLength < <i32>(HEADER + this.count * STRIDE)) {
            this.context!.log("splat_scene: blob is truncated");
            return false;
        }
        for (let i = 0; i < 3; i++) {
            this.boundsMin[i] = v.getFloat32(16 + i * 4, true);
            this.boundsMax[i] = v.getFloat32(28 + i * 4, true);
        }
        for (let i = 0; i < 4; i++) {
            this.roles[i] = v.getUint8(52 + i);
        }
        for (let i = 0; i < 64; i++) {
            this.palette[i] = v.getUint32(64 + i * 4, true);
        }
        for (let i = 0; i < 256; i++) {
            this.ramps[i] = v.getUint8(320 + i);
        }
        for (let i = 0; i < 32; i++) {
            this.rampLen[i] = v.getUint8(576 + i);
        }
        // dequantization: positions and sigma (16-byte splats)
        let q = this.quant;
        q[0] = v.getFloat32(640, true); q[1] = v.getFloat32(644, true); q[2] = v.getFloat32(648, true);
        q[4] = v.getFloat32(652, true); q[5] = v.getFloat32(656, true); q[6] = v.getFloat32(660, true);
        q[3] = v.getFloat32(664, true); q[7] = v.getFloat32(668, true);
        // the FX splats' bounds (x, y at rest), for the effects' left-right and bottom-top
        let minX: f32 = 1e9, maxX: f32 = -1e9, minY: f32 = 1e9, maxY: f32 = -1e9;
        for (let i: u32 = 0; i < this.count; i++) {
            let at = <i32>(HEADER + i * STRIDE);
            if (((v.getUint8(at + 12) >> 3) & 16) != 0) {
                let x = q[0] + <f32>v.getUint16(at, true) * q[4];
                let y = q[1] + <f32>v.getUint16(at + 2, true) * q[5];
                minX = Mathf.min(minX, x); maxX = Mathf.max(maxX, x);
                minY = Mathf.min(minY, y); maxY = Mathf.max(maxY, y);
                this.fxCount++;
            }
        }
        this.fxBox[0] = minX; this.fxBox[1] = maxX; this.fxBox[2] = minY; this.fxBox[3] = maxY;
        // game bones: names and rest poses (splat_bake.py "bone")
        let api = this.api;
        let namesAt = <i32>v.getUint32(612, true);
        let named = <i32>v.getUint32(616, true);
        let na = namesAt;
        for (let k = 0; k < named && namesAt > 0 && na + 2 <= blob.byteLength; k++) {
            let idx = <i32>v.getUint8(na);
            let len = <i32>v.getUint8(na + 1);
            let name = "";
            for (let c = 0; c < len; c++) {
                name += String.fromCharCode(v.getUint8(na + 2 + c));
            }
            na += 2 + len;
            if (idx > 0 && idx < MAX_BONES) {
                api.names.push(name);
                api.index.push(idx);
                api.restX[idx] = v.getFloat32(na, true);
                api.restY[idx] = v.getFloat32(na + 4, true);
                api.restZ[idx] = v.getFloat32(na + 8, true);
                api.restYaw[idx] = v.getFloat32(na + 12, true);
            }
            na += 16;
        }
        api.boneCount = api.names.length;
        for (let i = 0; i < 64; i++) {
            api.palette[i] = this.palette[i];
        }
        for (let i = 0; i < 256; i++) {
            api.ramps[i] = this.ramps[i];
        }
        for (let i = 0; i < 32; i++) {
            api.rampLen[i] = this.rampLen[i];
        }
        this.boneCount = <i32>v.getUint32(56, true);
        this.trackCount = <i32>Math.min(64, <f64>v.getUint32(60, true));
        let table = <i32>v.getUint32(608, true);
        for (let t = 0; t < this.trackCount; t++) {
            let at = table + t * 32;
            this.trackFirst[t] = <i32>v.getUint32(at, true);
            this.trackBones[t] = <i32>v.getUint32(at + 4, true);
            this.trackFrames[t] = <i32>v.getUint32(at + 8, true);
            this.trackFps[t] = <f64>v.getFloat32(at + 12, true);
            this.trackPhase[t] = <f64>v.getFloat32(at + 16, true);
            this.trackData[t] = <i32>v.getUint32(at + 20, true);
            this.trackSpeed[t] = <f64>v.getFloat32(at + 24, true);
        }
        return true;
    }

    private buildPipelines(): void {
        let layout = new GPUVertexBufferLayout();
        layout.stride = STRIDE;
        layout.stepMode = VertexStepMode.instance;
        layout.attributes = [
            // the 16-byte splat as four uint8x4 (16-bit vertex formats are not dependable everywhere)
            new GPUVertexAttribute(VertexFormat.uint8x4, 0, 0),   // x u16, y u16
            new GPUVertexAttribute(VertexFormat.uint8x4, 1, 4),   // z u16, sigma u8, ramp u8
            new GPUVertexAttribute(VertexFormat.uint8x4, 2, 8),   // octahedral normal u16 x2
            new GPUVertexAttribute(VertexFormat.uint8x4, 3, 12),  // step | flags << 3, joint 0, joint 1, weight 0
        ];

        let depthState = new GPUDepthStencilDesc();
        depthState.format = TextureFormat.depth32float;
        depthState.compare = CompareFunction.less;
        depthState.write = true;

        let g = new GPUPipelineDesc();
        g.vertexModule = this.splatShader;
        g.vertexEntryPoint = "vs_main";
        g.fragmentModule = this.splatShader;
        g.fragmentEntryPoint = "fs_main";
        let gTarget = new GPUColorTargetDesc();
        gTarget.format = TextureFormat.rgba8unorm;
        g.colorTargets = [gTarget];
        g.vertexBuffers = [layout];
        g.depthStencil = depthState;
        this.gbufPipe = new GPUPipeline(g);

        let s = new GPUPipelineDesc();
        s.vertexModule = this.splatShader;
        s.vertexEntryPoint = "vs_shadow";
        s.fragmentModule = this.splatShader;
        s.fragmentEntryPoint = "fs_shadow";
        s.colorTargets = [];
        s.vertexBuffers = [layout];
        s.depthStencil = depthState;
        this.shadowPipe = new GPUPipeline(s);

        let r = new GPUPipelineDesc();
        r.vertexModule = this.resolveShader;
        r.vertexEntryPoint = "vs_full";
        r.fragmentModule = this.resolveShader;
        r.fragmentEntryPoint = "fs_resolve";
        let rTarget = new GPUColorTargetDesc();
        rTarget.format = <TextureFormat>this.canvas!.format;
        r.colorTargets = [rTarget];
        this.resolvePipe = new GPUPipeline(r);

        // the shadow map never changes size, so its groups are made once
        let size = <u32>Math.max(64, this.shadowSize);
        let sd = new GPUTextureDesc();
        sd.width = size;
        sd.height = size;
        sd.format = TextureFormat.depth32float;
        sd.renderTarget = true;
        let shadowTex = new GPUTexture(sd);
        this.shadowTex = shadowTex;
        this.shadowView = shadowTex.view();
        let readDesc = new GPUTextureViewDesc();
        readDesc.aspect = TextureAspect.depthOnly;
        this.shadowRead = shadowTex.view(readDesc);
        this.frameGroup = new GPUBindGroup(this.gbufPipe!.getBindGroupLayout(0),
            [new GPUBindGroupUBO(0, this.frameUBO!), new GPUBindGroupUBO(1, this.bonesUBO!)]);
        this.shadowMapGroup = new GPUBindGroup(this.gbufPipe!.getBindGroupLayout(1), [],
            [new GPUBindGroupTexture(0, this.shadowRead!)]);
        this.shadowGroup = new GPUBindGroup(this.shadowPipe!.getBindGroupLayout(0),
            [new GPUBindGroupUBO(0, this.shadowUBO!), new GPUBindGroupUBO(1, this.bonesUBO!)]);
    }

    override resize(width: f64, height: f64, scale: f64): void {
        this.width = width;
        this.height = height;
        let px = Math.max(1, this.pixelSize);
        // one spare art pixel on every side: the camera snap slides the grid by
        // up to a pixel, and the edge must never show
        let w = <u32>Math.max(8, Math.ceil(width / px) + 2);
        let h = <u32>Math.max(8, Math.ceil(height / px) + 2);
        if (w == this.artW && h == this.artH) {
            return;
        }
        this.artW = w;
        this.artH = h;
        let canvas = this.canvas;
        if (canvas == null || !canvas.resize(w, h)) {
            return;
        }
        let gd = new GPUTextureDesc();
        gd.width = w * 2;
        gd.height = h * 2;
        gd.format = TextureFormat.rgba8unorm;
        gd.renderTarget = true;
        let gbuf = new GPUTexture(gd);
        let dd = new GPUTextureDesc();
        dd.width = w * 2;
        dd.height = h * 2;
        dd.format = TextureFormat.depth32float;
        dd.renderTarget = true;
        let depth = new GPUTexture(dd);
        let readDesc = new GPUTextureViewDesc();
        readDesc.aspect = TextureAspect.depthOnly;
        this.gbuf = gbuf;
        this.gbufView = gbuf.view();
        this.depth = depth;
        this.depthView = depth.view();
        this.depthRead = depth.view(readDesc);
        this.resolveGroup = new GPUBindGroup(this.resolvePipe!.getBindGroupLayout(0),
            [new GPUBindGroupUBO(0, this.lookUBO!)],
            [new GPUBindGroupTexture(1, this.gbufView!), new GPUBindGroupTexture(2, this.depthRead!)]);
        this.ready = true;
    }

    override advance(seconds: f64): bool {
        if (!this.argsReapplied) {
            // RML sets its ScriptInputs after init: apply the command line's --arg again, once,
            // so `--arg yaw=90` wins over the scene's own value
            this.argsReapplied = true;
            let context = this.context;
            if (context != null) {
                this.applyArgs(context);
            }
        }
        this.time += seconds;
        this.runGame(seconds);
        if (this.demo && !this.api.playable && this.tourRate == 0 && this.tour <= 0) {
            this.demoYaw += this.demoSpin * seconds;
        }
        if (!this.dragging) {
            this.spinTime += seconds;
            // a released drag keeps turning a little and settles
            this.userYaw += this.yawVelocity * seconds;
            this.userPitch += this.pitchVelocity * seconds;
            let damp = Math.exp(-seconds * 5);
            this.yawVelocity *= damp;
            this.pitchVelocity *= damp;
            this.clampPitch();
        }
        return true;
    }

    // --- the game hook (game.as): inputs -> api, the game's update, api -> inputs

    private toApi(): void {
        let a = this.api;
        a.yaw = this.yaw; a.pitch = this.pitch; a.distance = this.distance; a.orthoHeight = this.orthoHeight;
        a.perspective = this.perspective; a.fov = this.fov; a.lookAt = this.lookAt;
        a.eyeX = this.eyeX; a.eyeY = this.eyeY; a.eyeZ = this.eyeZ; a.useTarget = this.useTarget;
        a.targetX = this.targetX; a.targetY = this.targetY; a.targetZ = this.targetZ;
        a.sunYaw = this.sunYaw; a.sunPitch = this.sunPitch; a.keyLight = this.keyLight; a.fogMax = this.fogMax;
        a.horizon = this.horizon; a.skyBlend = this.skyBlend;
    }

    private fromApi(): void {
        let a = this.api;
        this.yaw = a.yaw; this.pitch = a.pitch; this.distance = a.distance; this.orthoHeight = a.orthoHeight;
        this.perspective = a.perspective; this.fov = a.fov; this.lookAt = a.lookAt;
        this.eyeX = a.eyeX; this.eyeY = a.eyeY; this.eyeZ = a.eyeZ; this.useTarget = a.useTarget;
        this.targetX = a.targetX; this.targetY = a.targetY; this.targetZ = a.targetZ;
        this.sunYaw = a.sunYaw; this.sunPitch = a.sunPitch; this.keyLight = a.keyLight; this.fogMax = a.fogMax;
        this.horizon = a.horizon; this.skyBlend = a.skyBlend;
    }

    // The HUD grid: whole art pixels, aligned with the art grid's pixels (the art is centred and
    // slid by the camera snap, so its pixel edges sit at hudOX + k * pixelSize on screen).
    private hudOX: f32 = 0;
    private hudOY: f32 = 0;

    private updateHudOrigin(): void {
        let px = <f32>Math.max(1, this.pixelSize);
        let ox = Mathf.round((<f32>this.width - <f32>this.artW * px) * 0.5 + this.blitX);
        let oy = Mathf.round((<f32>this.height - <f32>this.artH * px) * 0.5 + this.blitY);
        this.hudOX = ox - Mathf.floor(ox / px) * px;
        this.hudOY = oy - Mathf.floor(oy / px) * px;
    }

    private runGame(seconds: f64): void {
        let a = this.api;
        a.time = this.time;
        a.frame++;
        a.dt = Math.min(Math.max(seconds, 0), 0.1);
        a.demoChanged = this.started && a.demo != this.demo;
        a.demo = this.demo;
        let px = Math.max(1, this.pixelSize);
        a.pixelSize = px;
        a.hudW = <i32>Math.floor((this.width - <f64>this.hudOX) / px);
        a.hudH = <i32>Math.floor((this.height - <f64>this.hudOY) / px);
        this.toApi();
        if (!this.started) {
            this.started = true;
            if (this.ready && this.canvas != null) {
                this.updateUniforms(); // pick and project see the real camera from the first update
            }
            this.game.start(a);
        }
        this.game.update(a);
        this.fromApi();
        this.sendSounds();
        if (a.playable && this.ready && this.canvas != null) {
            this.updateUniforms(); // picking and projecting see the camera the game just set
        }
    }

    // The game's sounds of this frame, to the synth on the audio thread (started on the first one).
    private sendSounds(): void {
        let a = this.api;
        let n = a.sfxKind.length;
        if (n > 0 && !this.demo && this.sound) {
            let h = this.sfxHandle;
            if (h != null && h.failed != null) {
                this.sfxHandle = null; // a failed processor plays silence: start a new one (a few times)
            }
            if (this.sfxHandle == null && this.sfxStarts < 3 && Audio.processorSampleRate() > 0) {
                let ring = this.sfxRing;
                if (ring == null) {
                    ring = Ring.create<SfxEvent>(8192);
                    this.sfxRing = ring;
                }
                this.sfxHandle = Audio.start(() => new SfxSynth(), ring);
                this.sfxStarts++;
            }
            let ring = this.sfxRing;
            if (this.sfxHandle != null && ring != null) {
                let at = Audio.timeFrame();
                let sr = Audio.processorSampleRate();
                let e = this.sfxEvent;
                for (let i = 0; i < n; i++) {
                    e.kind = a.sfxKind[i];
                    e.pitch = a.sfxPitch[i];
                    e.volume = a.sfxVol[i] * this.soundVolume;
                    e.pan = a.sfxPan[i];
                    e.at = at + Math.round(a.sfxDelay[i] * sr);
                    ring.send(e);
                }
            }
        }
        a.sfxKind.length = 0;
        a.sfxPitch.length = 0;
        a.sfxVol.length = 0;
        a.sfxPan.length = 0;
        a.sfxDelay.length = 0;
    }

    private gamePointer(event: PointerEvent, kind: i32): bool {
        let a = this.api;
        if (!a.playable) {
            return false;
        }
        if (this.demo) {
            return true; // a game in demo mode ignores the pointer (and leaves it to the host)
        }
        let px = <f32>Math.max(1, this.pixelSize);
        a.pointerX = (event.position.x - this.hudOX) / px;
        a.pointerY = (event.position.y - this.hudOY) / px;
        if (kind == POINTER_DOWN) {
            a.pointerDown = true;
        } else if (kind == POINTER_UP) {
            a.pointerDown = false;
        }
        if (this.ready && this.canvas != null) {
            this.updateUniforms(); // the camera of this moment, for api.pick
        }
        if (this.game.pointer(a, kind, a.pointerX, a.pointerY)) {
            event.hit();
        }
        return true;
    }

    // The shared turntable's angle at timeline time t: speed eases 0 -> rate over `tourEase` s
    // (smoothstep, integrated), holds, and eases back to 0 over the last `tourEase` s of `tourLength`.
    private tourAngle(t0: f64): f64 {
        let rate = this.tourRate;
        let e = Math.max(this.tourEase, 0.001);
        let len = this.tourLength > 2 * e ? this.tourLength : 1e9;
        let t = Math.min(Math.max(t0, 0), len);
        let ramp = (u: f64): f64 => u * u * u - 0.5 * u * u * u * u; // integral of 3u^2 - 2u^3
        if (t < e) {
            return rate * e * ramp(t / e);
        }
        if (t < len - e) {
            return rate * (0.5 * e + (t - e));
        }
        let total = rate * (len - e);
        return total - rate * e * ramp((len - t) / e);
    }

    // --- orbit controls

    private clampPitch(): void {
        let p = this.pitch + this.userPitch;
        if (p < this.pitchMin) {
            this.userPitch = this.pitchMin - this.pitch;
            this.pitchVelocity = 0;
        } else if (p > this.pitchMax) {
            this.userPitch = this.pitchMax - this.pitch;
            this.pitchVelocity = 0;
        }
    }

    override pointerDown(event: PointerEvent): void {
        if (this.gamePointer(event, POINTER_DOWN)) {
            return;
        }
        if (!this.orbit || this.demo || this.dragging) {
            return;
        }
        this.dragging = true;
        this.dragId = event.id;
        this.lastX = event.position.x;
        this.lastY = event.position.y;
        this.yawVelocity = 0;
        this.pitchVelocity = 0;
        event.hit();
    }

    override pointerMove(event: PointerEvent): void {
        if (this.gamePointer(event, POINTER_MOVE)) {
            return;
        }
        if (!this.dragging || event.id != this.dragId) {
            return;
        }
        let dx = <f64>(event.position.x - this.lastX);
        let dy = <f64>(event.position.y - this.lastY);
        this.lastX = event.position.x;
        this.lastY = event.position.y;
        let dYaw = -dx * this.orbitSpeed;
        let dPitch = dy * this.orbitSpeed;
        this.userYaw += dYaw;
        this.userPitch += dPitch;
        this.clampPitch();
        // the throw: a smoothed rate of the last moves, in degrees per second (moves come ~60 a second)
        this.yawVelocity = this.yawVelocity * 0.5 + dYaw * 60 * 0.5;
        this.pitchVelocity = this.pitchVelocity * 0.5 + dPitch * 60 * 0.5;
        event.hit();
    }

    override pointerUp(event: PointerEvent): void {
        if (this.gamePointer(event, POINTER_UP)) {
            return;
        }
        if (!this.dragging || event.id != this.dragId) {
            return;
        }
        this.dragging = false;
        event.hit();
    }

    override pointerExit(event: PointerEvent): void {
        if (this.api.playable) {
            this.api.pointerDown = false;
        }
        if (this.dragging && event.id == this.dragId) {
            this.dragging = false;
        }
    }

    override pointerScroll(event: ScrollEvent): void {
        if (!this.orbit || this.demo || this.api.playable) {
            return;
        }
        let z = this.zoom * Math.exp(<f64>event.delta.y * 0.002);
        this.zoom = Math.min(Math.max(z, this.zoomMin), this.zoomMax);
        event.hit();
    }

    // Stepped playback: each track shows frame floor((time * speed + phase) * fps), copied
    // straight from the blob into the bone buffer, only when it changes.
    private updateBones(): void {
        let bones = this.bonesUBO;
        if (bones == null) {
            return;
        }
        let t0 = this.animate ? this.time * this.animSpeed : 0;
        for (let t = 0; t < this.trackCount; t++) {
            let frames = this.trackFrames[t];
            let k = <i32>Math.floor((t0 * this.trackSpeed[t] + this.trackPhase[t]) * this.trackFps[t]);
            k = ((k % frames) + frames) % frames;
            if (k == this.trackShown[t]) {
                continue;
            }
            this.trackShown[t] = k;
            let n = this.trackBones[t];
            bones.update(<u32>(this.trackFirst[t] * BONE_BYTES), this.blob, <u32>(n * BONE_BYTES),
                <u32>(this.trackData[t] + k * n * BONE_BYTES));
        }
        // the game's bones: one upload over the range it changed
        let a = this.api;
        if (a.anyDirty) {
            a.anyDirty = false;
            let lo = MAX_BONES, hi = -1;
            let f = Float32Array.wrap(this.gameBones);
            for (let b = 1; b < MAX_BONES; b++) {
                if (a.dirty[b]) {
                    a.dirty[b] = false;
                    lo = lo < b ? lo : b;
                    hi = hi > b ? hi : b;
                    for (let i = 0; i < 12; i++) {
                        f[b * 12 + i] = a.mats[b * 12 + i];
                    }
                }
            }
            if (hi >= lo) {
                bones.update(<u32>(lo * BONE_BYTES), this.gameBones, <u32>((hi - lo + 1) * BONE_BYTES),
                    <u32>(lo * BONE_BYTES));
            }
        }
    }

    // --- uniforms

    private sceneRadius(): f32 {
        let dx = this.boundsMax[0] - this.boundsMin[0];
        let dy = this.boundsMax[1] - this.boundsMin[1];
        let dz = this.boundsMax[2] - this.boundsMin[2];
        return Mathf.max(0.5 * Mathf.sqrt(dx * dx + dy * dy + dz * dz), 0.01);
    }

    private writeTables(f: Float32Array, u: Uint32Array, rampsAt: i32, lenAt: i32): void {
        for (let i = 0; i < 256; i++) {
            u[rampsAt + i] = this.ramps[i];
        }
        for (let i = 0; i < 32; i++) {
            u[lenAt + i] = this.rampLen[i];
        }
    }

    private updateUniforms(): void {
        let W = <f32>this.artW;
        let H = <f32>this.artH;
        let R = this.sceneRadius();
        let useTarget = this.useTarget || this.lookAt;
        let cx = useTarget ? <f32>this.targetX : 0.5 * (this.boundsMin[0] + this.boundsMax[0]);
        let cy = useTarget ? <f32>this.targetY : 0.5 * (this.boundsMin[1] + this.boundsMax[1]);
        let cz = useTarget ? <f32>this.targetZ : 0.5 * (this.boundsMin[2] + this.boundsMax[2]);
        let yawDeg = this.yaw + this.spin * this.spinTime + this.userYaw + this.demoYaw;
        if (this.tourRate != 0 && !this.lookAt) {
            yawDeg = this.yaw + this.tourAngle(this.time + this.tourOffset);
        } else if (this.tour > 0 && !this.lookAt) {
            let u = Math.min(Math.max(this.time / this.tour, 0), 1);
            yawDeg = this.yaw + 360 * this.tourLoops * (0.5 - 0.5 * Math.cos(Math.PI * u));
        }
        let yaw = <f32>(yawDeg * Math.PI / 180);
        let pitch = <f32>((this.pitch + this.userPitch) * Math.PI / 180);
        let zoom = <f32>this.zoom;
        // the camera's axes: forward f, right r (level: no roll), up = r x f; look-at replaces the orbit's
        let dist = (this.distance > 0 ? <f32>this.distance : R * 3) * (this.perspective ? zoom : 1);
        let fx = -Mathf.cos(pitch) * Mathf.sin(yaw);
        let fy = -Mathf.sin(pitch);
        let fz = -Mathf.cos(pitch) * Mathf.cos(yaw);
        let rx = Mathf.cos(yaw);
        let rz = -Mathf.sin(yaw);
        if (this.lookAt) {
            let dx = cx - <f32>this.eyeX;
            let dy = cy - <f32>this.eyeY;
            let dz = cz - <f32>this.eyeZ;
            dist = Mathf.max(Mathf.sqrt(dx * dx + dy * dy + dz * dz), 0.001);
            fx = dx / dist;
            fy = dy / dist;
            fz = dz / dist;
            let rl = Mathf.max(Mathf.sqrt(fx * fx + fz * fz), 1e-4);
            rx = -fz / rl;
            rz = fx / rl;
        }
        // up = right x forward
        let upx = -rz * fy;
        let upy = rz * fx - rx * fz;
        let upz = rx * fy;
        let orthoH = (this.orthoHeight > 0 ? <f32>this.orthoHeight : R * 2.1) * zoom;
        let texel = orthoH / H; // world units per art pixel
        // snap the target to the art grid along the view plane (ortho), and
        // carry the remainder into the blit so the picture slides by whole
        // screen pixels instead of shimmering
        this.blitX = 0;
        this.blitY = 0;
        if (!this.perspective) {
            let tr = cx * rx + cz * rz;
            let tu = cx * upx + cy * upy + cz * upz;
            let sr = Mathf.round(tr / texel) * texel;
            let su = Mathf.round(tu / texel) * texel;
            cx += (sr - tr) * rx + (su - tu) * upx;
            cy += (su - tu) * upy;
            cz += (sr - tr) * rz + (su - tu) * upz;
            let px = <f32>this.pixelSize;
            this.blitX = (sr - tr) / texel * px;
            this.blitY = -(su - tu) / texel * px;
        }
        let ex = cx - fx * dist;
        let ey = cy - fy * dist;
        let ez = cz - fz * dist;
        let view = Mat4.lookAt(ex, ey, ez, cx, cy, cz, upx, upy, upz); // works straight down too
        let near: f32 = 0.05;
        let far: f32 = dist + R * 2;
        let proj: Mat4;
        let scale: f32;
        if (this.perspective) {
            let fovy = <f32>(this.fov * Math.PI / 180);
            near = Mathf.max(0.05, dist - R * 2);
            proj = Mat4.perspective(fovy, W / H, near, far);
            scale = (H * 2) * 0.5 / Mathf.tan(fovy * 0.5); // focal length in G-buffer px
        } else {
            let hw = orthoH * 0.5 * W / H;
            near = Mathf.max(0.01, dist - R * 2);
            proj = Mat4.ortho(-hw, hw, -orthoH * 0.5, orthoH * 0.5, near, far);
            scale = (H * 2) / orthoH; // G-buffer px per world unit
        }
        // the camera for the game's picking (api.pick / api.project)
        let ga = this.api;
        ga.camEX = ex; ga.camEY = ey; ga.camEZ = ez;
        ga.camFX = fx; ga.camFY = fy; ga.camFZ = fz;
        ga.camRX = rx; ga.camRY = 0; ga.camRZ = rz;
        ga.camUX = upx; ga.camUY = upy; ga.camUZ = upz;
        ga.camPersp = this.perspective;
        if (this.perspective) {
            let th = Mathf.tan(<f32>(this.fov * Math.PI / 180) * 0.5);
            ga.camHW = th * W / H;
            ga.camHH = th;
        } else {
            ga.camHW = orthoH * 0.5 * W / H;
            ga.camHH = orthoH * 0.5;
        }
        let gpx = <f32>Math.max(1, this.pixelSize);
        this.updateHudOrigin();
        ga.gridOX = (Mathf.round((<f32>this.width - W * gpx) * 0.5 + this.blitX) - this.hudOX) / gpx;
        ga.gridOY = (Mathf.round((<f32>this.height - H * gpx) * 0.5 + this.blitY) - this.hudOY) / gpx;
        ga.gridW = W;
        ga.gridH = H;
        // the sun
        let sy = <f32>(this.sunYaw * Math.PI / 180);
        let sp = <f32>(this.sunPitch * Math.PI / 180);
        let sx = Mathf.cos(sp) * Mathf.sin(sy);
        let syy = Mathf.sin(sp);
        let sz = Mathf.cos(sp) * Mathf.cos(sy);
        let mx = 0.5 * (this.boundsMin[0] + this.boundsMax[0]);
        let my = 0.5 * (this.boundsMin[1] + this.boundsMax[1]);
        let mz = 0.5 * (this.boundsMin[2] + this.boundsMax[2]);
        let upZ: f32 = Mathf.abs(syy) > 0.99 ? 1 : 0;
        let lightView = Mat4.lookAt(mx + sx * R * 2, my + syy * R * 2, mz + sz * R * 2, mx, my, mz,
            0, 1 - upZ, upZ);
        let lightProj = Mat4.ortho(-R, R, -R, R, R * 0.5, R * 3.5);
        let lightVP = lightProj * lightView;
        let shadowSize = <f32>this.shadowTex!.width;

        this.writeFrame(this.frameData, view, proj, lightVP, W * 2, H * 2, scale, this.perspective ? 0 : 1,
            sx, syy, sz, this.shadows ? shadowSize : 0);
        this.writeFrame(this.shadowData, lightView, lightProj, lightVP, shadowSize, shadowSize,
            shadowSize / (2 * R), 1, sx, syy, sz, 0);
        this.frameUBO!.update(0, this.frameData);
        this.shadowUBO!.update(0, this.shadowData);

        // the resolve's look
        let f = Float32Array.wrap(this.lookData);
        let u = Uint32Array.wrap(this.lookData);
        for (let i = 0; i < 64; i++) {
            let c = this.palette[i];
            f[i * 4] = <f32>(c & 0xFF) / 255;
            f[i * 4 + 1] = <f32>((c >> 8) & 0xFF) / 255;
            f[i * 4 + 2] = <f32>((c >> 16) & 0xFF) / 255;
            f[i * 4 + 3] = 1;
        }
        this.writeTables(f, u, 256, 512);
        let o = 544; // grid
        f[o] = W; f[o + 1] = H; f[o + 2] = <f32>this.ink; f[o + 3] = <f32>this.edgeDepth;
        f[o + 4] = near; f[o + 5] = far; f[o + 6] = this.perspective ? 0 : 1;
        // fog is measured from the orbit target, so it does not move when the camera backs off
        let fogStart = dist + <f32>this.fogStart;
        let fogEnd = dist + (this.fogEnd != 0 ? <f32>this.fogEnd : R * 1.5);
        f[o + 7] = fogStart;
        f[o + 8] = fogEnd; f[o + 9] = <f32>this.fogMax;
        f[o + 10] = <f32>(this.roles[2] < 64 ? this.roles[2] : 0);
        f[o + 11] = <f32>this.minCoverage;
        f[o + 12] = <f32>(this.roles[0] < 64 ? this.roles[0] : 0);
        f[o + 13] = <f32>(this.roles[1] < 64 ? this.roles[1] : 0);
        f[o + 14] = <f32>this.horizon; f[o + 15] = <f32>this.skyBlend;
        f[o + 16] = <f32>this.debug; f[o + 17] = this.maskSky ? 1 : 0; f[o + 18] = 0; f[o + 19] = 0;
        this.lookUBO!.update(0, this.lookData);
    }

    private writeFrame(buffer: ArrayBuffer, view: Mat4, proj: Mat4, lightVP: Mat4,
                       tw: f32, th: f32, scale: f32, ortho: f32,
                       sx: f32, sy: f32, sz: f32, shadowSize: f32): void {
        view.writeToBuffer(buffer, 0);
        proj.writeToBuffer(buffer, 64);
        lightVP.writeToBuffer(buffer, 128);
        let f = Float32Array.wrap(buffer);
        let u = Uint32Array.wrap(buffer);
        let o = 48;
        f[o] = sx; f[o + 1] = sy; f[o + 2] = sz; f[o + 3] = <f32>this.keyLight;
        f[o + 4] = tw; f[o + 5] = th; f[o + 6] = scale; f[o + 7] = ortho;
        f[o + 8] = <f32>this.splatScale; f[o + 9] = <f32>this.threshold; f[o + 10] = <f32>this.flatness; f[o + 11] = <f32>this.jitter;
        f[o + 12] = <f32>this.shadeSteps; f[o + 13] = <f32>this.lightSteps; f[o + 14] = <f32>this.bandDither;
        f[o + 15] = <f32>this.time;
        let R = this.sceneRadius();
        // shadow offsets scale with the SPLAT, not the scene: a receiving splat is pushed
        // out along its normal past its neighbours' discs (the light's depth range is 3R)
        let sp = this.spacing;
        f[o + 16] = shadowSize; f[o + 17] = sp * <f32>this.shadowBias / (3 * R);
        f[o + 18] = sp * <f32>this.shadowOffset; f[o + 19] = this.splatDither ? 1 : 0;
        f[o + 20] = <f32>this.windAmp; f[o + 21] = 0; f[o + 22] = <f32>this.windAmp * 0.6;
        f[o + 23] = <f32>this.windFreq;
        f[o + 24] = <f32>this.highlight; f[o + 25] = 0; f[o + 26] = 0; f[o + 27] = 0;
        let cycle = Math.max(0.1, this.fxPeriod);
        let ft = (this.fxStopAt > 0 ? Math.min(this.time, this.fxStopAt) : this.time) + this.fxOffset;
        f[o + 28] = <f32>(ft - Math.floor(ft / cycle) * cycle);
        f[o + 29] = this.fx && this.fxCount > 0 ? 1 : 0;
        f[o + 30] = <f32>this.fxRampA; f[o + 31] = <f32>this.fxRampB;
        f[o + 32] = this.fxBox[0]; f[o + 33] = this.fxBox[1]; f[o + 34] = this.fxBox[2]; f[o + 35] = this.fxBox[3];
        this.writeTables(f, u, 84, 340);
        for (let k = 0; k < 8; k++) {
            f[372 + k] = this.quant[k];
        }
    }

    // --- drawing

    override draw(renderer: Renderer): void {
        let canvas = this.canvas;
        if (!this.ready || canvas == null || this.count == 0) {
            return;
        }
        this.updateUniforms();
        this.updateBones();
        let splats = this.splats!;

        if (this.shadows) {
            let sp = new GPUPassDesc();
            sp.depthView = this.shadowView;
            sp.depthLoadOp = LoadOp.clear;
            sp.depthStoreOp = StoreOp.store;
            sp.label = "splat shadow";
            let pass = canvas.beginRenderPass(sp);
            pass.setPipeline(this.shadowPipe!);
            pass.setBindGroup(0, this.shadowGroup!);
            pass.setVertexBuffer(0, splats);
            pass.draw(6, this.count);
            pass.finish();
        }

        let gColor = new GPUColorAttachment();
        gColor.view = this.gbufView;
        gColor.loadOp = LoadOp.clear;
        gColor.storeOp = StoreOp.store;
        let gp = new GPUPassDesc();
        gp.color = [gColor];
        gp.depthView = this.depthView;
        gp.depthLoadOp = LoadOp.clear;
        gp.depthStoreOp = StoreOp.store;
        gp.label = "splat gbuffer";
        let pass = canvas.beginRenderPass(gp);
        pass.setPipeline(this.gbufPipe!);
        pass.setBindGroup(0, this.frameGroup!);
        pass.setBindGroup(1, this.shadowMapGroup!);
        pass.setVertexBuffer(0, splats);
        pass.draw(6, this.count);
        pass.finish();

        let rColor = new GPUColorAttachment();
        rColor.loadOp = LoadOp.clear;
        rColor.storeOp = StoreOp.store;
        let rp = new GPUPassDesc();
        rp.color = [rColor];
        rp.label = "splat resolve";
        let resolve = canvas.beginRenderPass(rp);
        resolve.setPipeline(this.resolvePipe!);
        resolve.setBindGroup(0, this.resolveGroup!);
        resolve.draw(3);
        resolve.finish();

        // the art grid, scaled by whole pixels and centred
        let px = <f32>this.pixelSize;
        let ox = <f32>(this.width - <f64>this.artW * this.pixelSize) * 0.5 + this.blitX;
        let oy = <f32>(this.height - <f64>this.artH * this.pixelSize) * 0.5 + this.blitY;
        renderer.save();
        renderer.transform(Mat2D.withScaleAndTranslation(px, px, Mathf.round(ox), Mathf.round(oy)));
        renderer.drawImage(canvas.image, this.sampler, BlendMode.srcOver, 1);
        renderer.restore();
        this.drawHud(renderer);
    }

    // The game's HUD: rectangles on the HUD grid (whole art pixels from the frame's top-left),
    // one path per colour
    private drawHud(renderer: Renderer): void {
        let a = this.api;
        a.clearHud();
        this.game.hud(a);
        let n = a.rectC.length;
        if (n == 0) {
            return;
        }
        let px = <f32>Math.max(1, this.pixelSize);
        let path = this.hudPath;
        let paint = this.hudPaint;
        paint.style = PaintStyle.fill;
        renderer.save();
        renderer.transform(Mat2D.withScaleAndTranslation(px, px, this.hudOX, this.hudOY));
        // in call order (later on top), one path per run of one colour
        let i = 0;
        while (i < n) {
            let c = a.rectC[i];
            path.reset();
            let j = i;
            for (; j < n && a.rectC[j] == c; j++) {
                let x = a.rectX[j], y = a.rectY[j], w = a.rectW[j], h = a.rectH[j];
                path.moveTo(Vector.xy(x, y));
                path.lineTo(Vector.xy(x + w, y));
                path.lineTo(Vector.xy(x + w, y + h));
                path.lineTo(Vector.xy(x, y + h));
                path.close();
            }
            paint.color = Color.rgba(<i32>(c & 0xFF), <i32>((c >> 8) & 0xFF), <i32>((c >> 16) & 0xFF), 255);
            renderer.drawPath(path, paint);
            i = j;
        }
        renderer.restore();
    }
}
