//
//  FWEffectBarItem.m
//  FWMeituApp
//
//  Created by ForrestWoo on 15-9-23.
//  Copyright (c) 2015年 ForrestWoo co,.ltd. All rights reserved.
//

#import "FWEffectBarItem.h"

@interface FWEffectBarItem ()
{
    NSString *_title;
    UIOffset _imagePositionAdjustment;
    NSDictionary *_unselectedTitleAttributes;
    NSDictionary *_selectedTitleAttributes;
}

@property UIImage *unselectedBackgroundImage;
@property UIImage *selectedBackgroundImage;
@property UIImage *unselectedImage;
@property UIImage *selectedImage;

@end

@implementation FWEffectBarItem

- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self commonInitialization];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        [self commonInitialization];
    }
    return self;
}

- (id)init
{
    return [self initWithFrame:CGRectZero];
}

- (void)commonInitialization {
    // Setup defaults
    
    [self setBackgroundColor:[UIColor clearColor]];
    self.ShowBorder = NO;
    self.titleOverlay = NO;
    _title = @"";
    _titlePositionAdjustment = UIOffsetZero;
    
    if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1) {
        _unselectedTitleAttributes = @{
                                       NSFontAttributeName: [UIFont systemFontOfSize:12],
                                       NSForegroundColorAttributeName: [UIColor whiteColor],
                                       NSBackgroundColorAttributeName:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.6]};
        _selectedTitleAttributes = @{
                                     NSFontAttributeName: [UIFont systemFontOfSize:12],
                                     NSForegroundColorAttributeName: [UIColor colorWithRed:17 / 255.0 green:129 / 255.0 blue:243 / 255.0 alpha:1],
                                     NSBackgroundColorAttributeName:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.6]
                                     };
    } else {
#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_7_0
        _unselectedTitleAttributes = @{
                                       UITextAttributeFont: [UIFont systemFontOfSize:12],
                                       UITextAttributeTextColor: [UIColor blackColor],
                                       };
        _selectedTitleAttributes = @{
                                     NSFontAttributeName: [UIFont systemFontOfSize:12],
                                     UITextAttributeTextColor: [UIColor colorWithRed:17 / 255.0 green:129 / 255.0 blue:243 / 255.0 alpha:1],
                                     };
#endif
    }
}

- (void)drawRect:(CGRect)rect
{
    
    CGSize frameSize = self.frame.size;
    CGSize imageSize = CGSizeZero;
    CGSize titleSize = CGSizeZero;
    NSDictionary *titleAttributes = nil;
    UIImage *backgroundImage = nil;
    UIImage *image = nil;
    CGFloat imageStartingY = 0.0f;
    
    if ([self isSelected])
    {
        if (self.ShowBorder)
        {
            self.layer.borderWidth = 2;
            self.layer.borderColor = [UIColor colorWithRed:13 / 255.0 green:99 / 255.0 blue:188 / 255.0 alpha:1.0].CGColor;
        }
        
        image = [self selectedImage];
        backgroundImage = [self selectedBackgroundImage];
        titleAttributes = [self selectedTitleAttributes];
        
        if (!titleAttributes)
        {
            titleAttributes = [self unselectedTitleAttributes];
        }
    }
    else
    {
        if (self.ShowBorder)
        {
            self.layer.borderWidth = 0;
        }
        image = [self unselectedImage];
        backgroundImage = [self unselectedBackgroundImage];
        titleAttributes = [self unselectedTitleAttributes];
    }
    
    imageSize = [image size];
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);
    [backgroundImage drawInRect:self.bounds];
    
    // Draw image and title
    
    if (![_title length])
    {
        [image drawInRect:CGRectMake(roundf(frameSize.width / 2 - imageSize.width / 2) +
                                     _imagePositionAdjustment.horizontal,
                                     roundf(frameSize.height / 2 - imageSize.height / 2) +
                                     _imagePositionAdjustment.vertical,
                                     imageSize.width, imageSize.height)];
    }
    else
    {
        CGSize ts = CGSizeMake(frameSize.width, 20);
        titleSize = [_title boundingRectWithSize:ts
                                         options:NSStringDrawingUsesLineFragmentOrigin
                                      attributes:titleAttributes
                                         context:nil].size;
        
         if (!self.titleOverlay)
        {
            CGSize ts = CGSizeMake(frameSize.width, 20);
            titleSize = [_title boundingRectWithSize:ts
                                             options:NSStringDrawingUsesLineFragmentOrigin
                                          attributes:titleAttributes
                                             context:nil].size;
            
            imageStartingY = roundf((frameSize.height - imageSize.height - titleSize.height) / 2);
            CGRect frame = CGRectMake(roundf(frameSize.width / 2 - imageSize.width / 2) +
                                      _imagePositionAdjustment.horizontal,
                                      imageStartingY + _imagePositionAdjustment.vertical,
                                      imageSize.width, imageSize.height);
            [image drawInRect:frame];
            
            CGContextSetFillColorWithColor(context, [titleAttributes[NSForegroundColorAttributeName] CGColor]);
            
            CGRect frame1 = CGRectMake(roundf(frameSize.width / 2 - titleSize.width / 2) +
                                       _titlePositionAdjustment.horizontal,
                                       imageStartingY + imageSize.height + _titlePositionAdjustment.vertical,
                                       titleSize.width, titleSize.height);
            [_title drawInRect:frame1
                withAttributes:titleAttributes];
        }
        else
        {
            [image drawInRect:CGRectMake(roundf(frameSize.width / 2 - imageSize.width / 2) +
                                         _imagePositionAdjustment.horizontal,
                                         roundf(frameSize.height / 2 - imageSize.height / 2) +
                                         _imagePositionAdjustment.vertical,
                                         imageSize.width, imageSize.height)];
            [_title drawInRect:CGRectMake(roundf(frameSize.width / 2 - titleSize.width / 2) +
                                          _titlePositionAdjustment.horizontal, frameSize.height - 20, titleSize.width, titleSize.height)
             
                withAttributes:titleAttributes];
        }
    }
    
    CGContextRestoreGState(context);
}

- (UIImage *)fixOrientation:(UIImage *)aImage {
    
    // No-op if the orientation is already correct
    if (aImage.imageOrientation == UIImageOrientationUp)
        return aImage;
    
    // We need to calculate the proper transformation to make the image upright.
    // We do it in 2 steps: Rotate if Left/Right/Down, and then flip if Mirrored.
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    switch (aImage.imageOrientation) {
        case UIImageOrientationDown:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.width, aImage.size.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
            
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.width, 0);
            transform = CGAffineTransformRotate(transform, M_PI_2);
            break;
            
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, 0, aImage.size.height);
            transform = CGAffineTransformRotate(transform, -M_PI_2);
            break;
        default:
            break;
    }
    
    switch (aImage.imageOrientation) {
        case UIImageOrientationUpMirrored:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.width, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
            
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.height, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
        default:
            break;
    }
    
    // Now we draw the underlying CGImage into a new context, applying the transform
    // calculated above.
    CGContextRef ctx = CGBitmapContextCreate(NULL, aImage.size.width, aImage.size.height,
                                             CGImageGetBitsPerComponent(aImage.CGImage), 0,
                                             CGImageGetColorSpace(aImage.CGImage),
                                             CGImageGetBitmapInfo(aImage.CGImage));
    CGContextConcatCTM(ctx, transform);
    switch (aImage.imageOrientation) {
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            // Grr...
            CGContextDrawImage(ctx, CGRectMake(0,0,aImage.size.height,aImage.size.width), aImage.CGImage);
            break;
            
        default:
            CGContextDrawImage(ctx, CGRectMake(0,0,aImage.size.width,aImage.size.height), aImage.CGImage);
            break;
    }
    
    // And now we just create a new UIImage from the drawing context
    CGImageRef cgimg = CGBitmapContextCreateImage(ctx);
    UIImage *img = [UIImage imageWithCGImage:cgimg];
    CGContextRelease(ctx);
    CGImageRelease(cgimg);
    return img;
}

- (UIImage *)finishedSelectedImage
{
    return [self selectedImage];
}

- (UIImage *)finishedUnselectedImage
{
    return [self unselectedImage];
}

- (void)setFinishedSelectedImage:(UIImage *)selectedImage withFinishedUnselectedImage:(UIImage *)unselectedImage
{
    if (selectedImage && (selectedImage != [self selectedImage])) {
        [self setSelectedImage:selectedImage];
    }
    
    if (unselectedImage && (unselectedImage != [self unselectedImage])) {
        [self setUnselectedImage:unselectedImage];
    }
}


- (UIImage *)backgroundSelectedImage {
    return [self selectedBackgroundImage];
}

- (UIImage *)backgroundUnselectedImage {
    return [self unselectedBackgroundImage];
}

- (void)setBackgroundSelectedImage:(UIImage *)selectedImage withUnselectedImage:(UIImage *)unselectedImage {
    if (selectedImage && (selectedImage != [self selectedBackgroundImage])) {
        [self setSelectedBackgroundImage:selectedImage];
    }
    
    if (unselectedImage && (unselectedImage != [self unselectedBackgroundImage])) {
        [self setUnselectedBackgroundImage:unselectedImage];
    }
}

@end
