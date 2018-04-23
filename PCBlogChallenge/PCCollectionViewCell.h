//
//  PCCollectionViewCell.h
//  PCBlogChallenge
//
//  Created by Brian Goo on 4/20/18.
//  Copyright © 2018 Brian Goo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PCLabel.h"
#import "PCFeedItem.h"

@interface PCCollectionViewCell : UICollectionViewCell

@property (nonatomic, strong) UIImageView *itemImage;

@property (nonatomic, strong) UIActivityIndicatorView *imageLoadActivity;

@property (nonatomic, strong) PCLabel *itemTitleLabel;

- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;

- (void)setDataSource:(PCFeedItem *)item;

- (void)loadImage:(NSString *)imageUrlStr;

@end
