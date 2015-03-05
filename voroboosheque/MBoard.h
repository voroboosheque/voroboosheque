//
//  MBoard.h
//  voroboosheque
//
//  Created by admin on 04/03/15.
//  Copyright (c) 2015 voroboosheque. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class MBoardCategory, MThread;

@interface MBoard : NSManagedObject

@property (nonatomic, retain) NSNumber * bumpLimit;
@property (nonatomic, retain) NSString * defaultName;
@property (nonatomic, retain) NSNumber * enablePosting;
@property (nonatomic, retain) NSString * id;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * pages;
@property (nonatomic, retain) NSNumber * sage;
@property (nonatomic, retain) NSNumber * tripcodes;
@property (nonatomic, retain) MBoardCategory *category;
@property (nonatomic, retain) NSOrderedSet *threads;
@end

@interface MBoard (CoreDataGeneratedAccessors)

- (void)insertObject:(MThread *)value inThreadsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromThreadsAtIndex:(NSUInteger)idx;
- (void)insertThreads:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeThreadsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInThreadsAtIndex:(NSUInteger)idx withObject:(MThread *)value;
- (void)replaceThreadsAtIndexes:(NSIndexSet *)indexes withThreads:(NSArray *)values;
- (void)addThreadsObject:(MThread *)value;
- (void)removeThreadsObject:(MThread *)value;
- (void)addThreads:(NSOrderedSet *)values;
- (void)removeThreads:(NSOrderedSet *)values;
@end
