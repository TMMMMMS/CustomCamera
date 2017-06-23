//
//  TMSCustomCameraController.m
//  CustomCamera
//
//  Created by WuYaoDong on 2017/6/23.
//  Copyright © 2017年 TMS. All rights reserved.
//

#import "TMSCustomCameraController.h"
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "PhotoPrettifiedController.h"
#import "UIImage+ImgSupport.h"
#import "FWEffectBar.h"
#import "FWApplyFilter.h"
#import <SDAutoLayout.h>

#define Device_Height [[UIScreen mainScreen] bounds].size.height
#define Device_Width  [[UIScreen mainScreen] bounds].size.width
#define  ScreenScale  Device_Width/375

@interface TMSCustomCameraController ()<UIGestureRecognizerDelegate,FWEffectBarDelegate>

@property(nonatomic, strong)UIView *photoContainer;
@property(nonatomic, strong)UIImageView *photoView;

@property(nonatomic, strong)UIView *backView;

@property(nonatomic, strong)UIImage *picImg;
@property(nonatomic, strong)UIImage *currentImg;
//AVFoundation

@property (nonatomic) dispatch_queue_t sessionQueue;
/**
 *  AVCaptureSession对象来执行输入设备和输出设备之间的数据传递
 */
@property (nonatomic, strong) AVCaptureSession* session;
/**
 *  输入设备
 */
@property (nonatomic, strong) AVCaptureDeviceInput* videoInput;
/**
 *  照片输出流
 */
@property (nonatomic, strong) AVCaptureStillImageOutput* stillImageOutput;
/**
 *  预览图层
 */
@property (nonatomic, strong) AVCaptureVideoPreviewLayer* previewLayer;

/**
 *  记录开始的缩放比例
 */
@property(nonatomic,assign)CGFloat beginGestureScale;
/**
 *  最后的缩放比例
 */
@property(nonatomic,assign)CGFloat effectiveScale;

@property (nonatomic, strong) FWEffectBar *filterStyleBar;
@end

@implementation TMSCustomCameraController

{
    
    BOOL isUsingFrontFacingCamera;
}

#pragma mark life circle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationController.navigationBar.hidden = YES;
    
    [self configViews];
    [self configPhotoViews];
    
    [self initAVCaptureSession];
    
    [self setUpGesture];
    
    isUsingFrontFacingCamera = NO;
    
    self.effectiveScale = self.beginGestureScale = 1.0f;
    
}

- (void)viewWillAppear:(BOOL)animated{
    
    [super viewWillAppear:YES];
    
    if (self.session) {
        
        [self.session startRunning];
    }
}

- (void)viewDidDisappear:(BOOL)animated{
    
    [super viewDidDisappear:YES];
    
    if (self.session) {
        
        [self.session stopRunning];
    }
}
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark private method
- (void)initAVCaptureSession{
    
    self.session = [[AVCaptureSession alloc] init];
    
    NSError *error;
    
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    //更改这个设置的时候必须先锁定设备，修改完后再解锁，否则崩溃
    [device lockForConfiguration:nil];
    //设置闪光灯为自动
    [device setFlashMode:AVCaptureFlashModeAuto];
    [device unlockForConfiguration];
    
    self.videoInput = [[AVCaptureDeviceInput alloc] initWithDevice:device error:&error];
    if (error) {
        NSLog(@"%@",error);
    }
    self.stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
    //输出设置。AVVideoCodecJPEG   输出jpeg格式图片
    NSDictionary * outputSettings = [[NSDictionary alloc] initWithObjectsAndKeys:AVVideoCodecJPEG,AVVideoCodecKey, nil];
    [self.stillImageOutput setOutputSettings:outputSettings];
    
    if ([self.session canAddInput:self.videoInput]) {
        [self.session addInput:self.videoInput];
    }
    if ([self.session canAddOutput:self.stillImageOutput]) {
        [self.session addOutput:self.stillImageOutput];
    }
    
    //初始化预览图层
    self.previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
    [self.previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    NSLog(@"%f",Device_Width);
    self.previewLayer.frame = CGRectMake(0, 0, Device_Width, Device_Height  - 64 - 80*ScreenScale);
    self.backView.layer.masksToBounds = NO;
    [self.backView.layer addSublayer:self.previewLayer];
    
}


- (AVCaptureVideoOrientation)avOrientationForDeviceOrientation:(UIDeviceOrientation)deviceOrientation
{
    AVCaptureVideoOrientation result = (AVCaptureVideoOrientation)deviceOrientation;
    if ( deviceOrientation == UIDeviceOrientationLandscapeLeft )
        result = AVCaptureVideoOrientationLandscapeRight;
    else if ( deviceOrientation == UIDeviceOrientationLandscapeRight )
        result = AVCaptureVideoOrientationLandscapeLeft;
    return result;
}

#pragma 创建手势
- (void)setUpGesture{
    
    UIPinchGestureRecognizer *pinch = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinchGesture:)];
    pinch.delegate = self;
    [self.backView addGestureRecognizer:pinch];
}

#pragma mark gestureRecognizer delegate
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if ( [gestureRecognizer isKindOfClass:[UIPinchGestureRecognizer class]] ) {
        self.beginGestureScale = self.effectiveScale;
    }
    return YES;
}

#pragma mark respone method
//切换镜头
- (void)switchCameraSegmentedControlClick:(UIButton *)sender {
    
    //    NSLog(@"%ld",(long)sender.selectedSegmentIndex);
    
    AVCaptureDevicePosition desiredPosition;
    if (isUsingFrontFacingCamera){
        desiredPosition = AVCaptureDevicePositionBack;
    }else{
        desiredPosition = AVCaptureDevicePositionFront;
    }
    
    for (AVCaptureDevice *d in [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo]) {
        if ([d position] == desiredPosition) {
            [self.previewLayer.session beginConfiguration];
            AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:d error:nil];
            for (AVCaptureInput *oldInput in self.previewLayer.session.inputs) {
                [[self.previewLayer session] removeInput:oldInput];
            }
            [self.previewLayer.session addInput:input];
            [self.previewLayer.session commitConfiguration];
            break;
        }
    }
    
    isUsingFrontFacingCamera = !isUsingFrontFacingCamera;
}
- (void)takePhotoButtonClick:(UIButton *)sender {
    
    NSLog(@"takephotoClick...");
    AVCaptureConnection *stillImageConnection = [self.stillImageOutput connectionWithMediaType:AVMediaTypeVideo];
    UIDeviceOrientation curDeviceOrientation = [[UIDevice currentDevice] orientation];
    AVCaptureVideoOrientation avcaptureOrientation = [self avOrientationForDeviceOrientation:curDeviceOrientation];
    [stillImageConnection setVideoOrientation:avcaptureOrientation];
    [stillImageConnection setVideoScaleAndCropFactor:self.effectiveScale];
    
    [self.stillImageOutput captureStillImageAsynchronouslyFromConnection:stillImageConnection completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
        
        NSData *jpegData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
        CFDictionaryRef attachments = CMCopyDictionaryOfAttachments(kCFAllocatorDefault,
                                                                    imageDataSampleBuffer,
                                                                    kCMAttachmentMode_ShouldPropagate);
        
        ALAuthorizationStatus author = [ALAssetsLibrary authorizationStatus];
        if (author == ALAuthorizationStatusRestricted || author == ALAuthorizationStatusDenied){
            //无权限
            return ;
        }
        
        __weak typeof(self) weakSelf = self;
        
        ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
        [library writeImageDataToSavedPhotosAlbum:jpegData metadata:(__bridge id)attachments completionBlock:^(NSURL *assetURL, NSError *error) {
            
            UIImage *img = [UIImage imageWithData:jpegData];
            NSLog(@"img:%@", img);
            NSLog(@"assetURL:%@", assetURL);
            
            UIImage *image = [UIImage fixOrientation:img];
            
//                        self.picImg = image;
//                        self.photoView.image = image;
//                        self.photoContainer.hidden = NO;
            
            PhotoPrettifiedController *vc = [[PhotoPrettifiedController alloc]init];
            vc.photoImg = image;
            
            CATransition *myTransition=[CATransition animation];//创建CATransition
            myTransition.duration=0.3;//持续时长0.3秒
            myTransition.timingFunction=UIViewAnimationCurveEaseInOut;//计时函数，从头到尾的流畅度
            myTransition.type=kCATransitionMoveIn;//动画类型
            myTransition.subtype=kCATransitionFromTop;//子类型
            
            [weakSelf.navigationController.view.layer addAnimation:myTransition forKey:nil];
            
            [weakSelf.navigationController pushViewController:vc animated:NO];
            
            
        }];
        
    }];
    
}
- (void)flashButtonClick:(UIButton *)sender {
    
    NSLog(@"flashButtonClick");
    
    sender.selected = !sender.selected;
    
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    //修改前必须先锁定
    [device lockForConfiguration:nil];
    //必须判定是否有闪光灯，否则如果没有闪光灯会崩溃
    if ([device hasFlash]) {
        
        if (device.flashMode == AVCaptureFlashModeOff) {
            device.flashMode = AVCaptureFlashModeOn;
        } else if (device.flashMode == AVCaptureFlashModeOn) {
            device.flashMode = AVCaptureFlashModeAuto;
        } else if (device.flashMode == AVCaptureFlashModeAuto) {
            device.flashMode = AVCaptureFlashModeOff;
        }
        
    } else {
        
        NSLog(@"设备不支持闪光灯");
    }
    [device unlockForConfiguration];
}

#pragma mark - 配置滤镜视图
//简单边框视图
- (void)setupLOMOFilter
{
    [self setupFilterWithNormalImages:nil HighlightImages:nil titles:[NSArray arrayWithObjects:@"原图0", @"经典LOMO1", @"流年2", @"HDR3", @"碧波4", @"上野5", @"优格6", @"彩虹瀑7", @"云端8", @"淡雅9", @"粉红佳人10", @"复古11", @"候鸟12", @"黑白13", @"一九〇〇14", @"古铜色15", @"哥特风16", @"移轴17", @"TEST1-18", @"TEST2-19", @"TEST3-20", nil]];
}

- (void)setupFilterWithNormalImages:(NSArray *)normalImages HighlightImages:(NSArray *)highlightImages titles:(NSArray *)titles
{
    FWEffectBarItem *item = nil;
    NSMutableArray *items = [[NSMutableArray alloc] initWithCapacity:0];
    
    for (int i = 0; i < [titles count]; i++)
    {
        item = [[FWEffectBarItem alloc] initWithFrame:CGRectMake((50*ScreenScale + 22*ScreenScale) * i + 10, 0, 50*ScreenScale, 70*ScreenScale)];
        item.titleOverlay = YES;
        item.backgroundColor = [UIColor blackColor];
        
        UIImage *resultImg = [self didSelectItemAtIndex:i];
        
        UIImage *img = [UIImage scaleImage:resultImg targetHeight:70*ScreenScale];
        
        [item setFinishedSelectedImage:img withFinishedUnselectedImage:img];
        item.title = [NSString stringWithFormat:@"%@",titles[i]];
        [items addObject:item];
    }
    
    self.filterStyleBar.items = items;
}

- (UIImage *)didSelectItemAtIndex:(NSInteger)index{
    
    UIImage *img = nil;
    
    switch (index) {
        case 0:
            img = self.picImg;
            break;
            
        case 1:
            img= [FWApplyFilter applySketchFilter:self.picImg];
            break;
            
        case 2:
            img = [FWApplyFilter applySoftEleganceFilter:self.picImg];
            break;
            
        case 3:
            img =[FWApplyFilter applyMissetikateFilter:self.picImg];
            break;
            
        case 4:
            img =[FWApplyFilter applyNashvilleFilter:self.picImg];
            break;
            
        case 5:
            img =[FWApplyFilter applyLordKelvinFilter:self.picImg];
            break;
            
        case 6:
            img = [FWApplyFilter applyAmatorkaFilter:self.picImg];
            break;
            
        case 7:
            img = [FWApplyFilter applyRiseFilter:self.picImg];
            break;
            
        case 8:
            img = [FWApplyFilter applyHudsonFilter:self.picImg];
            break;
            
        case 9:
            img = [FWApplyFilter applyXproIIFilter:self.picImg];
            break;
            
        case 10:
            img =[FWApplyFilter apply1977Filter:self.picImg];
            break;
            
        case 11:
            img =[FWApplyFilter applyValenciaFilter:self.picImg];
            break;
            
        case 12:
            img =[FWApplyFilter applyWaldenFilter:self.picImg];
            break;
            
        case 13:
            img = [FWApplyFilter applyLomofiFilter:self.picImg];
            break;
            
        case 14:
            img = [FWApplyFilter applyInkwellFilter:self.picImg];
            break;
            
        case 15:
            img = [FWApplyFilter applySierraFilter:self.picImg];
            break;
            
        case 16:
            img = [FWApplyFilter applyEarlybirdFilter:self.picImg];
            break;
            
        case 17:
            img =[FWApplyFilter applySutroFilter:self.picImg];
            break;
            
        case 18:
            img =[FWApplyFilter applyToasterFilter:self.picImg];
            break;
            
        case 19:
            img =[FWApplyFilter applyBrannanFilter:self.picImg];
            break;
            
        case 20:
            img = [FWApplyFilter applyHefeFilter:self.picImg];
            break;
    }
    
    return img;
}

#pragma mark - FWEffectBarDelegate
- (void)effectBar:(FWEffectBar *)bar didSelectItemAtIndex:(NSInteger)index
{
    FWEffectBarItem *item = (FWEffectBarItem *)[bar.items objectAtIndex:index];
    item.ShowBorder = YES;
    [self.filterStyleBar scrollRectToVisible:item.frame  animated:YES];
    
    switch (index) {
        case 0:
            self.currentImg = self.picImg;
            break;
            
        case 1:
            self.currentImg = [FWApplyFilter applySketchFilter:self.picImg];
            break;
            
        case 2:
            self.currentImg = [FWApplyFilter applySoftEleganceFilter:self.picImg];
            break;
            
        case 3:
            self.currentImg =[FWApplyFilter applyMissetikateFilter:self.picImg];
            break;
            
        case 4:
            self.currentImg =[FWApplyFilter applyNashvilleFilter:self.picImg];
            break;
            
        case 5:
            self.currentImg =[FWApplyFilter applyLordKelvinFilter:self.picImg];
            break;
            
        case 6:
            self.currentImg = [FWApplyFilter applyAmatorkaFilter:self.picImg];
            break;
            
        case 7:
            self.currentImg = [FWApplyFilter applyRiseFilter:self.picImg];
            break;
            
        case 8:
            self.currentImg = [FWApplyFilter applyHudsonFilter:self.picImg];
            break;
            
        case 9:
            self.currentImg = [FWApplyFilter applyXproIIFilter:self.picImg];
            break;
            
        case 10:
            self.currentImg =[FWApplyFilter apply1977Filter:self.picImg];
            break;
            
        case 11:
            self.currentImg =[FWApplyFilter applyValenciaFilter:self.picImg];
            break;
            
        case 12:
            self.currentImg =[FWApplyFilter applyWaldenFilter:self.picImg];
            break;
            
        case 13:
            self.currentImg = [FWApplyFilter applyLomofiFilter:self.picImg];
            break;
            
        case 14:
            self.currentImg = [FWApplyFilter applyInkwellFilter:self.picImg];
            break;
            
        case 15:
            self.currentImg = [FWApplyFilter applySierraFilter:self.picImg];
            break;
            
        case 16:
            self.currentImg = [FWApplyFilter applyEarlybirdFilter:self.picImg];
            break;
            
        case 17:
            self.currentImg =[FWApplyFilter applySutroFilter:self.picImg];
            break;
            
        case 18:
            self.currentImg =[FWApplyFilter applyToasterFilter:self.picImg];
            break;
            
        case 19:
            self.currentImg =[FWApplyFilter applyBrannanFilter:self.picImg];
            break;
            
        case 20:
            self.currentImg = [FWApplyFilter applyHefeFilter:self.picImg];
            break;
    }
    
    self.photoView.image = self.currentImg;
    
}


//缩放手势 用于调整焦距
- (void)handlePinchGesture:(UIPinchGestureRecognizer *)recognizer{
    
    BOOL allTouchesAreOnThePreviewLayer = YES;
    NSUInteger numTouches = [recognizer numberOfTouches], i;
    for ( i = 0; i < numTouches; ++i ) {
        CGPoint location = [recognizer locationOfTouch:i inView:self.backView];
        CGPoint convertedLocation = [self.previewLayer convertPoint:location fromLayer:self.previewLayer.superlayer];
        if ( ! [self.previewLayer containsPoint:convertedLocation] ) {
            allTouchesAreOnThePreviewLayer = NO;
            break;
        }
    }
    
    if ( allTouchesAreOnThePreviewLayer ) {
        
        self.effectiveScale = self.beginGestureScale * recognizer.scale;
        if (self.effectiveScale < 1.0){
            self.effectiveScale = 1.0;
        }
        
        NSLog(@"%f-------------->%f------------recognizerScale%f",self.effectiveScale,self.beginGestureScale,recognizer.scale);
        
        CGFloat maxScaleAndCropFactor = [[self.stillImageOutput connectionWithMediaType:AVMediaTypeVideo] videoMaxScaleAndCropFactor];
        
        NSLog(@"%f",maxScaleAndCropFactor);
        if (self.effectiveScale > maxScaleAndCropFactor)
            self.effectiveScale = maxScaleAndCropFactor;
        
        [CATransaction begin];
        [CATransaction setAnimationDuration:.025];
        [self.previewLayer setAffineTransform:CGAffineTransformMakeScale(self.effectiveScale, self.effectiveScale)];
        [CATransaction commit];
        
    }
    
}

- (void)cancelAction {
    
    if (!self.photoContainer.hidden) {
        
        self.photoContainer.hidden = YES;
        
    } else {
        
        [self.navigationController popViewControllerAnimated:NO];
    }
    
}

- (void)ensureAction {
    
    if (!self.currentImg) {
        return;
    }
    
    if ([self.delegate respondsToSelector:@selector(photoCapViewController:didFinishDismissWithImage:)]) {
        
        [self.delegate photoCapViewController:self didFinishDismissWithImage:self.currentImg];
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)configViews{
    
    UIView *header = [[UIView alloc]initWithFrame:CGRectMake(0, 0, Device_Width, 64)];
    header.backgroundColor = [UIColor clearColor];
    [self.view addSubview:header];
    
    UIButton *flashlightBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [flashlightBtn setBackgroundImage:[UIImage imageNamed:@"闪光灯-开"] forState:UIControlStateNormal];
    [flashlightBtn setBackgroundImage:[UIImage imageNamed:@"闪光灯-关"] forState:UIControlStateSelected];
    [flashlightBtn addTarget:self action:@selector(flashButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    
    [header sd_addSubviews:@[flashlightBtn]];
    flashlightBtn.sd_layout
    .topSpaceToView(header, 25*ScreenScale)
    .leftSpaceToView(header, 15*ScreenScale)
    .widthIs(32*ScreenScale)
    .heightIs(27.75);
    
    UIView *backView = [[UIView alloc]initWithFrame:CGRectMake(0, 64, Device_Width, Device_Height - 80*ScreenScale - 64)];
    backView.layer.borderWidth = 1;
    backView.layer.borderColor = [UIColor whiteColor].CGColor;
    self.backView = backView;
    [self.view addSubview:backView];
    
    UIView *functionView = [[UIView alloc]initWithFrame:CGRectMake(0, Device_Height - 80*ScreenScale, Device_Width, 80*ScreenScale)];
    [self.view addSubview:functionView];
    
    UIButton *cancelBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [cancelBtn setTitle:@"取消" forState:UIControlStateNormal];
    [cancelBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [cancelBtn addTarget:self action:@selector(cancelAction) forControlEvents:UIControlEventTouchUpInside];
    cancelBtn.titleLabel.font = [UIFont systemFontOfSize:16*ScreenScale];
    
    UIButton *picBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [picBtn setBackgroundImage:[UIImage imageNamed:@"按钮"] forState:UIControlStateNormal];
    [picBtn addTarget:self action:@selector(takePhotoButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *convertBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [convertBtn setBackgroundImage:[UIImage imageNamed:@"切换摄像头"] forState:UIControlStateNormal];
    [convertBtn addTarget:self action:@selector(switchCameraSegmentedControlClick:) forControlEvents:UIControlEventTouchUpInside];
    
    [functionView sd_addSubviews:@[cancelBtn, picBtn, convertBtn]];
    
    picBtn.sd_layout
    .centerYEqualToView(functionView)
    .centerXEqualToView(functionView)
    .widthIs(64*ScreenScale)
    .heightIs(64*ScreenScale);
    
    cancelBtn.sd_layout
    .centerYEqualToView(picBtn)
    .leftSpaceToView(functionView, 15*ScreenScale)
    .widthIs(45*ScreenScale)
    .heightIs(16*ScreenScale);
    
    convertBtn.sd_layout
    .centerYEqualToView(picBtn)
    .rightSpaceToView(functionView, 15*ScreenScale)
    .widthIs(32*ScreenScale)
    .heightIs(32*ScreenScale);
}

- (void)configPhotoViews {
    
    UIView *photoContainer = [[UIView alloc]initWithFrame:self.view.bounds];
    photoContainer.backgroundColor = [UIColor blackColor];
    photoContainer.hidden = YES;
    self.photoContainer = photoContainer;
    [self.view addSubview:photoContainer];
    
    UIImageView *photoView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 64, Device_Width, Device_Height - 80*ScreenScale - 64)];
    [photoContainer addSubview:photoView];
    self.photoView = photoView;
    
    UIView *functionView = [[UIView alloc]initWithFrame:CGRectMake(0, Device_Height - 80*ScreenScale, Device_Width, 80*ScreenScale)];
    [photoContainer addSubview:functionView];
    
    UIButton *cancelBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [cancelBtn setTitle:@"重拍" forState:UIControlStateNormal];
    [cancelBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [cancelBtn addTarget:self action:@selector(cancelAction) forControlEvents:UIControlEventTouchUpInside];
    cancelBtn.titleLabel.font = [UIFont systemFontOfSize:16*ScreenScale];
    
    UIButton *picBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [picBtn setBackgroundImage:[UIImage imageNamed:@"按钮"] forState:UIControlStateNormal];
    picBtn.hidden = YES;
    [picBtn addTarget:self action:@selector(takePhotoButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *ensurelBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [ensurelBtn setTitle:@"使用照片" forState:UIControlStateNormal];
    [ensurelBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [ensurelBtn addTarget:self action:@selector(ensureAction) forControlEvents:UIControlEventTouchUpInside];
    ensurelBtn.titleLabel.font = [UIFont systemFontOfSize:16*ScreenScale];
    
    self.filterStyleBar = [[FWEffectBar alloc] init];
    self.filterStyleBar.effectBarDelegate = self;
    self.filterStyleBar.itemBeginX = 15.0;
    self.filterStyleBar.itemWidth = 50.0;
    self.filterStyleBar.margin = 10.0;
    [self.view addSubview:self.filterStyleBar];
    
    [functionView sd_addSubviews:@[cancelBtn, picBtn, ensurelBtn, self.filterStyleBar]];
    
    picBtn.sd_layout
    .centerYEqualToView(functionView)
    .centerXEqualToView(functionView)
    .widthIs(64*ScreenScale)
    .heightIs(64*ScreenScale);
    
    cancelBtn.sd_layout
    .centerYEqualToView(picBtn)
    .leftSpaceToView(functionView, 15*ScreenScale)
    .widthIs(45*ScreenScale)
    .heightIs(16*ScreenScale);
    
    ensurelBtn.sd_layout
    .centerYEqualToView(picBtn)
    .rightSpaceToView(functionView, 15*ScreenScale)
    .widthIs(80*ScreenScale)
    .heightIs(32*ScreenScale);
    
    self.filterStyleBar.sd_layout
    .centerYEqualToView(functionView)
    .leftSpaceToView(cancelBtn, 10*ScreenScale)
    .rightSpaceToView(ensurelBtn, 10*ScreenScale)
    .heightIs(70*ScreenScale);
    
}


@end
