//
//  QMImageHelper.h
//  GPUImageFilter
//
//  Created by qinmin on 2017/5/7.
//  Copyright © 2017年 Qinmin. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface QMImageHelper : NSObject

/**
 Converts a UIImage to RGBA8 bitmap.
 @param image - a UIImage to be converted
 @return a RGBA8 bitmap, or NULL if any memory allocation issues. Cleanup memory with free() when done.
 */
+ (unsigned char *)convertUIImageToBitmapRGBA8:(UIImage *)image;

/**
 A helper routine used to convert a RGBA8 to UIImage
 @return a new context that is owned by the caller
 */
+ (CGContextRef)newBitmapRGBA8ContextFromImage:(CGImageRef)image;


/**
 Converts a RGBA8 bitmap to a UIImage.
 @param buffer - the RGBA8 unsigned char * bitmap
 @param width - the number of pixels wide
 @param height - the number of pixels tall
 @return a UIImage that is autoreleased or nil if memory allocation issues
 */
+ (UIImage *)convertBitmapRGBA8ToUIImage:(unsigned char *)buffer
                               withWidth:(int)width
                              withHeight:(int)height;


/**
 Create a CGImageRef from sample buffer data
 @param sampleBuffer - the BGEA SampleBuffer
 @return a CGImageRef
 */
+ (CGImageRef)imageFromSampleBuffer:(CMSampleBufferRef)sampleBuffer;


/**
 Create a CGImageRef from sample buffer data
 @param pixelBuffer - the CVPixelBufferRef
 @return a CGImageRef
 */
+ (CGImageRef)imageFromPixelBuffer:(CVPixelBufferRef)pixelBuffer;

/**
 Create a CVPixelBufferRef from UIImage

 @param image - the image to convert
 @param size - the image size
 @return a CVPixelBufferRef
 */
+ (CVPixelBufferRef)convertToCVPixelBufferRefFromImage:(CGImageRef)image
                                              withSize:(CGSize)size;
@end
