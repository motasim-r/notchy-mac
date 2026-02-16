#!/usr/bin/env swift

import AppKit
import Foundation

let args = CommandLine.arguments
guard args.count >= 2 else {
    fputs("Usage: generate_dmg_background.swift <output-png-path> [width] [height]\n", stderr)
    exit(1)
}

let outputPath = args[1]
let width = CGFloat((args.count >= 3 ? Int(args[2]) : nil) ?? 720)
let height = CGFloat((args.count >= 4 ? Int(args[3]) : nil) ?? 440)

let canvas = NSImage(size: NSSize(width: width, height: height))
canvas.lockFocus()

NSColor(calibratedWhite: 0.95, alpha: 1.0).setFill()
NSBezierPath(rect: NSRect(x: 0, y: 0, width: width, height: height)).fill()

let topGradient = NSGradient(
    colors: [
        NSColor(calibratedWhite: 0.93, alpha: 1.0),
        NSColor(calibratedWhite: 0.97, alpha: 1.0)
    ]
)
topGradient?.draw(
    in: NSRect(x: 0, y: height * 0.35, width: width, height: height * 0.65),
    angle: -90
)

let text = "To install drag the Notchy Teleprompter app into your Applications folder"
let paragraph = NSMutableParagraphStyle()
paragraph.alignment = .center
paragraph.lineBreakMode = .byWordWrapping

let textAttributes: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 35, weight: .medium),
    .foregroundColor: NSColor(calibratedWhite: 0.33, alpha: 1.0),
    .paragraphStyle: paragraph
]

let textRect = NSRect(
    x: 56,
    y: height * 0.57,
    width: width - 112,
    height: 130
)

(text as NSString).draw(
    with: textRect,
    options: [.usesLineFragmentOrigin, .usesFontLeading],
    attributes: textAttributes
)

canvas.unlockFocus()

guard
    let tiffData = canvas.tiffRepresentation,
    let bitmapRep = NSBitmapImageRep(data: tiffData),
    let pngData = bitmapRep.representation(using: .png, properties: [:])
else {
    fputs("Failed to render DMG background image\n", stderr)
    exit(1)
}

do {
    let outputURL = URL(fileURLWithPath: outputPath)
    try FileManager.default.createDirectory(
        at: outputURL.deletingLastPathComponent(),
        withIntermediateDirectories: true
    )
    try pngData.write(to: outputURL)
} catch {
    fputs("Failed to write PNG: \(error)\n", stderr)
    exit(1)
}
