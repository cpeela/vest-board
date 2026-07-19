import AVFoundation
import QuartzCore

/// Soft, ASMR-ish split-flap sound. Each tick is a low, muffled "tock" (gentle
/// attack, low-passed noise + low body tone). Pitch-varied buffers played through
/// a small pool of nodes let ticks overlap softly into a riffle instead of the
/// truncated buzz you get from a single interrupting node.
final class FlapClicker {
    static let shared = FlapClicker()

    var enabled = true

    private let engine = AVAudioEngine()
    private var nodes: [AVAudioPlayerNode] = []
    private var buffers: [AVAudioPCMBuffer] = []
    private var nodeIndex = 0
    private var lastTick: CFTimeInterval = 0
    private let minInterval: CFTimeInterval = 0.019   // dense terminal riffle of clean clicks
    private var started = false

    private init() { setup() }

    private func setup() {
        guard let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1) else { return }

        // Soft "clack" variants — vary decay and the mid-body resonance (plasticky, not bright).
        let variants: [(decay: Double, res: Double)] = [
            (320, 720), (350, 900), (300, 1050), (370, 820), (330, 980)
        ]
        buffers = variants.compactMap { makeClack(decay: $0.decay, res: $0.res, format: format) }
        guard !buffers.isEmpty else { return }

        for _ in 0..<8 {
            let node = AVAudioPlayerNode()
            engine.attach(node)
            engine.connect(node, to: engine.mainMixerNode, format: format)
            nodes.append(node)
        }
        engine.mainMixerNode.outputVolume = 0.5

        do {
            try engine.start()
            nodes.forEach { $0.play() }
            started = true
        } catch {
            started = false
        }
    }

    /// A soft split-flap "clack": mildly-filtered noise (tamed hiss) + a mid-body
    /// resonance, gentle attack, medium decay — the plasticky flutter of a flip-clock,
    /// not a sharp click or a low drum.
    private func makeClack(decay: Double, res: Double, format: AVAudioFormat) -> AVAudioPCMBuffer? {
        let sr = 44_100.0
        let dur = 0.04
        let frames = AVAudioFrameCount(sr * dur)
        guard let buf = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames),
              let ch = buf.floatChannelData?[0] else { return nil }
        buf.frameLength = frames

        var lp = 0.0
        for i in 0..<Int(frames) {
            let t = Double(i) / sr
            let attack = min(1.0, t / 0.0018)            // ~1.8ms soft attack — no sharp click
            let env = attack * exp(-t * decay)
            let n = Double.random(in: -1...1)
            lp += 0.35 * (n - lp)                        // mild low-pass — tame hiss, keep body
            let body = sin(2 * .pi * res * t) * exp(-t * decay * 1.2)  // plasticky mid "clack"
            ch[i] = Float((lp * 0.5 + body * 0.5) * env * 0.45)
        }
        return buf
    }

    /// Call once per flip step; self-throttles and round-robins the node pool.
    func tick() {
        guard enabled, started, !nodes.isEmpty else { return }
        let now = CACurrentMediaTime()
        guard now - lastTick >= minInterval else { return }
        lastTick = now

        let node = nodes[nodeIndex % nodes.count]
        nodeIndex &+= 1
        let buffer = buffers[Int.random(in: 0..<buffers.count)]
        // No .interrupts: let each soft tock play out fully (the pool handles overlap).
        node.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
    }
}
