#!/usr/bin/env swift
// Composite the source AppIcon PNG onto an opaque purple background so no
// transparent corners remain. Reads assets/AppIcon.png, writes to the path
// given as the first argument.

import Foundation
import CoreGraphics
import ImageIO
import AppKit

guard CommandLine.arguments.count >= 3 else {
    FileHandle.standardError.write(Data("usage: flatten-icon.swift <input.png> <output.png>\n".utf8))
    exit(1)
}

let inputPath = CommandLine.arguments[1]
let outputPath = CommandLine.arguments[2]

let url = URL(fileURLWithPath: inputPath)
guard let src = CGImageSourceCreateWithURL(url as CFURL, nil),
      let image = CGImageSourceCreateImageAtIndex(src, 0, nil) else {
    FileHandle.standardError.write(Data("failed to read \(inputPath)\n".utf8))
    exit(1)
}

let width = image.width
let height = image.height

// Sample a pixel from just inside the icon's edge to pick a background color
// that matches the icon's gradient. (5% from the left, vertically centered.)
func samplePixel(x: Int, y: Int) -> (r: CGFloat, g: CGFloat, b: CGFloat) {
    var pixel: [UInt8] = [0, 0, 0, 0]
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let ctx = CGContext(data: &pixel,
                        width: 1,
                        height: 1,
                        bitsPerComponent: 8,
                        bytesPerRow: 4,
                        space: colorSpace,
                        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    ctx.translateBy(x: CGFloat(-x), y: CGFloat(-y))
    ctx.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
    return (CGFloat(pixel[0]) / 255.0,
            CGFloat(pixel[1]) / 255.0,
            CGFloat(pixel[2]) / 255.0)
}

let sample = samplePixel(x: Int(Double(width) * 0.06), y: height / 2)

let colorSpace = CGColorSpaceCreateDeviceRGB()
guard let ctx = CGContext(data: nil,
                          width: width,
                          height: height,
                          bitsPerComponent: 8,
                          bytesPerRow: 0,
                          space: colorSpace,
                          bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) else {
    FileHandle.standardError.write(Data("failed to create context\n".utf8))
    exit(1)
}

ctx.setFillColor(red: sample.r, green: sample.g, blue: sample.b, alpha: 1.0)
ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))
ctx.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))

guard let out = ctx.makeImage() else {
    FileHandle.standardError.write(Data("failed to render image\n".utf8))
    exit(1)
}

let outURL = URL(fileURLWithPath: outputPath)
guard let dest = CGImageDestinationCreateWithURL(outURL as CFURL, "public.png" as CFString, 1, nil) else {
    FileHandle.standardError.write(Data("failed to open \(outputPath) for writing\n".utf8))
    exit(1)
}
CGImageDestinationAddImage(dest, out, nil)
guard CGImageDestinationFinalize(dest) else {
    FileHandle.standardError.write(Data("failed to write PNG\n".utf8))
    exit(1)
}

print("wrote \(outputPath) with background rgb(\(Int(sample.r * 255)), \(Int(sample.g * 255)), \(Int(sample.b * 255)))")
