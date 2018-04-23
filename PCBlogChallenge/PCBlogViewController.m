//
//  ViewController.m
//  PCBlogChallenge
//
//  Created by Brian Goo on 4/9/18.
//  Copyright © 2018 Brian Goo. All rights reserved.
//

#import "PCBlogViewController.h"
#import "PCNetworking.h"
#import "PCCollectionHeaderView.h"
#import "PCCollectionViewCell.h"
#import "PCCollectionViewFlowLayout.h"
#import "PCFeedItem.h"

@interface PCBlogViewController ()

// View's Activity Indicator when (re-)loading blog articles.
@property (nonatomic, strong) UIActivityIndicatorView *feedLoadIndicator;
// Error alert
@property (nonatomic, strong) UIAlertController *alert;

// Section insets and number of items per row.
@property (nonatomic) UIEdgeInsets sectionInsets;
@property (nonatomic) NSInteger numberPerRow;

@end

@implementation PCBlogViewController

static CGFloat const kActivityIndicatorSize = 100.0;
static NSString * const kBlogItemCellId = @"BlogItemCell";
static NSString * const kTopBlogItemHeaderId = @"TopBlogItemHeader";
static NSString * const kPrevArticlesHeaderId = @"PrevArticlesHeader";

- (void)loadView {
    [super loadView];
    
    // Initialize sectionInsets
    self.sectionInsets = UIEdgeInsetsMake(10.0, 10.0, 10.0, 10.0);
    // Initialize numberPerRow (dependent on device)
    if (self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassCompact ||
        self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClassCompact) {
        self.numberPerRow = 2;
    }
    else self.numberPerRow = 3;
    
    self.view = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Initialize the UICollectionView.
    PCCollectionViewFlowLayout *layout = [[PCCollectionViewFlowLayout alloc] init];
    _collectionView = [[UICollectionView alloc] initWithFrame:self.view.frame collectionViewLayout:layout];
    _collectionView.dataSource = self;
    _collectionView.delegate = self;
    // Register headers to collection view
    [_collectionView registerClass:[PCCollectionHeaderView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:kTopBlogItemHeaderId];
    [_collectionView registerClass:[UICollectionReusableView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:kPrevArticlesHeaderId];
    // Register reusable cell to collection view
    [_collectionView registerClass:[PCCollectionViewCell class] forCellWithReuseIdentifier:kBlogItemCellId];
    [_collectionView setBackgroundColor:[UIColor whiteColor]];
    _collectionView.prefetchingEnabled = NO;
    [self.view addSubview:_collectionView];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.collectionView.translatesAutoresizingMaskIntoConstraints = NO;
    // Set autolayout constraints
    [self.collectionView.widthAnchor constraintEqualToAnchor:self.view.widthAnchor].active = YES;
    [self.collectionView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor].active = YES;
    [self.collectionView.topAnchor constraintEqualToAnchor:self.view.topAnchor].active = YES;
    
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
    _feedLoadIndicator.color = [UIColor blackColor];
    [_collectionView addSubview:_feedLoadIndicator];
    
    [[NSNotificationCenter defaultCenter] addObserver:self.collectionView
                                             selector:@selector(reloadData)
                                                 name:UIContentSizeCategoryDidChangeNotification
                                               object:nil];
    
    // Start by calling refresh to load the feed
    [self refresh];
}

- (void)refresh {
    [[PCNetworking sharedNetworking] fetchRssFeed];
    
    // Fade collection view to alpha 0.3, then start animating load indicator afterwards.
    [UIView animateWithDuration:1.75f animations: ^{
        [self.collectionView setAlpha:0.3f];
    } completion:^(BOOL finished) {
        if (finished) {
            // Set UI to have loading progress bar in center of screen, reduce opacity down to 0.3
            [self.feedLoadIndicator startAnimating];
        }
    }];
}

-(void)handleHeaderSelect:(UITapGestureRecognizer *)sender
{
    NSIndexPath *headerIndexPath = [NSIndexPath indexPathForItem:0 inSection:0];
    [self collectionView:_collectionView didSelectItemAtIndexPath:headerIndexPath];
}

#pragma mark - UICollectionViewDelegate

// Event to fire when a collection view item is tapped
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    NSInteger index;
    switch (indexPath.section) {
        case 0:
            index = 0;
            break;
            
        default:
            index = indexPath.item + 1; // off by one
            break;
    }
    PCFeedItem *feedItem = [PCNetworking sharedNetworking].blogEntries[index];
    NSURLComponents *mobileURL = [[NSURLComponents alloc] initWithURL:feedItem.link resolvingAgainstBaseURL:NO];
    mobileURL.query = @"displayMobileNavigation=0"; // append mobile navigation queryString
    // Load mobile URL in a SFSafariViewController
    SFSafariViewController *webVC = [[SFSafariViewController alloc] initWithURL:[mobileURL URL] entersReaderIfAvailable:NO];
    [self presentViewController:webVC animated:YES completion:nil];
}

#pragma Mark - UICollectionViewDataSource

// The header that is returned must be retrieved from a call to
// -dequeueReusableSupplementaryViewOfKind:withReuseIdentifier:atIndexPath:
- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    PCCollectionHeaderView *headerView;
    UICollectionReusableView *secondHeaderView;
    if (kind == UICollectionElementKindSectionHeader) {
        switch (indexPath.section) {
            case 0:
                headerView = ((PCCollectionHeaderView *)[self.collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:kTopBlogItemHeaderId forIndexPath:indexPath]);
                // Check to see if blogEntries has even been loaded.
                if ([PCNetworking sharedNetworking].blogEntries.count > 0) {
                    PCFeedItem *item = [PCNetworking sharedNetworking].blogEntries[indexPath.item];
                    // Bind data source to header.
                    [headerView setDataSource:item];
                    
                    // Add touch event if header is tapped.
                    UITapGestureRecognizer *headerTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleHeaderSelect:)];
                    headerView.userInteractionEnabled = YES;
                    [headerView addGestureRecognizer:headerTapRecognizer];
                }
                return headerView;
                break;
            default:
                secondHeaderView = [self.collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:kPrevArticlesHeaderId forIndexPath:indexPath];
                // Setup second header here with label "Previous Articles" since there's no custom subclass for it.
                PCLabel *secondHeaderLabel = [[PCLabel alloc] initWithFrame:CGRectMake(0, 0, secondHeaderView.bounds.size.width, secondHeaderView.bounds.size.height)];
                secondHeaderLabel.textInsets = UIEdgeInsetsMake(0.0, 10.0, 0.0, 10.0);
                secondHeaderLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
                secondHeaderLabel.adjustsFontForContentSizeCategory = YES;
                secondHeaderLabel.text = @"Previous Articles";
                [secondHeaderView addSubview:secondHeaderLabel];
                
                return secondHeaderView;
                break;
        }
    }
    return headerView;
}

// The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
- (PCCollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    PCCollectionViewCell *cell = (PCCollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:kBlogItemCellId forIndexPath:indexPath];
    
    [cell setNeedsLayout];
    [cell layoutIfNeeded];
    
    // Grab the appropriate blog feed item from blogEntries
    PCFeedItem *item = [PCNetworking sharedNetworking].blogEntries[indexPath.item+1]; // off by one, since first entry goes to header
    // Bind data source to cell and its appropraite properties will be set by cell class.
    [cell setDataSource:item];
    
    return cell;
}

-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 2;
}

- (NSInteger)collectionView:(nonnull UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    switch (section) {
        case 0:
            return 0;
            break;
            
        default:
            // Off by one, because first blog entry goes to header
            return [PCNetworking sharedNetworking].blogEntries.count - 1;
            break;
    }
}

# pragma mark - UICollectionViewDelegateFlowLayout

// Set default size of the headers.
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case 0:
            return CGSizeMake(self.view.frame.size.width, self.view.frame.size.width / 2);
            break;
            
        default:
            return CGSizeMake(self.view.frame.size.width, 10.0);
            break;
    }
    
}

// Set default size of the remaining collection cells according ot sectionInsets and numberPerRow.
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
    // Change aspect ratio of cell for portrait mode for iPhone SE/5/5s
    if (self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassCompact &&
        self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClassRegular) {
        return CGSizeMake(widthPerItem, widthPerItem / 1.25);
    }
    // Change aspect ratio of cell for portrait mode for iPad
    else if (self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular &&
             self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClassRegular) {
        return CGSizeMake(widthPerItem, widthPerItem / 2);
    }
    else
        return CGSizeMake(widthPerItem, widthPerItem / 1.5);
}

// Set insets for the collection view section.
-(UIEdgeInsets) collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    return self.sectionInsets;
}

// Set the minimum spacing for the collection view section.
-(CGFloat) collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
    switch (section) {
        case 0:
            return 0;
            break;
            
        default:
            return self.sectionInsets.left;
            break;
    }
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
{
    switch (section) {
        case 0:
            return 0;
            break;
            
        default:
            return self.sectionInsets.top;
            break;
    }
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    // Need to invalidate layout since iPad rotation doesn't change the Size Class of Normal/Normal.
    [self.collectionView.collectionViewLayout invalidateLayout];
}

#pragma mark - KVO

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
            
            UIAlertAction *action = [UIAlertAction actionWithTitle:okTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
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
