//
//  PCCollectionViewCell.m
//  PCBlogChallenge
//
//  Created by Brian Goo on 4/20/18.
//  Copyright © 2018 Brian Goo. All rights reserved.
//

#import "PCCollectionViewCell.h"
#import "PCNetworking.h"

@implementation PCCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.translatesAutoresizingMaskIntoConstraints = NO;
        // Set cell border width and color.
        self.layer.borderWidth = 0.5f;
        self.layer.borderColor = [UIColor lightGrayColor].CGColor;
        // Initialize item image to top 2/3s, title label to bottom 1/3.
        _itemImage = [[UIImageView alloc] initWithFrame:CGRectMake(0.0, 0.0, self.bounds.size.width, self.bounds.size.height * 0.67)];
        _itemImage.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        _imageLoadActivity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        _imageLoadActivity.hidesWhenStopped = YES;
        _imageLoadActivity.center = CGPointMake(_itemImage.frame.size.width / 2, _itemImage.frame.size.height / 2);
        
        _itemTitleLabel = [[PCLabel alloc] initWithFrame:CGRectMake(0.0, self.bounds.size.height * 0.67, self.bounds.size.width, self.bounds.size.height * 0.33)];
        _itemTitleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        // Set text insets to 10.0 on left and right only.
        _itemTitleLabel.textInsets = UIEdgeInsetsMake(0.0, 10.0, 0.0, 10.0);
        _itemTitleLabel.numberOfLines = 2;
        _itemTitleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption2];
        _itemTitleLabel.adjustsFontForContentSizeCategory = YES;
        
        [self.contentView addSubview:_itemImage];
        [self.contentView addSubview:_imageLoadActivity];
        [self.contentView addSubview:_itemTitleLabel];
        
//        [NSLayoutConstraint activateConstraints:@[[_itemImage.leftAnchor constraintEqualToAnchor:self.contentView.leftAnchor],
//                                                  [_itemImage.topAnchor constraintEqualToAnchor:self.contentView.topAnchor],
//                                                  [_itemImage.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor],
//                                                  [_itemTitleLabel.topAnchor constraintEqualToAnchor:_itemImage.bottomAnchor],
//                                                  [_itemTitleLabel.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor]
//                                                  ]];
    }
    
    return self;
}

- (void)loadImage:(NSString *)imageUrlStr
{
    _itemImage.image = nil;
    [_imageLoadActivity startAnimating];
    [[PCNetworking sharedNetworking] fetchImageUrl:imageUrlStr completionHandler:^(UIImage *img, NSURL *url, NSError *err) {
        // Once image has been loaded, display it in header
        //if (imageUrlStr == url.absoluteString) {
            self.itemImage.image = img;
            [self.itemImage setNeedsDisplay];
            [self.imageLoadActivity stopAnimating];
        //}
    }];
}

@end
