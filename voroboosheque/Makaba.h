//
//  Makaba.h
//  vorobooshek
//
//  Created by admin on 19/02/15.
//  Copyright (c) 2015 voroboosheque. All rights reserved.
//

#import <Foundation/Foundation.h>
@import UIKit;

typedef void (^makabaReturnBlockWithDictionary) (NSDictionary *result);
typedef void (^makabaReturnBlockWithArray) (NSArray *result);
typedef void (^makabaReturnBlockWithError) (NSError *error);

@protocol makabaDelegateProtocol <NSObject>

// display UIWebView with this data, set Makaba as its' delegate
-(void)makabaNeedsCloudflareVerification:(NSData*)data forURL:(NSURL*)url;

-(void)makabaDidFinishCloudflareVerification;

@end

@interface Makaba : NSObject <UIWebViewDelegate>

@property (nonatomic) id makabaDelegate;

+(id)shared;

/* json responses described:
 
 post
     date
     email
     files ()
     lasthit
     name
     num - global post number;
     op - 1 for OP
     parent - OP post number, 0 for OP post
     sticky
     subject
     timestamp
     trip
     banned
     closed
 
 threadInfo
     num - global board ID of this thread
     posts
     timestamp

 
 */

-(void)getBoardsWithSuccessHandler:(makabaReturnBlockWithDictionary)successHandler
                            failureHandler:(makabaReturnBlockWithError)failureHandler;

// retrieves array of strings with threads numbers (global board IDs)
-(void)getThreadsForBoard:(NSString*)board
           successHandler:(makabaReturnBlockWithArray)successHandler
           failureHandler:(makabaReturnBlockWithError)failureHandler;

// retrieves array of posts with fields described above. post - global board post ID.
// empty if there's no posts after 'post' post
-(void)getPostsForBoard:(NSString*)board
              andThread:(NSUInteger)thread
       startingFromPost:(NSUInteger)post
         successHandler:(makabaReturnBlockWithDictionary)successHandler
         failureHandler:(makabaReturnBlockWithError)failureHandler;

// retrieves array of posts with fields described above. startingPosition - local position of a post in a thread.
// empty if there's no posts after startingPosition
-(void)getPostsForBoard:(NSString*)board
              andThread:(NSUInteger)thread
   startingFromPosition:(NSUInteger)startingPosition
         successHandler:(makabaReturnBlockWithDictionary)successHandler
         failureHandler:(makabaReturnBlockWithError)failureHandler;

// retrieves actual info on a thread
-(void)getThreadInfoForBoard:(NSString*)board
                   andThread:(NSUInteger)thread
              successHandler:(makabaReturnBlockWithDictionary)successHandler
              failureHandler:(makabaReturnBlockWithError)failureHandler;
@end
