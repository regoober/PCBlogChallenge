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
// Fetches the blog RSS feed.
-(void) fetchRssFeed;
-(void) fetchImageUrl:(NSString *)urlString completionHandler:(void (^)(UIImage *, NSError *))completionBlock;

@end

