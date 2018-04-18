//
//  NSParseOperation.m
//  PCBlogChallenge
//
//  Created by Brian Goo on 4/11/18.
//  Copyright © 2018 Brian Goo. All rights reserved.
//

#import "PCParseOperation.h"
#import "PCFeedItem.h"

@interface PCParseOperation () <NSXMLParserDelegate>

@property (nonatomic) PCFeedItem *currentFeedItemObject;
@property (nonatomic) NSMutableArray *currentParseBatch;
@property (nonatomic) NSMutableAttributedString *currentParsedCharacterData;

@property (nonatomic, strong) NSDateFormatter *dateFormatter;

@property (assign) BOOL accumulatingParsedCharacterData;
@property (assign) BOOL didAbortParsing;

@property (assign) BOOL seekTitle;
@property (assign) BOOL seekDescription;
@property (assign) BOOL seekPubDate;
@property (assign) BOOL seekMediaURL;
@property (assign) BOOL seekLink;

// a stack queue containing elements as they are being parsed, used to detect malformed XML.
@property (nonatomic, strong) NSMutableArray *elementStack;

@end

@implementation PCParseOperation

#pragma mark - Initialization Stuff


+ (NSString *)AddBlogItemsNotificationName
{
    return @"AddBlogItemsNotification";
}

+ (NSString *)BlogItemsResultsKey
{
    return @"BlogItemsResultsKey";
}

+ (NSString *)BlogFeedErrorNotificationName
{
    return @"BlogFeedErrorNotification";
}

+ (NSString *)BlogFeedMessageErrorKey
{
    return @"BlogFeedMsgErrorKey";
}

-(instancetype)init {
    
    NSAssert(NO, @"Invalid use of init; use initWithData to create PCParseOperation");
    return [self init];
}

-(instancetype)initWithData:(NSData *)blogData {
    self = [super init];
    if (self != nil && blogData != nil) {
        _blogData = [blogData copy];
        
        _dateFormatter = [[NSDateFormatter alloc] init];
        self.dateFormatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
        self.dateFormatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
        // Match the date format of the RSS feed (RFC 233): eg. Thu, 29 Mar 2018 15:32:46 +0000
        self.dateFormatter.dateFormat = @"EEE, dd MMM yyyy HH:mm:ss Z";
    }
    return self;
}

- (void)addBlogItemsToList:(NSArray *)blogItems {
    
    assert([NSThread isMainThread]);
    [[NSNotificationCenter defaultCenter] postNotificationName:PCParseOperation.AddBlogItemsNotificationName
                                                        object:self
                                                      userInfo:@{PCParseOperation.BlogItemsResultsKey: blogItems}];
}

// Main
-(void)main {
    
    /*
     The NSXMLParser could download the data if passed a URL, but this is not desirable because it gives less control over the network communication, particularly in dealing with connection errors.
     */
    NSXMLParser *parser = [[NSXMLParser alloc] initWithData:self.blogData];
    parser.delegate = self;
    [parser parse];
    
    /*
     Depending on the total number of blog items parsed, the last batch might not have been a "full" batch, and thus not been part of the regular batch transfer. So, check the count of the array and, if necessary, send it to the main thread.
     */
    if (self.currentParseBatch.count > 0) {
        [self performSelectorOnMainThread:@selector(addBlogItemsToList:) withObject:self.currentParseBatch waitUntilDone:NO];
    }
}

#pragma mark - Parser constants

/*
 When an PCFeedItem object has been fully constructed, it must be passed to the main thread and the table view in PCBlogViewController must be reloaded to display it. Doing this for every PCFeedItem object one by one will create massive overhead in communicating between threads and reloading the main view which will lead to an unperformant application. Thus, passing feed items in batches, of which its size is designated by the following constant.
 */
static NSUInteger const kSizeOfBlogBatch = 10;

// Reduce potential parsing errors by using string constants declared in a single place.
static NSString * const kEntryElementName = @"item";
static NSString * const kTitleElementName = @"title";

static NSString * const kDescriptionElementName = @"description";
static NSString * const kPublishedDateElementName = @"pubDate";
static NSString * const kMediaURLElementName = @"media:content";
static NSString * const kLinkElementName = @"link";


#pragma mark - NSXMLParserDelegate

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
    
    // add the element to the state stack
    [self.elementStack addObject:elementName];
    
    if ([elementName isEqualToString:kEntryElementName]) { // <item>..
        PCFeedItem *feedItem = [[PCFeedItem alloc] init];
        self.currentFeedItemObject = feedItem;
    }
    else if ([elementName isEqualToString:kTitleElementName] ||         // <title>..
             [elementName isEqualToString:kDescriptionElementName] ||   // <description>..
             [elementName isEqualToString:kLinkElementName] ||          // <link>..
             [elementName isEqualToString:kPublishedDateElementName])   // <pubDate>..
    {
        // Process contents of these elements in parser:foundCharacters:
        _accumulatingParsedCharacterData = YES;
        // The mutable string needs to be reset to empty.
        self.currentParsedCharacterData = [[NSMutableAttributedString alloc] initWithString:@""];
    }
    else if ([elementName isEqualToString:kMediaURLElementName]) {      // <media:content url=".." />
        self.currentFeedItemObject.imageURL = attributeDict[@"url"];
        _accumulatingParsedCharacterData = NO;
    }
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
    
        // check if the end element matches what's last on the element stack
    if ([elementName isEqualToString:self.elementStack.lastObject]) {
        // they match, remove it
        [self.elementStack removeLastObject];
    }
    else {
        // they don't match, we have malformed XML
        NSLog(@"could not find end element of \"%@\"", elementName);
        [self.elementStack removeAllObjects];
        [parser abortParsing];
    }
    
    if ([elementName isEqualToString:kEntryElementName]) {
        
        // end feed item entry, add to the array
        [self.currentParseBatch addObject:self.currentFeedItemObject];
        
        if (self.currentParseBatch.count >= kSizeOfBlogBatch) {
            [self performSelectorOnMainThread:@selector(addBlogItemsToList:) withObject:self.currentParseBatch waitUntilDone:YES];
            
            [self.currentParseBatch removeAllObjects];
        }
    }
    else if ([elementName isEqualToString:kTitleElementName]) {
        self.currentFeedItemObject.title = self.currentParsedCharacterData;
    }
    else if ([elementName isEqualToString:kDescriptionElementName]) {
        self.currentFeedItemObject.itemDescription = self.currentParsedCharacterData;
    }
    else if ([elementName isEqualToString:kPublishedDateElementName]) {
        self.currentFeedItemObject.pubDate = [self.dateFormatter dateFromString:[self.currentParsedCharacterData string]];
    }
    else if ([elementName isEqualToString:kLinkElementName]) {
        self.currentFeedItemObject.link = [NSURL URLWithString:[self.currentParsedCharacterData string]];
    }
    else if ([elementName isEqualToString:kMediaURLElementName]) {
        // Do nothing, this is self-closing tag.
    }
    
        // Stop accumulating parsed character data. We won't start again until specific elements begin.
    _accumulatingParsedCharacterData = NO;
}

/**
 Collect data within an element. This could be long, so the XML parser may call this as a batch operation until finished
 */
- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    
    if (self.accumulatingParsedCharacterData) {
            // If the current element is one whose content we care about, append 'string'
            // to the property that holds the content of the current element.
            //
        [self.currentParsedCharacterData appendAttributedString:[[NSAttributedString alloc] initWithString:string]];
    }
}

-(void)parser:(NSXMLParser *)parser foundCDATA:(NSData *)CDATABlock {
    // Check top element in elementStack to figure out if this is within description element
    if ([self.elementStack.lastObject isEqualToString:kDescriptionElementName]) {
        NSMutableString *cdataStr = [[NSMutableString alloc] initWithData:CDATABlock encoding:NSUTF8StringEncoding];
        // remove <p></p> tags from cdataStr
        [cdataStr replaceOccurrencesOfString:@"<p>" withString:@""
                                                options:0
                                                  range:NSMakeRange(0, cdataStr.length)];
        [cdataStr replaceOccurrencesOfString:@"</p>" withString:@""
                                                options:0
                                                  range:NSMakeRange(0, cdataStr.length)];
        // html decode cdataStr
        NSDictionary *options = @{NSDocumentTypeDocumentAttribute:NSHTMLTextDocumentType,
                                  NSCharacterEncodingDocumentAttribute:@(NSUTF8StringEncoding)};
        NSAttributedString *decodedString = [[NSAttributedString alloc] initWithString:cdataStr attributes:options];
        [self.currentParsedCharacterData appendAttributedString:decodedString];
    }
}

/**
 An error occurred while parsing the earthquake data: post the error as an NSNotification to our app delegate.
 */
- (void)handleBlogItemsError:(NSError *)parseError {
    
    assert([NSThread isMainThread]);
    [[NSNotificationCenter defaultCenter] postNotificationName:PCParseOperation.BlogFeedErrorNotificationName
                                                        object:self
                                                      userInfo:@{PCParseOperation.BlogFeedMessageErrorKey: parseError}];
}

/**
 An error occurred while parsing the blog items data, pass the error to the main thread for handling.
 */
- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError {
    
    if (parseError.code != NSXMLParserDelegateAbortedParseError && !self.didAbortParsing) {
        [self performSelectorOnMainThread:@selector(handleBlogItemsError:) withObject:parseError waitUntilDone:NO];
    }
}

@end
