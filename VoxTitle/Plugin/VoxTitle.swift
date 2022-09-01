//
//  VoxTitle.swift
//  VoxTitle
//
//  Created by Martin Ivančo on 13/08/2022.
//

import CoreGraphics
import CoreImage
import CoreText
import os

@objc(VoxTitle) class VoxTitle: NSObject, FxTileableEffect {
    struct Color: Codable {
        let r: Double
        let g: Double
        let b: Double
    }

    struct Parameters: Codable {
        let text: String
        static let textId: UInt32 = 1
        static let textDefault = "Vox Title"

        let font: String
        static let fontId: UInt32 = 2
        static let fontDefault = "Helvetica"

        let size: Double
        static let sizeId: UInt32 = 3
        static let sizeDefault = 72.0

        let textColor: Color
        static let textColorId: UInt32 = 4
        static let textColorDefault = Color(r: 0, g: 0, b: 0)

        let backgroundEnabled: Bool
        static let backgroundEnabledId: UInt32 = 5
        static let backgroundEnabledDefault = true

        let backgroundColor: Color
        static let backgroundColorId: UInt32 = 6
        static let backgroundColorDefault = Color(r: 1, g: 1, b: 0)

        let backgroundMargin: Double
        static let backgroundMarginId: UInt32 = 7
        static let backgroundMarginDefault = 12.0

        let buildInDuration: Double
        static let buildInDurationId: UInt32 = 8
        static let buildInDurationDefault = 1.0

        let buildInCurvature: Double
        static let buildInCurvatureId: UInt32 = 9
        static let buildInCurvatureDefault = 0.5

        init(
            text: String, font: String, size: Double, textColor: Color, backgroundEnabled: Bool,
            backgroundColor: Color, backgroundMargin: Double, buildInDuration: Double,
            buildInCurvature: Double
        ) {
            self.text = text
            self.font = font
            self.size = size
            self.textColor = textColor
            self.backgroundEnabled = backgroundEnabled
            self.backgroundColor = backgroundColor
            self.backgroundMargin = backgroundMargin
            self.buildInDuration = buildInDuration
            self.buildInCurvature = buildInCurvature
        }

        init() {
            self.init(
                text: Parameters.textDefault, font: Parameters.fontDefault,
                size: Parameters.sizeDefault, textColor: Parameters.textColorDefault,
                backgroundEnabled: Parameters.backgroundEnabledDefault,
                backgroundColor: Parameters.backgroundColorDefault,
                backgroundMargin: Parameters.backgroundMarginDefault,
                buildInDuration: Parameters.buildInDurationDefault,
                buildInCurvature: Parameters.buildInCurvatureDefault)
        }
    }

    let apiAccess: PROAPIAccessing
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()

    required init?(apiManager: PROAPIAccessing) {
        apiAccess = apiManager
    }

    func addParameters() throws {
        let api = apiAccess.api(for: FxParameterCreationAPI_v5.self) as! FxParameterCreationAPI_v5
        let flags = FxParameterFlags(kFxParameterFlag_DEFAULT)

        api.addStringParameter(
            withName: "Text", parameterID: Parameters.textId, defaultValue: Parameters.textDefault,
            parameterFlags: flags)
        api.addFontMenu(
            withName: "Font", parameterID: Parameters.fontId, fontName: Parameters.fontDefault,
            parameterFlags: flags)
        api.addFloatSlider(
            withName: "Size", parameterID: Parameters.sizeId, defaultValue: Parameters.sizeDefault,
            parameterMin: 0, parameterMax: 1000, sliderMin: 0, sliderMax: 100, delta: 1,
            parameterFlags: flags)
        api.addColorParameter(
            withName: "Text Color", parameterID: Parameters.textColorId,
            defaultRed: Parameters.textColorDefault.r, defaultGreen: Parameters.textColorDefault.g,
            defaultBlue: Parameters.textColorDefault.b, parameterFlags: flags)
        api.addToggleButton(
            withName: "Enable Background", parameterID: Parameters.backgroundEnabledId,
            defaultValue: Parameters.backgroundEnabledDefault, parameterFlags: flags)
        api.addColorParameter(
            withName: "Background Color", parameterID: Parameters.backgroundColorId,
            defaultRed: Parameters.backgroundColorDefault.r,
            defaultGreen: Parameters.backgroundColorDefault.g,
            defaultBlue: Parameters.backgroundColorDefault.b, parameterFlags: flags)
        api.addFloatSlider(
            withName: "Background Margin", parameterID: Parameters.backgroundMarginId,
            defaultValue: Parameters.backgroundMarginDefault, parameterMin: 0, parameterMax: 1000,
            sliderMin: 0, sliderMax: 100, delta: 1, parameterFlags: flags)
        api.addFloatSlider(
            withName: "Build In Duration", parameterID: Parameters.buildInDurationId,
            defaultValue: Parameters.buildInDurationDefault, parameterMin: 0, parameterMax: 100,
            sliderMin: 0, sliderMax: 10, delta: 0.1, parameterFlags: flags)
        api.addFloatSlider(
            withName: "Build In Curvature", parameterID: Parameters.buildInCurvatureId,
            defaultValue: Parameters.buildInCurvatureDefault, parameterMin: 0, parameterMax: 0.99,
            sliderMin: 0, sliderMax: 0.99, delta: 0.01, parameterFlags: flags)
    }

    func properties(_ properties: AutoreleasingUnsafeMutablePointer<NSDictionary>?) throws {
        properties?.pointee = NSDictionary(dictionary: [
            kFxPropertyKey_ChangesOutputSize: NSNumber(booleanLiteral: false),
            kFxPropertyKey_MayRemapTime: NSNumber(booleanLiteral: false),
            kFxPropertyKey_NeedsFullBuffer: NSNumber(booleanLiteral: true),
            kFxPropertyKey_PixelTransformSupport: NSNumber(value: kFxPixelTransform_Scale),
            kFxPropertyKey_VariesWhenParamsAreStatic: NSNumber(booleanLiteral: false),
        ])
    }

    func pluginState(
        _ pluginState: AutoreleasingUnsafeMutablePointer<NSData>?, at renderTime: CMTime,
        quality qualityLevel: UInt
    ) throws {
        let api = apiAccess.api(for: FxParameterRetrievalAPI_v6.self) as! FxParameterRetrievalAPI_v6

        var text = Parameters.textDefault as NSString
        api.getStringParameterValue(&text, fromParameter: Parameters.textId)

        var font = Parameters.fontDefault as NSString
        api.getFontName(&font, fromParameter: Parameters.fontId, at: renderTime)

        var size = Parameters.sizeDefault
        api.getFloatValue(&size, fromParameter: Parameters.sizeId, at: renderTime)

        var textColorR = Parameters.textColorDefault.r
        var textColorG = Parameters.textColorDefault.g
        var textColorB = Parameters.textColorDefault.b
        api.getRedValue(
            &textColorR, greenValue: &textColorG, blueValue: &textColorB,
            fromParameter: Parameters.textColorId, at: renderTime)

        var backgroundEnabled = ObjCBool(Parameters.backgroundEnabledDefault)
        api.getBoolValue(
            &backgroundEnabled, fromParameter: Parameters.backgroundEnabledId, at: renderTime)

        var backgroundColorR = Parameters.backgroundColorDefault.r
        var backgroundColorG = Parameters.backgroundColorDefault.g
        var backgroundColorB = Parameters.backgroundColorDefault.b
        api.getRedValue(
            &backgroundColorR, greenValue: &backgroundColorG, blueValue: &backgroundColorB,
            fromParameter: Parameters.backgroundColorId, at: renderTime)

        var backgroundMargin = Parameters.backgroundMarginDefault
        api.getFloatValue(
            &backgroundMargin, fromParameter: Parameters.backgroundMarginId, at: renderTime)

        var buildInDuration = Parameters.buildInDurationDefault
        api.getFloatValue(
            &buildInDuration, fromParameter: Parameters.buildInDurationId, at: renderTime)

        var buildInCurvature = Parameters.buildInCurvatureDefault
        api.getFloatValue(
            &buildInCurvature, fromParameter: Parameters.buildInCurvatureId, at: renderTime)

        let parameters = Parameters(
            text: text as String, font: font as String, size: size,
            textColor: Color(r: textColorR, g: textColorG, b: textColorB),
            backgroundEnabled: backgroundEnabled.boolValue,
            backgroundColor: Color(r: backgroundColorR, g: backgroundColorG, b: backgroundColorB),
            backgroundMargin: backgroundMargin, buildInDuration: buildInDuration,
            buildInCurvature: buildInCurvature)
        pluginState?.pointee = try encoder.encode(parameters) as NSData
    }

    func destinationImageRect(
        _ destinationImageRect: UnsafeMutablePointer<FxRect>, sourceImages: [FxImageTile],
        destinationImage: FxImageTile, pluginState: Data?, at renderTime: CMTime
    ) throws {
        destinationImageRect.pointee = kFxRect_Infinite
    }

    func sourceTileRect(
        _ sourceTileRect: UnsafeMutablePointer<FxRect>, sourceImageIndex: UInt,
        sourceImages: [FxImageTile], destinationTileRect: FxRect, destinationImage: FxImageTile,
        pluginState: Data?, at renderTime: CMTime
    ) throws {
        sourceTileRect.pointee = kFxRect_Empty
    }

    func easyEase(x: Double, curvature c: Double) -> Double {
        func f(_ a: Double) -> Double {
            return (6 * c - 2) * pow(a, 3) + (-9 * c + 3) * pow(a, 2) + 3 * c * a - x
        }

        func fd(_ a: Double) -> Double {
            return (18 * c - 6) * pow(a, 2) + (-18 * c + 6) * a + 3 * c
        }

        var a = 0.5
        for _ in 1...100 {
            let y = f(a)
            let yd = fd(a)

            if abs(yd) < 0.001 { break }

            let na = a - y / yd

            if abs(na - a) < 0.001 {
                a = na
                break
            }

            a = na
        }

        return 3 * pow(a, 2) - 2 * pow(a, 3)
    }

    func renderDestinationImage(
        _ destinationImage: FxImageTile, sourceImages: [FxImageTile], pluginState: Data?,
        at renderTime: CMTime
    ) throws {
        let parameters =
            pluginState == nil
            ? Parameters() : try decoder.decode(Parameters.self, from: pluginState!)

        let imageBounds = destinationImage.imagePixelBounds
        let canvasSize = CGSize(
            width: CGFloat(imageBounds.right - imageBounds.left),
            height: CGFloat(imageBounds.top - imageBounds.bottom))
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let canvas = CGContext(
            data: nil, width: Int(canvasSize.width), height: Int(canvasSize.height),
            bitsPerComponent: 8, bytesPerRow: Int(canvasSize.width) * 4, space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        canvas.translateBy(x: 0, y: canvasSize.height)
        canvas.scaleBy(x: 1, y: -1)

        let font =
            NSFont(name: parameters.font, size: parameters.size)
            ?? NSFont.systemFont(ofSize: parameters.size)
        let text = NSAttributedString(
            string: parameters.text,
            attributes: [
                .font: font,
                .foregroundColor: NSColor(
                    red: parameters.textColor.r, green: parameters.textColor.g,
                    blue: parameters.textColor.b, alpha: 1),
            ])
        let line = CTLineCreateWithAttributedString(text)
        let lineBounds = CTLineGetImageBounds(line, canvas)
        let linePosition = CGPoint(
            x: (canvasSize.width - lineBounds.width) / 2,
            y: (canvasSize.height - lineBounds.height) / 2)

        let clipRect = CGRect(
            x: linePosition.x - parameters.backgroundMargin,
            y: linePosition.y - parameters.backgroundMargin,
            width: lineBounds.width + parameters.backgroundMargin * 2,
            height: lineBounds.height + parameters.backgroundMargin * 2)
        canvas.clip(to: clipRect)

        var offset = 0.0
        if parameters.buildInDuration > 0.01 {
            offset =
                max(parameters.buildInDuration - renderTime.seconds, 0) / parameters.buildInDuration
            offset =
                parameters.buildInCurvature > 0.01
                ? easyEase(x: offset, curvature: parameters.buildInCurvature) : offset
        }

        if parameters.backgroundEnabled {
            canvas.setFillColor(
                CGColor(
                    red: parameters.backgroundColor.r, green: parameters.backgroundColor.g,
                    blue: parameters.backgroundColor.b, alpha: 1))
            canvas.fill(clipRect.offsetBy(dx: offset * -clipRect.width, dy: 0))
        }

        canvas.textPosition = linePosition.applying(
            CGAffineTransform(translationX: 0, y: offset * -clipRect.height))
        CTLineDraw(line, canvas)

        CIContext().render(
            CIImage(cgImage: canvas.makeImage()!), to: destinationImage.ioSurface,
            bounds: CGRect(
                x: 0, y: 0, width: destinationImage.ioSurface.width,
                height: destinationImage.ioSurface.height), colorSpace: colorSpace)
    }
}
