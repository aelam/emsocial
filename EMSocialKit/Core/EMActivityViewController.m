//
//  EMActivityViewController.m
//  EMSocialApp
//
//  Created by Ryan Wang on 15/3/18.
//  Copyright (c) 2015年 Ryan Wang. All rights reserved.
//

#import "EMActivityViewController.h"
#import "EMSSlideUpTransitionAnimator.h"
#import "_EMActivityViewCell.h"
#import "EMActivity.h"
#import "EMSocialSDK.h"
#import "EMSocialThemeConf.h"

#define EMSOCIAL_RGBA(r,g,b,a) [UIColor colorWithRed:r / 255.0 green:g / 255.0 blue:b / 255.0 alpha:a]
#define EMSOCIAL_RGB(r,g,b) EMSOCIAL_RGBA(r,g,b,1)

static NSString *kActivityCellIdentifier = @"kActivityCellIdentifier";
static CGFloat kContentHeight = 156.f;

@interface EMActivityViewController () <UIViewControllerTransitioningDelegate,UIGestureRecognizerDelegate, UICollectionViewDataSource, UICollectionViewDelegate>

@property (nonatomic, strong) NSArray *activityItems;
@property (nonatomic, strong) NSArray *applicationActivities;
@property (nonatomic, strong, readwrite) UIView *contentView;
@property (nonatomic, strong, readwrite) UICollectionView *collectionView;
@property (nonatomic, strong, readwrite) UIButton *closeButton;
@property (nonatomic, assign) NSString *selectedActivityType;
@property (nonatomic, strong) UITapGestureRecognizer *tapGestureRecognizer;
@property (nonatomic, assign) CGFloat bottomPadding;

@property(nonatomic, strong, readwrite)EMActivity *activeActivity;

@end


@implementation EMActivityViewController

- (instancetype)initWithActivityItems:(NSArray *)activityItems applicationActivities:(NSArray *)applicationActivities {
    if (self = [super init]) {
        self.activityItems = activityItems;
        self.applicationActivities = applicationActivities;
        self.modalPresentationStyle = UIModalPresentationCustom;
        self.transitioningDelegate = self;
        self.activityStyle = EMActivityStyleBlack;
        if (@available(iOS 11.0, *)) {
            self.bottomPadding = [UIApplication sharedApplication].keyWindow.safeAreaInsets.bottom;
        } else {
            self.bottomPadding = 0;
        }
    }
    
    return self;
}

- (void)loadView {
    CGFloat width = [UIScreen mainScreen].bounds.size.width;
    self.view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, kContentHeight + self.bottomPadding)];
}

- (CGSize)preferredContentSize {
    return CGSizeMake(self.view.frame.size.width, kContentHeight + self.bottomPadding);
}


- (void)viewDidLoad {
    [super viewDidLoad];
    [self setUpActivitiesUI];
    [self updateUIForTheme];

}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    // this moment the self.view.window != nil
    [self addCloseGestureOnWindow];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self removeGesture];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
}

- (void)viewSafeAreaInsetsDidChange {
    [super viewSafeAreaInsetsDidChange];
    self.bottomPadding = self.view.safeAreaInsets.bottom;
}

- (void)loadWhiteTheme {
//    self.backgroundColor = EMSOCIAL_RGB(0xf2,0xf2,0xF2);
//    self.activityTitleColor = EMSOCIAL_RGB(0x3d,0x3d,0x3d);
//    self.cancelBackgroundColor = [UIColor whiteColor];
//    self.cancelBorderColor = [UIColor whiteColor];
}

- (void)loadBlackTheme {
//    self.backgroundColor = EMSOCIAL_RGB(0x28,0x29,0x2c);
//    self.activityTitleColor = [UIColor whiteColor];
//    self.cancelBackgroundColor = EMSOCIAL_RGB(0x3e,0x40,0x4f);
//    self.cancelBorderColor = EMSOCIAL_RGB(0x5b,0x5b,0x5b);
}

- (void)updateUIForTheme {
    self.view.backgroundColor = EMSocialThemeConf.defaultConf.backgroundColor;
    self.closeButton.backgroundColor = EMSocialThemeConf.defaultConf.cancelBackgroundColor;
}

- (void)setApplicationActivities:(NSArray *)applicationActivities {
    if (_applicationActivities != applicationActivities) {
        _applicationActivities = applicationActivities;
    }
    [self.collectionView reloadData];
}

- (void)addCloseGestureOnWindow {
    self.tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapBehind:)];
    self.tapGestureRecognizer.delegate = self;
    [self.view.window addGestureRecognizer:self.tapGestureRecognizer];
}

- (void)removeGesture {
    [self.view.window removeGestureRecognizer:self.tapGestureRecognizer];
}

- (void)setUpActivitiesUI {
    const CGFloat closeButtonHeight = 50;
    const CGFloat collectionViewHeight = 110.f;

    self.view.backgroundColor = EMSocialThemeConf.defaultConf.backgroundColor;
    CGRect collectionViewRect = self.view.bounds;
    collectionViewRect.size.height = collectionViewHeight;
    
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    CGFloat screenWidth = [UIScreen mainScreen].applicationFrame.size.width;
    flowLayout.itemSize = CGSizeMake((screenWidth - 20) /3.0, 110);
    flowLayout.sectionInset = UIEdgeInsetsMake(0, 10, 0, 10);
    flowLayout.minimumInteritemSpacing = 0;
    flowLayout.minimumLineSpacing = 0;
    flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    self.collectionView = [[UICollectionView alloc] initWithFrame:collectionViewRect collectionViewLayout:flowLayout];
    self.collectionView.backgroundColor = [UIColor clearColor];
    self.collectionView.showsHorizontalScrollIndicator = NO;
    
    [self.collectionView registerClass:[_EMActivityViewCell class] forCellWithReuseIdentifier:kActivityCellIdentifier];

    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    [self.view addSubview:self.collectionView];
    
    self.closeButton = [UIButton buttonWithType:UIButtonTypeSystem];
    CGRect closeRect = self.view.bounds;//
    closeRect.origin.y = collectionViewRect.size.height;
    closeRect.size.height = closeButtonHeight;
    //closeRect = UIEdgeInsetsInsetRect(closeRect, UIEdgeInsetsMake(0, 0, 20, 15));
    self.closeButton.frame = closeRect;
    [self.closeButton setTitleColor:EMSocialThemeConf.defaultConf.cancelTitleColor forState:UIControlStateNormal];
    self.closeButton.titleLabel.font = [UIFont systemFontOfSize:16];

    self.closeButton.backgroundColor = [UIColor clearColor];
    self.closeButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
    [self.view addSubview:self.closeButton];

    CGRect separatorRect = self.view.bounds;//
    separatorRect.origin.y = collectionViewRect.size.height;
    separatorRect.size.height = 0.5;
    
    UIView *separator = [[UIView alloc] initWithFrame:separatorRect];
    separator.backgroundColor = EMSocialThemeConf.defaultConf.separatorColor;
    [self.view addSubview:separator];
    
    [self.closeButton setTitle:NSLocalizedString(@"取消", nil) forState:UIControlStateNormal];
    [self.closeButton addTarget:self action:@selector(cancelAction:) forControlEvents:UIControlEventTouchUpInside];
}

#pragma mark UIGestureRecognizerDelegate -
- (void)handleTapBehind:(UITapGestureRecognizer *)sender
{
    // dimiss and clear tapGestureRecognizer
    [self.view.window removeGestureRecognizer:sender];
    [self dismiss:nil];
    self.tapGestureRecognizer = nil;
}

- (void)dismiss:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)sender {
    CGPoint location = [sender locationInView:nil];
    // if tap outside pincode inputscreen
    BOOL inView = [self.view pointInside:[self.view convertPoint:location fromView:self.view.window] withEvent:nil];
    // if tap outside pincode inputscreen
    if (!inView)
    {
        return YES;
    }
    return NO;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    return YES;
}

#pragma mark - UICollectionViewDataSource -
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.applicationActivities.count;
}


- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    _EMActivityViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kActivityCellIdentifier forIndexPath:indexPath];
    if (self.applicationActivities.count > indexPath.row) {
        EMActivity *activity = self.applicationActivities[indexPath.row];
        cell.activityTitleLabel.text = activity.activityTitle;
        cell.activityImageView.image = activity.activityImage;
        cell.activityTitleLabel.textColor = EMSocialThemeConf.defaultConf.activityTitleColor;
    }
    return cell;
}


- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (self.applicationActivities.count > indexPath.row) {
        __weak __typeof(self) weakSelf = self;
        [self dismissViewControllerAnimated:YES completion:^{
            EMActivity *activity = weakSelf.applicationActivities[indexPath.row];
            weakSelf.selectedActivityType = activity.activityType;
            weakSelf.activeActivity = activity;
            
            if (weakSelf.completionWithItemsHandler) {
                weakSelf.completionWithItemsHandler(weakSelf.activeActivity, YES, NULL, nil);
            }

            [weakSelf.activeActivity prepareWithActivityItems:weakSelf.activityItems];
            [weakSelf.activeActivity performActivity];
        }];
    }
}

- (void)cancelAction:(id)sender {
    if (self.completionWithItemsHandler) {
        NSError *activityError = [NSError errorWithDomain:@"EMActivityViewController" code:100 userInfo:@{NSLocalizedDescriptionKey:@"用户取消"}];
        self.completionWithItemsHandler(self.activeActivity,YES, nil, activityError);
    }
    [self dismiss:nil];
}

#pragma mark - UIVieControllerTransitioningDelegate -
- (id <UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented
                                                                   presentingController:(UIViewController *)presenting
                                                                       sourceController:(UIViewController *)source{
    EMSTransitionAnimator *slideUpTransitionAnimator = [EMSocialSDK sharedSDK].transitionAnimator;
    slideUpTransitionAnimator.presenting = YES;
    return slideUpTransitionAnimator;
}

#pragma mark - Rotate
- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed
{
    EMSTransitionAnimator *slideUpTransitionAnimator = [EMSocialSDK sharedSDK].transitionAnimator;
    slideUpTransitionAnimator.presenting = NO;
    return slideUpTransitionAnimator;
}

- (BOOL)shouldAutorotate {
    return NO;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (void)dealloc {
    
}

@end
