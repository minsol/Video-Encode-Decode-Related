//
//  FunctionalCoreImage.swift
//  CoreImageVideo
//
//  Created by Chris Eidhof on 03/04/15.
//  Copyright (c) 2015 objc.io. All rights reserved.
//

import Foundation
import UIKit

typealias Filter = (CIImage) -> CIImage

func blur(_ radius: Double) -> Filter {
    return { image in
        let parameters = [
            kCIInputRadiusKey: radius,
            kCIInputImageKey: image
        ] as [String : Any]
        let filter = CIFilter(name: "CIGaussianBlur",
            withInputParameters: parameters)
        return filter!.outputImage!
    }
}

func colorGenerator(_ color: UIColor) -> Filter {
    return { _ in
        let parameters = [kCIInputColorKey: color]
        let filter = CIFilter(name: "CIConstantColorGenerator",
            withInputParameters: parameters)
        return filter!.outputImage!
    }
}

func hueAdjust(_ angleInRadians: Float) -> Filter {
    return { image in
        let parameters = [
            kCIInputAngleKey: angleInRadians,
            kCIInputImageKey: image
        ] as [String : Any]
        let filter = CIFilter(name: "CIHueAdjust",
            withInputParameters: parameters)
        return filter!.outputImage!
    }
}

func pixellate(_ scale: Float) -> Filter {
    return { image in
        let parameters = [
            kCIInputImageKey:image,
            kCIInputScaleKey:scale
        ] as [String : Any]
        return CIFilter(name: "CIPixellate", withInputParameters: parameters)!.outputImage!
    }
}

func kaleidoscope() -> Filter {
    return { image in
        let parameters = [
            kCIInputImageKey:image,
        ]
        return CIFilter(name: "CITriangleKaleidoscope", withInputParameters: parameters)!.outputImage!.cropping(to: image.extent)
    }
}


func vibrance(_ amount: Float) -> Filter {
    return { image in
        let parameters = [
            kCIInputImageKey: image,
            "inputAmount": amount
        ] as [String : Any]
        return CIFilter(name: "CIVibrance", withInputParameters: parameters)!.outputImage!
    }
}

func compositeSourceOver(_ overlay: CIImage) -> Filter {
    return { image in
        let parameters = [
            kCIInputBackgroundImageKey: image,
            kCIInputImageKey: overlay
        ]
        let filter = CIFilter(name: "CISourceOverCompositing",
            withInputParameters: parameters)
        let cropRect = image.extent
        return filter!.outputImage!.cropping(to: cropRect)
    }
}


func radialGradient(_ center: CGPoint, radius: CGFloat) -> CIImage {
    let params: [String: Any] = [
        "inputColor0": CIColor(red: 1, green: 1, blue: 1),
        "inputColor1": CIColor(red: 0, green: 0, blue: 0),
        "inputCenter": CIVector(cgPoint: center),
        "inputRadius0": radius,
        "inputRadius1": radius + 1
    ]
    return CIFilter(name: "CIRadialGradient", withInputParameters: params)!.outputImage!
}

func blendWithMask(_ background: CIImage, mask: CIImage) -> Filter {
    return { image in
        let parameters = [
            kCIInputBackgroundImageKey: background,
            kCIInputMaskImageKey: mask,
            kCIInputImageKey: image
        ]
        let filter = CIFilter(name: "CIBlendWithMask",
            withInputParameters: parameters)
        let cropRect = image.extent
        return filter!.outputImage!.cropping(to: cropRect)
    }
}

func colorOverlay(_ color: UIColor) -> Filter {
    return { image in
        let overlay = colorGenerator(color)(image)
        return compositeSourceOver(overlay)(image)
    }
}


//infix operator >>> { associativity left }
//
//func >>> (filter1: @escaping Filter, filter2: @escaping Filter) -> Filter {
//    return { img in filter2(filter1(img)) }
//}
