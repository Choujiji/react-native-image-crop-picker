//
//  Compression.m
//  imageCropPicker
//
//  Created by Ivan Pusic on 12/24/16.
//  Copyright © 2016 Ivan Pusic. All rights reserved.
//

#import "Compression.h"
#import "UIImage-Resize/UIImage+Resize.h"

@implementation Compression

- (instancetype)init {
    NSMutableDictionary *dic = [[NSMutableDictionary alloc] initWithDictionary:@{
                                                                                 @"640x480": AVAssetExportPreset640x480,
                                                                                 @"960x540": AVAssetExportPreset960x540,
                                                                                 @"1280x720": AVAssetExportPreset1280x720,
                                                                                 @"1920x1080": AVAssetExportPreset1920x1080,
                                                                                 @"LowQuality": AVAssetExportPresetLowQuality,
                                                                                 @"MediumQuality": AVAssetExportPresetMediumQuality,
                                                                                 @"HighestQuality": AVAssetExportPresetHighestQuality,
                                                                                 }];
    NSOperatingSystemVersion systemVersion = [[NSProcessInfo processInfo] operatingSystemVersion];
    if (systemVersion.majorVersion >= 9) {
        [dic addEntriesFromDictionary:@{@"3840x2160": AVAssetExportPreset3840x2160}];
    }
    self.exportPresets = dic;
    
    return self;
}

- (ImageResult*) compressImageDimensions:(UIImage*)image
                             withOptions:(NSDictionary*)options {
    NSNumber *maxWidth = [options valueForKey:@"compressImageMaxWidth"];
    NSNumber *maxHeight = [options valueForKey:@"compressImageMaxHeight"];
    ImageResult *result = [[ImageResult alloc] init];
    
    if ([maxWidth integerValue] == 0 && [maxWidth integerValue] == 0) {
        result.width = [NSNumber numberWithFloat:image.size.width];
        result.height = [NSNumber numberWithFloat:image.size.height];
        result.image = image;
        return result;
    }
    
    CGFloat oldWidth = image.size.width;
    CGFloat oldHeight = image.size.height;
    
    
    //指定了最大宽度
    if (([maxWidth integerValue] > 0) &&
        (oldWidth > [maxWidth integerValue])) {//需要裁剪 且 原图尺寸大于最大设定尺寸
        //裁剪图片
        CGFloat scaledImageWidth = [maxWidth floatValue];
        CGFloat scaledImageHeight = oldHeight / oldWidth * scaledImageWidth;
        UIImage *resizedImage = [image resizedImageToFitInSize:CGSizeMake(scaledImageWidth, scaledImageHeight) scaleIfSmaller:NO];
        
        result.width = [NSNumber numberWithFloat:scaledImageWidth];
        result.height = [NSNumber numberWithFloat:scaledImageHeight];
        result.image = resizedImage;
        return result;
    }
    
    
    //最大宽度和最大高度都指定了
    if ([maxWidth integerValue] != 0 && [maxWidth integerValue] != 0) {
        CGFloat scaleFactor = (oldWidth > oldHeight) ? [maxWidth floatValue] / oldWidth : [maxHeight floatValue] / oldHeight;
        
        int newWidth = oldWidth * scaleFactor;
        int newHeight = oldHeight * scaleFactor;
        CGSize newSize = CGSizeMake(newWidth, newHeight);
        
        UIGraphicsBeginImageContext(newSize);
        [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
        UIImage *resizedImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        result.width = [NSNumber numberWithFloat:newWidth];
        result.height = [NSNumber numberWithFloat:newHeight];
        result.image = resizedImage;
        return result;
    }
}

- (ImageResult*) compressImage:(UIImage*)image
                   withOptions:(NSDictionary*)options {
    ImageResult *result = [self compressImageDimensions:image withOptions:options];
    
    NSNumber *compressQuality = [options valueForKey:@"compressImageQuality"];
    if (compressQuality == nil) {
        compressQuality = [NSNumber numberWithFloat:1];
    }
    
    result.data = UIImageJPEGRepresentation(result.image, [compressQuality floatValue]);
    result.mime = @"image/jpeg";
    
    return result;
}

- (void)compressVideo:(NSURL*)inputURL
            outputURL:(NSURL*)outputURL
          withOptions:(NSDictionary*)options
              handler:(void (^)(AVAssetExportSession*))handler {
    
    NSString *presetKey = [options valueForKey:@"compressVideoPreset"];
    if (presetKey == nil) {
        presetKey = @"MediumQuality";
    }
    
    NSString *preset = [self.exportPresets valueForKey:presetKey];
    if (preset == nil) {
        preset = AVAssetExportPresetMediumQuality;
    }
    
    [[NSFileManager defaultManager] removeItemAtURL:outputURL error:nil];
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:inputURL options:nil];
    AVAssetExportSession *exportSession = [[AVAssetExportSession alloc] initWithAsset:asset presetName:preset];
    exportSession.shouldOptimizeForNetworkUse = YES;
    exportSession.outputURL = outputURL;
    exportSession.outputFileType = AVFileTypeMPEG4;
    
    [exportSession exportAsynchronouslyWithCompletionHandler:^(void) {
        handler(exportSession);
    }];
}

@end
