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
        // Set blog item image to take up top 60% of cell
        _itemImage = [[UIImageView alloc] initWithFrame:CGRectMake(0.0, 0.0, self.bounds.size.width, self.bounds.size.height * 0.6)];
        _itemImage.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        // Set up activity indicator in center of blog item image
        _headerImageActivity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        _headerImageActivity.hidesWhenStopped = YES;
        _headerImageActivity.center = CGPointMake(_itemImage.frame.size.width / 2, _itemImage.frame.size.height / 2);
        // Set blog item title to take up next chunk of space immediately below
        _itemTitleLabel = [[PCLabel alloc] initWithFrame:CGRectMake(0.0, _itemImage.bounds.size.height, self.bounds.size.width, _itemTitleLabel.bounds.size.height * 2)];
        _itemTitleLabel.textInsets = UIEdgeInsetsMake(5.0, 10.0, 5.0, 10.0);
        _itemTitleLabel.numberOfLines = 1;
        _itemTitleLabel.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        _itemTitleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
        _itemTitleLabel.adjustsFontForContentSizeCategory = YES;
        // Set blog item description to take up last chunk of space on bottom
        _itemDescription = [[PCLabel alloc] initWithFrame:CGRectMake(0.0, _itemImage.bounds.size.height + _itemTitleLabel.bounds.size.height, self.bounds.size.width, _itemDescription.bounds.size.height * 2)];
        _itemDescription.textInsets = UIEdgeInsetsMake(0.0, 10.0, 5.0, 10.0);
        _itemDescription.numberOfLines = 2;
        _itemDescription.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        _itemDescription.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption2];
        _itemDescription.adjustsFontForContentSizeCategory = YES;
        [self addSubview:_itemImage];
        [self addSubview:_headerImageActivity];
        [self addSubview:_itemTitleLabel];
        [self addSubview:_itemDescription];
        
        [self setupConstraints];
    }
    
    return self;
}

- (void)setupConstraints
{
    [NSLayoutConstraint activateConstraints:
     @[[self.leadingAnchor constraintEqualToAnchor:_itemImage.leadingAnchor],
       [self.topAnchor constraintEqualToAnchor:_itemImage.topAnchor],
       [self.trailingAnchor constraintEqualToAnchor:_itemImage.trailingAnchor],
       [self.bottomAnchor constraintEqualToAnchor:_itemDescription.bottomAnchor],
       [self.leadingAnchor constraintEqualToAnchor:_itemTitleLabel.leadingAnchor],
       [self.trailingAnchor constraintEqualToAnchor:_itemTitleLabel.trailingAnchor],
       [self.leadingAnchor constraintEqualToAnchor:_itemDescription.leadingAnchor],
       [self.trailingAnchor constraintEqualToAnchor:_itemDescription.trailingAnchor],
       [_itemImage.bottomAnchor constraintEqualToAnchor:_itemTitleLabel.topAnchor],
       [_itemTitleLabel.heightAnchor constraintEqualToConstant:_itemTitleLabel.numberOfLines * _itemTitleLabel.font.lineHeight + _itemTitleLabel.textInsets.top + _itemTitleLabel.textInsets.bottom],
       [_itemTitleLabel.bottomAnchor constraintEqualToAnchor:_itemDescription.topAnchor],
       [_itemDescription.heightAnchor constraintEqualToConstant:_itemDescription.numberOfLines * _itemDescription.font.lineHeight + _itemDescription.textInsets.top + _itemDescription.textInsets.bottom]
       ]];
    [_itemImage setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisVertical];
    [_itemTitleLabel setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
    [_itemDescription setContentHuggingPriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisVertical];
    _itemImage.translatesAutoresizingMaskIntoConstraints = NO;
    _itemTitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _itemDescription.translatesAutoresizingMaskIntoConstraints = NO;
}

- (void)setDataSource:(PCFeedItem *)item
{
    // Load the image asynchronously.
    [self loadImage:item.imageURL];
    // Attach header title, make slightly bolder.
    NSMutableAttributedString *title = [[NSMutableAttributedString alloc] initWithAttributedString:item.title];
    [title addAttribute:NSStrokeWidthAttributeName value:@(-2.0) range:NSMakeRange(0, item.title.length)];
    self.itemTitleLabel.attributedText = title;
    // Prepend the published date in long format before the description, separated by an em-dash
    NSDateFormatter *normalDate = [[NSDateFormatter alloc] init];
    [normalDate setDateFormat:@"MMMM d, yyyy"];
    NSMutableAttributedString *datedDescAttStr = [[NSMutableAttributedString alloc] initWithString:[normalDate stringFromDate:item.pubDate]];
    [datedDescAttStr appendAttributedString:[[NSAttributedString alloc] initWithString:@" — "]];
    [datedDescAttStr appendAttributedString:item.itemDescription];
    self.itemDescription.attributedText = datedDescAttStr;
}

- (void)loadImage:(NSString *)imageUrlStr
{
    _itemImage.image = nil;
    [_headerImageActivity startAnimating];
    [[PCNetworking sharedNetworking] fetchImageUrl:imageUrlStr completionHandler:^(UIImage *img, NSURL *url, NSError *err) {
        // Once image has been loaded, display it in header
        if ([imageUrlStr isEqualToString:url.absoluteString]) {
            self.itemImage.image = img;
            [self.itemImage setNeedsDisplay];
            [self.headerImageActivity stopAnimating];
        }
    }];
}

@end
