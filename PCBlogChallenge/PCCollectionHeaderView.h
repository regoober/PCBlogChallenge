//
//  PCCollectionHeaderView.h
//  PCBlogChallenge
//
//  Created by Brian Goo on 4/20/18.
//  Copyright © 2018 Brian Goo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PCLabel.h"
#import "PCFeedItem.h"

@interface PCCollectionHeaderView : UICollectionReusableView

@property (nonatomic, strong) UIImageView *itemImage;

@property (nonatomic, strong) UIActivityIndicatorView *headerImageActivity;

@property (nonatomic, strong) PCLabel *itemTitleLabel;

@property (nonatomic, strong) PCLabel *itemDescription;

- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;

- (void)setDataSource:(PCFeedItem *)item;

- (void)loadImage:(NSString *)imageUrlStr;

@end
