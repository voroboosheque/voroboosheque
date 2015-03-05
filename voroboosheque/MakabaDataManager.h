//
//  MakabaDataManager.h
//  voroboosheque
//
//  Created by admin on 23/02/15.
//  Copyright (c) 2015 voroboosheque. All rights reserved.
//

#import <Foundation/Foundation.h>
@class UIViewController;
@class MBoard;
@class MThread;

typedef void (^makabaDataReturnBlockWithArray) (NSArray *result);
typedef void (^makabaDataReturnBlockWithError) (NSError *error);

@interface MakabaDataManager : NSObject


@property (nonatomic) UIViewController *currentViewController;

+(id)shared;

-(void)resetCache;
-(NSArray*)getCachedCategories;
-(NSArray*)getCachedBoards;
-(NSArray*)getCahcedThreadsForBoard:(MBoard*)board;
-(NSArray *)getCachedPostsForThread:(MThread*)thread;
//-(void)getBoardsDataWithSuccessHandler:(makabaDataReturnBlockWithArray)successHandler
//                        failureHandler:(makabaDataReturnBlockWithError)failureHandler;

-(void)getBoardsDataWithSuccessHandler:(void (^)(NSArray *categories, NSArray *boards))successHandler
                        failureHandler:(makabaDataReturnBlockWithError)failureHandler;

-(void)getThreadsDataForBoard:(MBoard*)board
               successHandler:(void (^)(NSArray *threads))successHandler
               failureHandler:(makabaDataReturnBlockWithError)failureHandler;

-(void)getPostsForThread:(MThread*)thread
    startingFromPosition:(NSUInteger)startingPosition
          successHandler:(void (^)(NSArray *posts))successHandler
          failureHandler:(makabaDataReturnBlockWithError)failureHandler;

@end
