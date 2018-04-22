//
//  PCCollectionHeaderView.m
//  PCBlogChallenge
//
//  Created by Brian Goo on 4/20/18.
//  Copyright © 2018 Brian Goo. All rights reserved.
//

#import "PCCollectionHeaderView.h"
#import "PCNetworking.h"

@implementation PCCollectionHeaderView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.translatesAutoresizingMaskIntoConstraints = NO;
        
        self.layer.borderWidth = 0.5f;
        self.layer.borderColor = [UIColor lightGrayColor].CGColor;
        // Set blog item image to take up top 70% of cell
        _itemImage = [[UIImageView alloc] initWithFrame:CGRectMake(0.0, 0.0, self.bounds.size.width, self.bounds.size.height * 0.7)];
        _itemImage.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        // Set up activity indicator in center of blog item image
        _headerImageActivity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        _headerImageActivity.hidesWhenStopped = YES;
        _headerImageActivity.center = CGPointMake(_itemImage.frame.size.width / 2, _itemImage.frame.size.height / 2);
        // Set blog item title to take up next 15% of cell immediately below
        _itemTitleLabel = [[PCLabel alloc] initWithFrame:CGRectMake(0.0, self.bounds.size.height * 0.7, self.bounds.size.width, self.bounds.size.height * 0.15)];
        _itemTitleLabel.textInsets = UIEdgeInsetsMake(0.0, 10.0, 0.0, 10.0);
        _itemTitleLabel.numberOfLines = 1;
        _itemTitleLabel.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        _itemTitleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
        _itemTitleLabel.adjustsFontForContentSizeCategory = YES;
        // Set blog item description to take up last 15% of cell on bottom
        _itemDescription = [[PCLabel alloc] initWithFrame:CGRectMake(0.0, self.bounds.size.height * 0.85, self.bounds.size.width, self.bounds.size.height * 0.15)];
        _itemDescription.textInsets = UIEdgeInsetsMake(0.0, 10.0, 10.0, 10.0);
        _itemDescription.numberOfLines = 2;
        _itemDescription.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        _itemDescription.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption2];
        _itemDescription.adjustsFontForContentSizeCategory = YES;
        [self addSubview:_itemImage];
        [self addSubview:_headerImageActivity];
        [self addSubview:_itemTitleLabel];
        [self addSubview:_itemDescription];
        
//        [_itemImage.topAnchor constraintEqualToAnchor:self.topAnchor].active = YES;
//        [_itemImage.widthAnchor constraintEqualToAnchor:self.widthAnchor].active = YES;
//        [_itemTitleLabel.topAnchor constraintEqualToAnchor:_itemImage.bottomAnchor].active = YES;
//        [_itemDescription.topAnchor constraintEqualToAnchor:_itemTitleLabel.bottomAnchor].active = YES;
//        [_itemDescription.bottomAnchor constraintEqualToAnchor:self.bottomAnchor].active = YES;
    }
    
    return self;
}

- (void)loadImage:(NSString *)imageUrlStr
{
    _itemImage.image = nil;
    [_headerImageActivity startAnimating];
    [[PCNetworking sharedNetworking] fetchImageUrl:imageUrlStr completionHandler:^(UIImage *img, NSURL *url, NSError *err) {
        // Once image has been loaded, display it in header
        //if (imageUrlStr == url.absoluteString) {
        self.itemImage.image = img;
        [self.itemImage setNeedsDisplay];
        [self.headerImageActivity stopAnimating];
        //}
    }];
}

@end
