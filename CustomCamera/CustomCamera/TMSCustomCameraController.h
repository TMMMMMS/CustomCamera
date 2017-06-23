//
//  TMSCustomCameraController.h
//  CustomCamera
//
//  Created by WuYaoDong on 2017/6/23.
//  Copyright © 2017年 TMS. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol TMSCustomCameraControllerDelegate <NSObject>

@optional
- (void)photoCapViewController:(UIViewController *)viewController didFinishDismissWithImage:(UIImage *)image;

@end

@interface TMSCustomCameraController : UIViewController

@property(nonatomic,weak)id<TMSCustomCameraControllerDelegate> delegate;

@end
