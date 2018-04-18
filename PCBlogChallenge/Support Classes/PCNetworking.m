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
static NSString * const kBlogURL = @"​https://www.personalcapital.com/blog/feed/?cat=3,891,890,68,284";

// Objects for creating singleton of this class
static PCNetworking *_sharedNetworking = nil;
static dispatch_once_t token = 0;

@interface PCNetworking ()

@property (nonatomic, strong) NSMutableArray *blogEntries;
@property (nonatomic, strong) NSError *error;

// queue that manages our NSOperation for parsing blog data
@property (nonatomic, strong) NSOperationQueue *parseQueue;

@end

@implementation PCNetworking

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
                        if ((httpResponse.statusCode/100 == 2) && [response.MIMEType isEqual:@"application/xml"]) {
                            
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

-(void) fetchImageUrl:(NSString *)urlString completionHandler:(void (^)(UIImage *, NSError *))completionBlock
{
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLSessionDataTask *downloadImageTask = [[NSURLSession sharedSession] dataTaskWithURL:url
                                                                    completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                                        // fire completionBlock according to error or valid image data response
                                                                        if (error != nil) {
                                                                            completionBlock(nil, error);
                                                                        }
                                                                        else {
                                                                            UIImage *img = [UIImage imageWithData:data];
                                                                            completionBlock(img, nil);
                                                                        }
    }];
    // Start downloading image for article
    [downloadImageTask resume];
}
@end
