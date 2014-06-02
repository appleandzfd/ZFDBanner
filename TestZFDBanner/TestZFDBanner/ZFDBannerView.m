//
//  FirstPageBannerView.m
//  TourKit2.0
//
//  Created by ZFD on 13-5-6.
//  Copyright (c) 2013年 Vobile. All rights reserved.
//

#import "ZFDBannerView.h"
//#import "ZFDUtil.h"
#define AutoScrollTimeInterval 4.0
#define ForbidScroll 0
#define AllowScroll 1
//#import "LocalCacheMemory.h"
#define defaultImage @"bannerimageDefault.png"

@interface UIScrollView (ZFDScrollKVOCustom)

//+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)theKey;

@end

@implementation UIScrollView (ZFDScrollKVOCustom)

#warning this will influence all the scroll view contentset
/*
+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)theKey {
    BOOL automatic = NO;
    if ([theKey isEqualToString:@"contentOffset"]) {
        automatic = NO;
    }
    else {
        automatic = [super automaticallyNotifiesObserversForKey:theKey];
    }
    return automatic;
}
*/
@end

@interface ZFDBannerView(){
    int currentImageNum;
}
@property int scrollStyle;//滑动类型，0表示禁止左右滑动，1表示可以滑动,默认可以滑动

@property (strong, nonatomic) UIScrollView *mainScrollView;
@property (strong, nonatomic) UIPageControl *pageControl;
@property (strong, nonatomic) UIImageView *leftImageView;
@property (strong, nonatomic) UIImageView *centerImageView;
@property (strong, nonatomic) UIImageView *rightImageView;

@property (nonatomic, strong) NSMutableArray *showArray;//初始显示
@property (nonatomic, strong) NSMutableArray *loadedImageArray;
@property (strong, atomic) NSTimer *scrollAutoTimer;//计时器

@property int backgroudState;

@property (nonatomic,strong) UITapGestureRecognizer *tapImage;
@end
@implementation ZFDBannerView
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}


-(void) loadLocalImage:(NSString *)imagePath imageIndex:(int) index{
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^(void) {
//        LocalCacheMemory *localCache = [LocalCacheMemory sharedSingle];
//        [localCache getMemoryTargetWithUrl:[self.scrollImagePaths objectAtIndex:index] success:^(NSData *data) {
            UIImage *oneImage = [UIImage imageNamed:imagePath];
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                @synchronized (self)
                {
                    [self.loadedImageArray setObject:oneImage atIndexedSubscript:index];
                }
                int leftImageNum;
                int centerImageNum = currentImageNum;
                int rightImageNum;
                if (currentImageNum == 0) {
                    leftImageNum = self.scrollImagePaths.count-1;
                }else{
                    leftImageNum = currentImageNum-1;
                }
                if (currentImageNum == self.scrollImagePaths.count-1) {
                    rightImageNum = 0;
                }else{
                    rightImageNum = currentImageNum +1;
                }
                if (index == centerImageNum) {
                    self.centerImageView.image = oneImage;
                }
                if (index == leftImageNum) {
                    self.leftImageView.image = oneImage;
                }
                if (index == rightImageNum) {
                    self.rightImageView.image = oneImage;
                }
            });
//        } fail:^(NSString *errorDescription) {
//            
//        }];
    });

}

////加载图片的方法，可
//-(void)loadAnImage : (NSString *)imageUrl imageIndex:(int) index{
//    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
//    dispatch_async(queue, ^(void) {
//        LocalCacheMemory *localCache = [LocalCacheMemory sharedSingle];
//        [localCache getMemoryTargetWithUrl:[self.scrollImagePaths objectAtIndex:index] success:^(NSData *data) {
//            NSData *imageData = data;
//            UIImage *oneImage = [UIImage imageWithData:imageData];
//            dispatch_async(dispatch_get_main_queue(), ^(void) {
//                @synchronized (self)
//                {
//                    [self.loadedImageArray setObject:oneImage atIndexedSubscript:index];
//                }
//                int leftImageNum;
//                int centerImageNum = currentImageNum;
//                int rightImageNum;
//                if (currentImageNum == 0) {
//                    leftImageNum = self.scrollImagePaths.count-1;
//                }else{
//                    leftImageNum = currentImageNum-1;
//                }
//                if (currentImageNum == self.scrollImagePaths.count-1) {
//                    rightImageNum = 0;
//                }else{
//                    rightImageNum = currentImageNum +1;
//                }
//                if (index == centerImageNum) {
//                    self.centerImageView.image = oneImage;
//                }
//                if (index == leftImageNum) {
//                    self.leftImageView.image = oneImage;
//                }
//                if (index == rightImageNum) {
//                    self.rightImageView.image = oneImage;
//                }
//            });
//        } fail:^(NSString *errorDescription) {
//            
//        }];
////        [NSData dataWithContentsOfURL:[NSURL URLWithString:[self.scrollImagePaths objectAtIndex:index]]];
//    });
//}

- (void) tapTheImage:(UITapGestureRecognizer *)sender{
    if (currentImageNum != 1) {//used for this project
        return;
    }
    if ([self.delegateVC respondsToSelector:@selector(handleImageTouch:)]) {
        self.mainScrollView.userInteractionEnabled = NO;
        [self stopAutoTimer];//there is situation the when push viewcontroller ,there only begin celebrate ,and no end celebrate
        [self.delegateVC performSelector:@selector(handleImageTouch:) withObject:[[NSDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithInt:currentImageNum],@"currentImageNum", nil]];
        [self performSelector:@selector(resetUserInteractionToYes) withObject:nil afterDelay:0.3];
    }
}

-(void)resetUserInteractionToYes{
    [self restartAutoTimer];
    self.mainScrollView.userInteractionEnabled = YES;
}

- (id)initWithFrame:(CGRect)frame withImagePaths : (NSArray *) imagePaths
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        //initial all the componnet;
        self.scrollImagePaths = imagePaths;//目前唯一参数，图片路径，由VC传递
        
        self.mainScrollView = [[UIScrollView alloc] initWithFrame:self.frame];
        self.mainScrollView.delegate = self;
        self.mainScrollView.contentSize = CGSizeMake(self.frame.size.width*3, self.frame.size.height);
        self.mainScrollView.pagingEnabled = YES;
        self.mainScrollView.showsHorizontalScrollIndicator = NO;
        self.mainScrollView.backgroundColor = [UIColor whiteColor];
        [self addSubview:self.mainScrollView];
        self.leftImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
        self.centerImageView = [[UIImageView alloc] initWithFrame:CGRectMake(self.frame.size.width, 0, self.frame.size.width, self.frame.size.height)];
        self.rightImageView = [[UIImageView alloc] initWithFrame:CGRectMake(self.frame.size.width*2, 0, self.frame.size.width, self.frame.size.height)];
        self.leftImageView.userInteractionEnabled = YES;
        self.centerImageView.userInteractionEnabled = YES;
        self.rightImageView.userInteractionEnabled = YES;
        self.tapImage = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapTheImage:)];
        self.tapImage.delaysTouchesBegan = YES;
        [self.centerImageView addGestureRecognizer:self.tapImage];
        [self.mainScrollView addSubview:self.leftImageView];
        [self.mainScrollView addSubview:self.centerImageView];
        [self.mainScrollView addSubview:self.rightImageView];
        self.loadedImageArray = [[NSMutableArray alloc] init];
        for (int i = 0; i<= self.scrollImagePaths.count -1 ; i++) {
//            NSString *onex = [self.scrollImagePaths objectAtIndex:i];
            [self.loadedImageArray addObject:[UIImage imageNamed:defaultImage]];
            [self loadLocalImage:[self.scrollImagePaths objectAtIndex:i] imageIndex:i];
        }
        
        self.bottomView = [[UIView alloc] initWithFrame:CGRectMake(0, self.frame.size.height - 29, self.frame.size.width, 29)];
        self.bottomView.backgroundColor = [UIColor blackColor];
        self.bottomView.alpha = 0.5;
        self.bannerLabel = [[UILabel alloc] initWithFrame:CGRectMake(6, 4, 123, 21)];
        self.bannerLabel.text = @"提示信息";
        self.bannerLabel.textColor = [UIColor whiteColor];
        self.bannerLabel.backgroundColor = [UIColor clearColor];
        [self.bottomView addSubview:self.bannerLabel];
        self.pageControl = [[UIPageControl alloc] init];
        /*
         reset the position of page control
         */
//        [self.bottomView addSubview:self.pageControl];
        self.pageControl.numberOfPages = self.scrollImagePaths.count;
        self.pageControl.currentPage = 0;
        self.pageControl.center = CGPointMake(self.center.x, frame.size.height - 12);
        [self addSubview:self.pageControl];
        /*
         remove the bottom view
         */
//        [self addSubview:self.bottomView];
        [self.mainScrollView addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
        
        self.scrollStyle = AllowScroll;//初始允许滑动
        self.showArray = [self getShowImagePaths];//取出三张图片使用
        currentImageNum = 0;
        if (self.scrollStyle == AllowScroll) {//允许滑动
            NSNumber *left = [self.showArray objectAtIndex:0];
            NSNumber *center = [self.showArray objectAtIndex:1];
            NSNumber *right = [self.showArray objectAtIndex:2];

            self.leftImageView.image = [self.loadedImageArray objectAtIndex:left.intValue];
            self.centerImageView.image = [self.loadedImageArray objectAtIndex:center.intValue];
            self.rightImageView.image = [self.loadedImageArray objectAtIndex:right.intValue];
            [self.mainScrollView setContentOffset:CGPointMake(self.frame.size.width, 0)];
            
//            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActive:)name:UIApplicationWillResignActiveNotification object:nil]; //监听是否触发home键挂起程序.
//            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive:)name:UIApplicationDidBecomeActiveNotification object:nil]; //监听是否重新进入程序程序.
        }
        [self addAutoTimer];
//        self.scrollAutoTimer = [NSTimer scheduledTimerWithTimeInterval:AutoScrollTimeInterval target:self selector:@selector(autoChangeScrollView) userInfo:nil repeats:YES];

    }
    return self;
}
#pragma mark kvo

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
//    if ([keyPath isEqualToString:@"contentOffset"]) {
//        NSLog(@"self.scrollview offset = %f",self.mainScrollView.contentOffset.x);
//        [self performSelector:@selector(checkScrollViewOffset) withObject:nil afterDelay:0.5];
//    }
    
}

-(void)checkScrollViewOffset{
//    NSLog(@"||||||||self.mainScrollView.contentOffset.x = %f",self.mainScrollView.contentOffset.x);
//    if (self.mainScrollView.contentOffset.x != self.mainScrollView.frame.size.width) {
//        NSLog(@"there is something wrong ,reset the offset=====================");
//        [self.mainScrollView setContentOffset:CGPointMake(self.frame.size.width*2, 0) animated:YES];
//    }else
//        NSLog(@"there is nothing wrong");
}

#pragma mark check mainscrollview offset

- (NSMutableArray *)getShowImagePaths{//23.jpg作为默认图片
    switch (self.scrollImagePaths.count) {
        case 0:
        {
            self.scrollStyle = ForbidScroll;//禁止滑动
            self.mainScrollView.scrollEnabled = NO;
            return [[NSMutableArray alloc] initWithObjects:defaultImage, nil];
        }
        break;
        case 1:
        {
            self.scrollStyle = ForbidScroll;//禁止滑动
            self.mainScrollView.scrollEnabled = NO;
            return [[NSMutableArray alloc] initWithObjects:[NSNumber numberWithInt:0], nil];
        }
        break;
        default:
        {
            return [[NSMutableArray alloc] initWithObjects:[NSNumber numberWithInt:[self.scrollImagePaths count]-1],[NSNumber numberWithInt:0],[NSNumber numberWithInt:1], nil];
        }
            break;
    }
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
//- (void)drawRect:(CGRect)rect
//{
//    // Drawing code
////    self.autoresizingMask = UIViewAutoresizingFlexibleHeight;
//}

#pragma mark become active/resign active

//- (void)applicationWillResignActive:(NSNotification *)notification
//
//{
//    [self stopAutoTimer];
//    self.backgroudState = 1;
//}
//
//- (void)applicationDidBecomeActive:(NSNotification *)notification
//{
//    self.backgroudState = 0;
//    [self restartAutoTimer];
//}

#pragma mark change images when scroll
-(void) scrollImageChange{
#ifdef debugbanner
    NSLog(@"切换图片");
#endif
    int leftImageNum;
    int centerImageNum = currentImageNum;
    int rightImageNum;
    if (currentImageNum == 0) {
        leftImageNum = self.scrollImagePaths.count-1;
    }else{
        leftImageNum = currentImageNum-1;
    }
    if (currentImageNum == self.scrollImagePaths.count-1) {
        rightImageNum = 0;
    }else{
        rightImageNum = currentImageNum +1;
    }
    self.leftImageView.image = [self.loadedImageArray objectAtIndex:leftImageNum];
    self.centerImageView.image = [self.loadedImageArray objectAtIndex:centerImageNum];
    self.rightImageView.image = [self.loadedImageArray objectAtIndex:rightImageNum];
}

#pragma mark aboutAutoScroll

- (void) autoChangeScrollView{
#ifdef debugbanner
    NSLog(@"auto change scroll view");
#endif
    //代码设置滑动
    [self.mainScrollView willChangeValueForKey:@"contentOffset"];
    [self.mainScrollView setContentOffset:CGPointMake(self.frame.size.width*2, 0) animated:YES];
    [self.mainScrollView didChangeValueForKey:@"contentOffset"];
}


- (void)addAutoTimer
{
#ifdef debugbanner
    NSLog(@"add auto timer");
#endif
    NSRunLoop *runloop = [NSRunLoop currentRunLoop];
    self.scrollAutoTimer = [NSTimer scheduledTimerWithTimeInterval:AutoScrollTimeInterval target:self selector:@selector(autoChangeScrollView) userInfo:nil repeats:YES];
    //    NSTimer *timer = [NSTimer timerWithTimeInterval:0.1 target:self selector:@selector(myTimerAction:) userInfo:nil repeats:YES];
    [runloop addTimer:self.scrollAutoTimer forMode:NSRunLoopCommonModes];
    [runloop addTimer:self.scrollAutoTimer forMode:UITrackingRunLoopMode];}

- (void)stopAutoTimer
{
#ifdef debugbanner
    NSLog(@"stop auto timer");
#endif
    if (self.scrollAutoTimer) {
        [self.scrollAutoTimer invalidate];
        self.scrollAutoTimer = nil;
    }
}

- (void)restartAutoTimer
{
#ifdef debugbanner
    NSLog(@"restart auto timer");
#endif
    if (!self.scrollAutoTimer) {
        [self addAutoTimer];
    }
}

#pragma mark -
#pragma mark UIScrollViewDelegate
- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView
{
#ifdef debugbanner
    NSLog(@"did begin decelerating");
#endif
    [self stopAutoTimer];
}
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{//若只有一张以下图片，不会允许滑动，进入到该方法的，均为两张以上图片
//    NSLog(@"scrollView.contentOffset.x=== %f",scrollView.contentOffset.x);
    if (scrollView.contentOffset.x <= 0) {
#ifdef debugbanner
        NSLog(@"did scroll view <=0");
#endif
        if (currentImageNum == 0) {
            currentImageNum = self.scrollImagePaths.count -1;
        }else{
            currentImageNum -- ;
        }
        self.pageControl.currentPage = currentImageNum;
        [self scrollImageChange];
        //调换图片之后移动scrollview的content到中心，因为图片相同，不添加动画效果，界面上看不出移动的效果
        [self.mainScrollView setContentOffset:CGPointMake(self.frame.size.width, 0)];
    }
    if (scrollView.contentOffset.x >= 2*self.frame.size.width) {
#ifdef debugbanner
        NSLog(@"did scrollview second");
#endif
        if (currentImageNum == self.scrollImagePaths.count -1 ) {
            currentImageNum = 0;
        }else{
            currentImageNum ++ ;
        }
        self.pageControl.currentPage = currentImageNum;
        [self scrollImageChange];
        [self.mainScrollView setContentOffset:CGPointMake(self.frame.size.width, 0)];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
#ifdef debugbanner
    NSLog(@"did end selebrate");
#endif
    [self.mainScrollView setContentOffset:CGPointMake(self.frame.size.width, 0) animated:YES];
    [self restartAutoTimer];
}

@end
