//
//  PhotoPrettifiedController.m
//  YuanTianRan
//
//  Created by WuYaoDong on 2017/6/22.
//  Copyright © 2017年 WuYaoDong. All rights reserved.
//

#import "PhotoPrettifiedController.h"
#import "FWEffectBar.h"
#import "UIImage+ImgSupport.h"
#import "FWApplyFilter.h"
#import <SDAutoLayout.h>

#define Device_Height [[UIScreen mainScreen] bounds].size.height
#define Device_Width  [[UIScreen mainScreen] bounds].size.width
#define  ScreenScale  Device_Width/375

@interface PhotoPrettifiedController ()<FWEffectBarDelegate>
@property(nonatomic, strong)UIView *photoContainer;
@property(nonatomic, strong)UIImageView *photoView;
@property(nonatomic, strong)UIImage *currentImg;

@property (nonatomic, strong) FWEffectBar *filterStyleBar;
@end

@implementation PhotoPrettifiedController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationController.navigationBar.hidden = YES;
    
    [self configPhotoViews];
    
    [self setupLOMOFilter];

}

- (void)cancelAction {
    
    [self.navigationController popViewControllerAnimated:NO];
}

- (void)ensureAction{
    
    NSLog(@"----->确定这张");
    [self.navigationController popViewControllerAnimated:NO];
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
            img = self.photoImg;
            break;
            
        case 1:
            img= [FWApplyFilter applySketchFilter:self.photoImg];
            break;
            
        case 2:
            img = [FWApplyFilter applySoftEleganceFilter:self.photoImg];
            break;
            
        case 3:
            img =[FWApplyFilter applyMissetikateFilter:self.photoImg];
            break;
            
        case 4:
            img =[FWApplyFilter applyNashvilleFilter:self.photoImg];
            break;
            
        case 5:
            img =[FWApplyFilter applyLordKelvinFilter:self.photoImg];
            break;
            
        case 6:
            img = [FWApplyFilter applyAmatorkaFilter:self.photoImg];
            break;
            
        case 7:
            img = [FWApplyFilter applyRiseFilter:self.photoImg];
            break;
            
        case 8:
            img = [FWApplyFilter applyHudsonFilter:self.photoImg];
            break;
            
        case 9:
            img = [FWApplyFilter applyXproIIFilter:self.photoImg];
            break;
            
        case 10:
            img =[FWApplyFilter apply1977Filter:self.photoImg];
            break;
            
        case 11:
            img =[FWApplyFilter applyValenciaFilter:self.photoImg];
            break;
            
        case 12:
            img =[FWApplyFilter applyWaldenFilter:self.photoImg];
            break;
            
        case 13:
            img = [FWApplyFilter applyLomofiFilter:self.photoImg];
            break;
            
        case 14:
            img = [FWApplyFilter applyInkwellFilter:self.photoImg];
            break;
            
        case 15:
            img = [FWApplyFilter applySierraFilter:self.photoImg];
            break;
            
        case 16:
            img = [FWApplyFilter applyEarlybirdFilter:self.photoImg];
            break;
            
        case 17:
            img =[FWApplyFilter applySutroFilter:self.photoImg];
            break;
            
        case 18:
            img =[FWApplyFilter applyToasterFilter:self.photoImg];
            break;
            
        case 19:
            img =[FWApplyFilter applyBrannanFilter:self.photoImg];
            break;
            
        case 20:
            img = [FWApplyFilter applyHefeFilter:self.photoImg];
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
            self.currentImg = self.photoImg;
            break;
            
        case 1:
            self.currentImg = [FWApplyFilter applySketchFilter:self.photoImg];
            break;
            
        case 2:
            self.currentImg = [FWApplyFilter applySoftEleganceFilter:self.photoImg];
            break;
            
        case 3:
            self.currentImg =[FWApplyFilter applyMissetikateFilter:self.photoImg];
            break;
            
        case 4:
            self.currentImg =[FWApplyFilter applyNashvilleFilter:self.photoImg];
            break;
            
        case 5:
            self.currentImg =[FWApplyFilter applyLordKelvinFilter:self.photoImg];
            break;
            
        case 6:
            self.currentImg = [FWApplyFilter applyAmatorkaFilter:self.photoImg];
            break;
            
        case 7:
            self.currentImg = [FWApplyFilter applyRiseFilter:self.photoImg];
            break;
            
        case 8:
            self.currentImg = [FWApplyFilter applyHudsonFilter:self.photoImg];
            break;
            
        case 9:
            self.currentImg = [FWApplyFilter applyXproIIFilter:self.photoImg];
            break;
            
        case 10:
            self.currentImg =[FWApplyFilter apply1977Filter:self.photoImg];
            break;
            
        case 11:
            self.currentImg =[FWApplyFilter applyValenciaFilter:self.photoImg];
            break;
            
        case 12:
            self.currentImg =[FWApplyFilter applyWaldenFilter:self.photoImg];
            break;
            
        case 13:
            self.currentImg = [FWApplyFilter applyLomofiFilter:self.photoImg];
            break;
            
        case 14:
            self.currentImg = [FWApplyFilter applyInkwellFilter:self.photoImg];
            break;
            
        case 15:
            self.currentImg = [FWApplyFilter applySierraFilter:self.photoImg];
            break;
            
        case 16:
            self.currentImg = [FWApplyFilter applyEarlybirdFilter:self.photoImg];
            break;
            
        case 17:
            self.currentImg =[FWApplyFilter applySutroFilter:self.photoImg];
            break;
            
        case 18:
            self.currentImg =[FWApplyFilter applyToasterFilter:self.photoImg];
            break;
            
        case 19:
            self.currentImg =[FWApplyFilter applyBrannanFilter:self.photoImg];
            break;
            
        case 20:
            self.currentImg = [FWApplyFilter applyHefeFilter:self.photoImg];
            break;
    }
    
    self.photoView.image = self.currentImg;
    
}



- (void)configPhotoViews {
    
    UIView *photoContainer = [[UIView alloc]initWithFrame:self.view.bounds];
    photoContainer.backgroundColor = [UIColor blackColor];
    self.photoContainer = photoContainer;
    [self.view addSubview:photoContainer];
    
    UIImageView *photoView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 64, Device_Width, Device_Height - 80*ScreenScale - 64)];
    [photoContainer addSubview:photoView];
    photoView.image = self.photoImg;
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
    .heightIs(45*ScreenScale);
    
    ensurelBtn.sd_layout
    .centerYEqualToView(picBtn)
    .rightSpaceToView(functionView, 15*ScreenScale)
    .widthIs(80*ScreenScale)
    .heightIs(45*ScreenScale);
    
    self.filterStyleBar.sd_layout
    .centerYEqualToView(functionView)
    .leftSpaceToView(cancelBtn, 10*ScreenScale)
    .rightSpaceToView(ensurelBtn, 10*ScreenScale)
    .heightIs(70*ScreenScale);
    
}

@end
