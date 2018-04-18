//
//  ViewController.m
//  PCBlogChallenge
//
//  Created by Brian Goo on 4/9/18.
//  Copyright © 2018 Brian Goo. All rights reserved.
//

#import "PCBlogViewController.h"
#import "PCNetworking.h"

@interface PCBlogViewController ()

@property (nonatomic, strong) UIActivityIndicatorView *feedLoadIndicator;

@end

@implementation PCBlogViewController

static CGFloat const kActivityIndicatorSize = 100.0;
static NSString * const kBlogItemCellId = @"BlogItemCell";

- (void)loadView {
    [super loadView];
    
    self.view = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Initialize the UICollectionView.
    UICollectionViewFlowLayout *layout=[[UICollectionViewFlowLayout alloc] init];
    _collectionView = [[UICollectionView alloc] initWithFrame:self.view.frame collectionViewLayout:layout];
    _collectionView.dataSource = self;
    _collectionView.delegate = self;
    
    [_collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:kBlogItemCellId];
    [_collectionView setBackgroundColor:[UIColor whiteColor]];
    [self.view addSubview:_collectionView];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
        // Add "refresh" button to top right corner of UINav bar.
    UIBarButtonItem *refreshButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
                                                                                   target:self
                                                                                   action:@selector(refresh)];
    self.navigationItem.rightBarButtonItem = refreshButton;
        // Set title of navigation bar
    self.navigationItem.title = @"Research & Insights";
    
    // Add UIActivityIndicatorView to dead center of the app to use when refreshing the entire feed.
    CGPoint centerPoint = CGPointMake(self.view.bounds.size.width / 2.0, self.view.bounds.size.height / 2.0);
    _feedLoadIndicator = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(centerPoint.x - (kActivityIndicatorSize / 2.0), centerPoint.y - (kActivityIndicatorSize / 2.0),
                                                                                   kActivityIndicatorSize, kActivityIndicatorSize)];
    _feedLoadIndicator.hidesWhenStopped = YES;
    [_collectionView addSubview:_feedLoadIndicator];
    
    // Start by calling refresh: to load the feed
    [self refresh];
}

- (void)refresh {
    [[PCNetworking sharedNetworking] fetchRssFeed];
    
    // Set UI to have loading progress bar in center of screen, reduce opacity down to 0.3
    [_feedLoadIndicator startAnimating];
    [UIView animateWithDuration:0.75f animations: ^{
        [self.collectionView setAlpha:0.3f];
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma Mark - UICollectionViewDelegate

//- (nonnull __kindof UICollectionViewCell *)collectionView:(nonnull UICollectionView *)collectionView cellForItemAtIndexPath:(nonnull NSIndexPath *)indexPath {
//    static NSString *reuseIdentifier = @"BlogItemCell";
//    
//    return
//}
//
//- (NSInteger)collectionView:(nonnull UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
//    switch (section) {
//        case 0:
//            return 1;
//            break;
//            
//        default:
//            return 0; // set items to 0 while the feed loads
//            break;
//    }
//}


    // The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kBlogItemCellId forIndexPath:indexPath];
    
    cell.backgroundColor=[UIColor greenColor];
    return cell;
}

- (NSInteger)collectionView:(nonnull UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return 15;
}


- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(125, 100);
}

#pragma Mark - UICollectionViewDataSource


@end
