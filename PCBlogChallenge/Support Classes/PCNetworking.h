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
-(void) fetchRssFeedWithXMLParserDelegate:(id<NSXMLParserDelegate> *)delegate completionHandler:(void (^)(NSString *, NSError *))completionBlock;

@end

