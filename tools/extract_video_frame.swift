// extract_video_frame.swift — pull a single still frame out of a simulator
// screen recording (e.g. from `tools/record_ui_test.sh`) as a PNG, so a fast
// or timing-sensitive animation can be inspected frame-by-frame after the
// fact instead of relying on a human watching it happen live.
//
// Usage: swift tools/extract_video_frame.swift <video.mov> <time-seconds> <out.png>
//
// Run it a few times at different <time-seconds> across the window you care
// about (e.g. every 0.2-0.3s) to build a flipbook — cheaper than guessing the
// exact moment up front. Uses AVFoundation's frame-accurate image generator;
// no GPU/display access needed, so it runs headless.

import AVFoundation
import AppKit

let args = CommandLine.arguments
guard args.count >= 4, let timeSec = Double(args[2]) else {
    print("usage: swift tools/extract_video_frame.swift <video.mov> <time-seconds> <out.png>")
    exit(1)
}
let videoPath = args[1]
let outPath = args[3]

let asset = AVURLAsset(url: URL(fileURLWithPath: videoPath))
let generator = AVAssetImageGenerator(asset: asset)
generator.appliesPreferredTrackTransform = true
generator.requestedTimeToleranceBefore = .zero
generator.requestedTimeToleranceAfter = .zero
let time = CMTime(seconds: timeSec, preferredTimescale: 600)

do {
    let cgImage = try generator.copyCGImage(at: time, actualTime: nil)
    let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
    guard let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
        print("error: failed to encode PNG")
        exit(1)
    }
    try pngData.write(to: URL(fileURLWithPath: outPath))
    print("wrote \(outPath) @ \(timeSec)s")
} catch {
    print("error extracting frame at \(timeSec)s: \(error)")
    exit(1)
}
