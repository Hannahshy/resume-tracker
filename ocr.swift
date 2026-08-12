import AppKit
import Foundation
import Vision

struct OCRResponse: Codable {
    let text: String
}

func emitError(_ message: String, code: Int32 = 1) -> Never {
    FileHandle.standardError.write(Data(message.utf8))
    exit(code)
}

guard CommandLine.arguments.count > 1 else {
    emitError("缺少图片路径")
}

let imageURL = URL(fileURLWithPath: CommandLine.arguments[1])
guard let image = NSImage(contentsOf: imageURL),
      let imageData = image.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: imageData),
      let cgImage = bitmap.cgImage else {
    emitError("无法读取图片")
}

let request = VNRecognizeTextRequest()
request.recognitionLevel = .accurate
request.usesLanguageCorrection = true
request.recognitionLanguages = ["zh-Hans", "zh-Hant", "en-US"]

do {
    let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
    try handler.perform([request])
    let observations = request.results ?? []
    let lines = observations.compactMap { observation in
        observation.topCandidates(1).first.map { candidate in
            (text: candidate.string, y: observation.boundingBox.midY, x: observation.boundingBox.minX)
        }
    }
    .sorted {
        if abs($0.y - $1.y) > 0.012 { return $0.y > $1.y }
        return $0.x < $1.x
    }
    .map(\.text)

    let output = OCRResponse(text: lines.joined(separator: "\n"))
    let data = try JSONEncoder().encode(output)
    FileHandle.standardOutput.write(data)
} catch {
    emitError("文字识别失败：\(error.localizedDescription)")
}
