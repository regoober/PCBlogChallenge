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

// View's Activity Indicator when (re-)loading blog articles.
@property (nonatomic, strong) UIActivityIndicatorView *feedLoadIndicator;
// Error alert
@property (nonatomic, strong) UIAlertController *alert;

// Section insets and number of items per row.
@property (nonatomic) UIEdgeInsets sectionInsets;
@property (nonatomic) CGFloat numberPerRow;

@end

@implementation PCBlogViewController

static CGFloat const kActivityIndicatorSize = 100.0;
static NSString * const kBlogItemCellId = @"BlogItemCell";

- (void)loadView {
    [super loadView];
    
    // Initialize sectionInsets and numberPerRow (dependent on device)
    switch ([UIDevice currentDevice].userInterfaceIdiom) {
        case UIUserInterfaceIdiomPhone:
            self.sectionInsets = UIEdgeInsetsMake(10.0, 10.0, 10.0, 10.0);
            self.numberPerRow = 2.0f;
            break;
        default:
            self.sectionInsets = UIEdgeInsetsMake(20.0, 20.0, 20.0, 20.0);
            self.numberPerRow = 3.0f;
            break;
    }
    
    self.view = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Initialize the UICollectionView.
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    _collectionView = [[UICollectionView alloc] initWithFrame:self.view.frame collectionViewLayout:layout];
    _collectionView.dataSource = self;
    _collectionView.delegate = self;
    
    [_collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:kBlogItemCellId];
    [_collectionView setBackgroundColor:[UIColor whiteColor]];
    [self.view addSubview:_collectionView];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // listen for incoming blogItems from our data source using KVO
    [[PCNetworking sharedNetworking] addObserver:self forKeyPath:@"blogItems" options:0 context:nil];

    // listen for errors reported by our data source using KVO, so we can report it in our own way
    [[PCNetworking sharedNetworking] addObserver:self forKeyPath:@"error" options:NSKeyValueObservingOptionNew context:nil];

    // Add "refresh" button to top right corner of UINav bar.
    UIBarButtonItem *refreshButton = [[UIBarButtonItem alloc]
                                      initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
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
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    // Start by calling refresh to load the feed
    [self refresh];
}

- (void)refresh {
    [[PCNetworking sharedNetworking] fetchRssFeed];
    
    // Fade collection view to alpha 0.3, then start animating load indicator afterwards.
    [UIView animateWithDuration:0.75f animations: ^{
        [self.collectionView setAlpha:0.3f];
    } completion:^(BOOL finished) {
        if (finished) {
            // Set UI to have loading progress bar in center of screen, reduce opacity down to 0.3
            [self.feedLoadIndicator startAnimating];
        }
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma Mark - UICollectionViewDelegate

// The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kBlogItemCellId forIndexPath:indexPath];
    
    cell.backgroundColor=[UIColor greenColor];
    return cell;
}

-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(nonnull UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [PCNetworking sharedNetworking].blogEntries.count;
}

# pragma Mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout*)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    // Calculate total spadding space per row
    CGFloat paddingSpace = self.sectionInsets.left * (self.numberPerRow + 1);
    // Calculate remaining width available for that row
    CGFloat availableWidth = self.view.frame.size.width - paddingSpace;
    // Calculate width per item based on available width
    CGFloat widthPerItem = availableWidth / self.numberPerRow;
    
    return CGSizeMake(widthPerItem, widthPerItem / 1.25);
}

-(UIEdgeInsets) collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    return self.sectionInsets;
}

-(CGFloat) collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
    return self.sectionInsets.left;
}

#pragma Mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    PCNetworking *networkingDS = object;
    
    if ([keyPath isEqualToString:@"blogItems"]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
            // Reload data from data source to collection view.
            [self.collectionView reloadData];
            
            // Stop animating load indicator.
            [self.feedLoadIndicator stopAnimating];
            //Unfade collection view.
            [UIView animateWithDuration:0.75f animations: ^{
                [self.collectionView setAlpha:1.0f];
            } completion:nil];
        });
    }
    else if ([keyPath isEqualToString:@"error"]) {
        // Crude error handler which would present a dialog box in the event of a load error.
        dispatch_async(dispatch_get_main_queue(), ^{
            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
            
            NSError *error = networkingDS.error;
            
            NSString *errorMessage = error.localizedDescription;
            NSString *alertTitle = NSLocalizedString(@"Error", @"Title for alert displayed when download or parse error occurs.");
            NSString *okTitle = NSLocalizedString(@"OK", @"OK Title for alert displayed when download or parse error occurs.");
            
            self.alert = [UIAlertController alertControllerWithTitle:alertTitle message:errorMessage preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *action = [UIAlertAction actionWithTitle:okTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction *act) {
                    //..
            }];
            [self.alert addAction:action];
            
            if (self.presentedViewController == nil) {
                [self presentViewController:self.alert animated:YES completion:^ {
                    // Stop animating load indicator.
                    [self.feedLoadIndicator stopAnimating];
                    //Unfade collection view.
                    [UIView animateWithDuration:0.75f animations: ^{
                        [self.collectionView setAlpha:1.0f];
                    } completion:nil];
                }];
            }
        });
    }
    else { // pass on any other KVO observers up to the superclass.
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

@end
