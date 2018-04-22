//
//  PCNetworking.m
//  PCBlogChallenge
//
//  Created by Brian Goo on 4/9/18.
//  Copyright © 2018 Brian Goo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "PCNetworking.h"
#import "PCParseOperation.h"

// The PC blog URL
static NSString * const kBlogURL = @"https://www.personalcapital.com/blog/feed/?cat=3,891,890,68,284";

// Objects for creating singleton of this class
static PCNetworking *_sharedNetworking = nil;
static dispatch_once_t token = 0;

@interface PCNetworking ()

@property (nonatomic, strong) NSMutableArray *blogEntries;
@property (nonatomic, strong) NSError *error;

@property (assign) id addBlogItemsObserver;
@property (assign) id blogErrorObserver;

// queue that manages our NSOperation for parsing blog data
@property (nonatomic, strong) NSOperationQueue *parseQueue;

// image cache to prevent excessive reloads
@property (nonatomic, strong) NSCache *imageCache;

@end

@implementation PCNetworking

-(instancetype)init {
    self = [super init];
    if (self != nil) {
        _blogEntries = [NSMutableArray array];
        
        // Our NSNotification callback from the running NSOperation to add the blogItems
        _addBlogItemsObserver = [[NSNotificationCenter defaultCenter] addObserverForName:PCParseOperation.AddBlogItemsNotificationName
                                                                                  object:nil
                                                                                   queue:nil
                                                                              usingBlock:^(NSNotification *notification) {
            // The NSOperation "ParseOperation" calls this observer with batches of parsed objects, use KVO to notify our client.
            NSArray *incomingItems = [notification.userInfo valueForKey:PCParseOperation.BlogItemsResultsKey];
            
            [self willChangeValueForKey:@"blogItems"];
            [self.blogEntries addObjectsFromArray:incomingItems];
            [self didChangeValueForKey:@"blogItems"];
        }];
        
        // Our NSNotification callback from the running NSOperation when a parsing error has occurred
        _blogErrorObserver = [[NSNotificationCenter defaultCenter] addObserverForName:PCParseOperation.BlogFeedErrorNotificationName
                                                                               object:nil
                                                                                queue:nil
                                                                           usingBlock:^(NSNotification *notification) {
            // The NSOperation "ParseOperation" calls this observer with an error, use KVO to notify our client
            [self willChangeValueForKey:@"error"];
            self.error = [notification.userInfo valueForKey:PCParseOperation.BlogFeedMessageErrorKey];
            [self didChangeValueForKey:@"error"];
        }];
    
        _parseQueue = [NSOperationQueue new];
        
        _imageCache = [[NSCache alloc] init];
    }
    
    return self;
}

// The singleton instance of PCNetworking.
+(PCNetworking *)sharedNetworking
{
    // Create singleton instance using Grand Central Dispatch
    dispatch_once(&token, ^{
        if (_sharedNetworking == nil) {
            _sharedNetworking = [[PCNetworking alloc] init];
        }
    });
    return _sharedNetworking;
}

// Fetches the blog RSS feed.
-(void) fetchRssFeed
{
    // Clear blog entries before reloading them again.
    [self willChangeValueForKey:@"blogItems"];
    [self.blogEntries removeAllObjects];
    [self didChangeValueForKey:@"blogItems"];
    
    NSURL *url = [NSURL URLWithString:kBlogURL];
    NSURLSessionDataTask *downloadFeedTask = [[NSURLSession sharedSession] dataTaskWithURL:url
                                              completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                // Add xml retrieval to main NSOperation queue
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    // back on the main thread, check for errors, if no errors start the parsing
                    if (error != nil && response == nil) {
                        if (error.code == NSURLErrorAppTransportSecurityRequiresSecureConnection) {
                            // Check for error NSURLErrorAppTransportSecurityRequiresSecureConnection (-1022),
                            // due to Info.plist not being properly configured to match the target server.
                            NSAssert(NO, @"NSURLErrorAppTransportSecurityRequiresSecureConnection");
                        }
                        else {
                            // use KVO to notify our client of this error
                            [self willChangeValueForKey:@"error"];
                            self.error = error;
                            [self didChangeValueForKey:@"error"];
                        }
                    }
                    
                    // Check for any returned NSError from the server.
                    // Also, check for http response errors.
                    if (response != nil) {
                        
                        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                        // Check for response code in 200s with MIME type as xml
                        if ((httpResponse.statusCode/100 == 2) && [response.MIMEType isEqual:@"application/rss+xml"]) {
                            
                            /* Update the UI and start parsing the data,
                             Spin up an NSOperation to parse the blog data to keep UI unblocked
                             while the application parses the XML data.
                             */
                            PCParseOperation *parseOperation = [[PCParseOperation alloc] initWithData:data];
                            [self.parseQueue addOperation:parseOperation];
                        }
                        else {
                            NSString *errorString =
                            NSLocalizedString(@"HTTP Error", @"Error message displayed when receiving an error from the server.");
                            NSDictionary *userInfo = @{NSLocalizedDescriptionKey : errorString};
                            
                                // use KVO to notify our client of this error
                            [self willChangeValueForKey:@"error"];
                            self.error = [NSError errorWithDomain:@"HTTP"
                                                             code:httpResponse.statusCode
                                                         userInfo:userInfo];
                            [self didChangeValueForKey:@"error"];
                        }
                    }
                }];
    }];
    
    // Start downloading RSS Feed
    [downloadFeedTask resume];
}

// Fetches the image at the urlString provided, as given by a blog item's media:content element.
-(void) fetchImageUrl:(NSString *)urlString completionHandler:(void (^)(UIImage *, NSURL *, NSError *))completionBlock
{
    // Check if image is in _imageCache and load from there instead
    UIImage *cachedImg = ((UIImage *)[_imageCache objectForKey:urlString]);
    if (cachedImg != nil) {
        completionBlock(cachedImg, [NSURL URLWithString:urlString], nil);
        return;
    }
    
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLSessionDataTask *downloadImageTask = [[NSURLSession sharedSession] dataTaskWithURL:url
                                                                    completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                                        // fire completionBlock according to error or valid image data response
                                                                        if (error != nil) {
                                                                            completionBlock(nil, response.URL, error);
                                                                        }
                                                                        else {
                                                                            UIImage *img = [UIImage imageWithData:data];
                                                                            dispatch_async(dispatch_get_main_queue(), ^{
                                                                                    // Add image to cache
                                                                                [self.imageCache setObject:img forKey:urlString];
                                                                                completionBlock(img, response.URL, nil);
                                                                            });
                                                                        }
    }];
    // Start downloading image for article
    [downloadImageTask resume];
}


// Remove NSNotificationCenter observers upon deallocation.
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self.addBlogItemsObserver];
    [[NSNotificationCenter defaultCenter] removeObserver:self.blogErrorObserver];
}
@end
