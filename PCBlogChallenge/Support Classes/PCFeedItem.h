//
//  PCFeedItem.h
//  PCBlogChallenge
//
//  Created by Brian Goo on 4/10/18.
//  Copyright © 2018 Brian Goo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface PCFeedItem : NSObject

// Title (HTML-encoded) of the blog article.
@property (nonatomic) NSAttributedString *title;
// Description (HTML-encoded in CDATA) of the blog article.
@property (nonatomic) NSAttributedString *itemDescription;
// Image of the blog article.
@property (nonatomic, strong) NSString *imageURL;
// Date and time at which the blog article published.
@property (nonatomic, strong) NSDate *pubDate;
// URL Link to the full blog article.
@property (nonatomic) NSURL *link;

@end
