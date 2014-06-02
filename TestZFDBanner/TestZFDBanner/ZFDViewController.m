//
//  ZFDViewController.m
//  TestZFDBanner
//
//  Created by ZFD on 14-6-2.
//  Copyright (c) 2014年 ZFD. All rights reserved.
//

#import "ZFDViewController.h"
#import "ZFDBannerView.h"

@interface ZFDViewController ()

@property (weak, nonatomic) IBOutlet UIView *topView;


@end

@implementation ZFDViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    ZFDBannerView *bannerView = [[ZFDBannerView alloc] initWithFrame:self.topView.frame withImagePaths:@[@"page1.png",@"page2.png",@"page3.png"]];
    [self.topView addSubview:bannerView];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
