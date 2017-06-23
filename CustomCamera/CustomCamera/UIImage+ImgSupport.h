//
//  UIImage+ImgSupport.h
//  CustomCamera
//
//  Created by WuYaoDong on 2017/6/23.
//  Copyright © 2017年 TMS. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (ImgSupport)

/* 调用系统相机完成拍照后 ，照片自动旋转90°的解决方法 */
+ (UIImage *)fixOrientation:(UIImage *)aImage;

+(UIImage *) scaleImage:(UIImage *)sourceImage targetHeight:(CGFloat)defineHeight;

@end
