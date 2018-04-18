//
//  PCParseOperation.h
//  PCBlogChallenge
//
//  Created by Brian Goo on 4/11/18.
//  Copyright © 2018 Brian Goo. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PCParseOperation : NSOperation

@property (copy, readonly) NSData *blogData;

-(instancetype)initWithData:(NSData *)blogData NS_DESIGNATED_INITIALIZER;

+(NSString *)BlogFeedErrorNotificationName;     // NSNotification name for reporting errors
+(NSString *)BlogFeedMessageErrorKey;           // NSNotification userInfo key for obtaining the error message

@end
