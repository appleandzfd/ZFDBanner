//
//  FirstPageBannerView.h
//  TourKit2.0
//
//  Created by ZFD on 13-5-6.
//  Copyright (c) 2013年 Vobile. All rights reserved.
//
/*
 for the work of banner ,make sure to override the method ->loadAnImage ,user a propal method to load images
 all the image was store in the memory
 */


#import <UIKit/UIKit.h>
///include currentImageNum key/value to identify which banner user selected
@protocol ZFDBannerViewDelegate <NSObject>

- (void) handleImageTouch : (NSDictionary *)touchInfor;

@end

@interface ZFDBannerView : UIView<UIScrollViewDelegate>{
}
@property (weak,nonatomic) id<ZFDBannerViewDelegate> delegateVC;
@property (strong, nonatomic) UILabel *bannerLabel;
@property (strong, nonatomic) UIView *bottomView;
@property (strong,nonatomic) NSArray *scrollImagePaths;//the array source path to load the image

- (id)initWithFrame:(CGRect)frame withImagePaths : (NSArray *) imagePaths;//init method


@end
