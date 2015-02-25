//
//  MakabaDataManager.h
//  voroboosheque
//
//  Created by admin on 23/02/15.
//  Copyright (c) 2015 voroboosheque. All rights reserved.
//

#import <Foundation/Foundation.h>
@class UIViewController;

typedef void (^makabaDataReturnBlockWithArray) (NSArray *result);
typedef void (^makabaDataReturnBlockWithError) (NSError *error);

@interface MakabaDataManager : NSObject


@property (nonatomic) UIViewController *currentViewController;

+(id)shared;

-(NSArray*)getCachedCategories;
-(NSArray*)getCachedBoards;
//-(void)getBoardsDataWithSuccessHandler:(makabaDataReturnBlockWithArray)successHandler
//                        failureHandler:(makabaDataReturnBlockWithError)failureHandler;

-(void)getBoardsDataWithSuccessHandler:(void (^)(NSArray *categories, NSArray *boards))successHandler
                        failureHandler:(makabaDataReturnBlockWithError)failureHandler;

@end
