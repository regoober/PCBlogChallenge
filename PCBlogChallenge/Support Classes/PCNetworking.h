//
//  PCNetworking.h
//  PCBlogChallenge
//
//  Created by Brian Goo on 4/10/18.
//  Copyright © 2018 Brian Goo. All rights reserved.
//

@interface PCNetworking : NSObject

// The singleton instance of the CDSRequest.
+(PCNetworking *)sharedNetworking;

// The blog items array to be retrieved by the UI.
@property (readonly) NSMutableArray *blogEntries;
// The error to be retrieved by the UI.
@property (readonly) NSError *error;

// Fetches the blog RSS feed.
-(void) fetchRssFeed;
-(void) fetchImageUrl:(NSString *)urlString completionHandler:(void (^)(UIImage *, NSURL *, NSError *))completionBlock;

@end

