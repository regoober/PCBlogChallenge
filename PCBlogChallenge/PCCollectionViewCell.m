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
        _itemImage = [[UIImageView alloc] initWithFrame:CGRectMake(0.0, 0.0, self.bounds.size.width, self.bounds.size.width * 2 / 7)];
        
        _imageLoadActivity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        _imageLoadActivity.hidesWhenStopped = YES;
        _imageLoadActivity.center = CGPointMake(_itemImage.frame.size.width / 2, _itemImage.frame.size.height / 2);
        
        _itemTitleLabel = [[PCLabel alloc] initWithFrame:CGRectMake(0.0, _itemImage.bounds.size.height, self.bounds.size.width, _itemTitleLabel.bounds.size.height * 2)];
        // Set text insets to 10.0 on leading/trailing, 5.0 on top/bottom.
        _itemTitleLabel.textInsets = UIEdgeInsetsMake(5.0, 10.0, 5.0, 10.0);
        _itemTitleLabel.numberOfLines = 2;
        _itemTitleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption2];
        _itemTitleLabel.adjustsFontForContentSizeCategory = YES;
        
        [self.contentView addSubview:_itemImage];
        [self.contentView addSubview:_imageLoadActivity];
        [self.contentView addSubview:_itemTitleLabel];
        
        [self setupConstraints];
    }
    
    return self;
}

- (void)setupConstraints
{
    [NSLayoutConstraint activateConstraints:
     @[[self.contentView.leadingAnchor constraintEqualToAnchor:_itemImage.leadingAnchor],
       [self.contentView.topAnchor constraintEqualToAnchor:_itemImage.topAnchor],
       [self.contentView.trailingAnchor constraintEqualToAnchor:_itemImage.trailingAnchor],
       [_itemTitleLabel.topAnchor constraintEqualToAnchor:_itemImage.bottomAnchor],
       [_itemTitleLabel.heightAnchor constraintEqualToConstant:_itemTitleLabel.numberOfLines * _itemTitleLabel.font.lineHeight + _itemTitleLabel.textInsets.top + _itemTitleLabel.textInsets.bottom],
       
       [_itemTitleLabel.heightAnchor constraintEqualToConstant:(_itemTitleLabel.numberOfLines * _itemTitleLabel.font.lineHeight + _itemTitleLabel.textInsets.top + _itemTitleLabel.textInsets.bottom) ],
       [self.contentView.bottomAnchor constraintEqualToAnchor:_itemTitleLabel.bottomAnchor],
       [self.contentView.leadingAnchor constraintEqualToAnchor:_itemTitleLabel.leadingAnchor],
       [self.contentView.trailingAnchor constraintEqualToAnchor:_itemTitleLabel.trailingAnchor]
       
       ]];
    [_itemImage setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisVertical];
    [_itemTitleLabel setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
    [_itemTitleLabel setContentCompressionResistancePriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisVertical];
    _itemImage.translatesAutoresizingMaskIntoConstraints = NO;
    _itemTitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
}

- (void)setDataSource:(PCFeedItem *)item
{
    [self loadImage:item.imageURL];
    _itemTitleLabel.attributedText = item.title;
}

- (void)loadImage:(NSString *)imageUrlStr
{
    // Clear the image, fetch the image for item, and populate the itemImage once it's complete
    _itemImage.image = nil;
    [_imageLoadActivity startAnimating];
    [[PCNetworking sharedNetworking] fetchImageUrl:imageUrlStr completionHandler:^(UIImage *img, NSURL *url, NSError *err) {
        // Once image has been loaded, display it in header
        if ([imageUrlStr isEqualToString:url.absoluteString]) {
            self.itemImage.image = img;
            [self.itemImage setNeedsDisplay];
            [self.imageLoadActivity stopAnimating];
        }
    }];
}

@end
