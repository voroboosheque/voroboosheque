//
//  MThread.h
//  voroboosheque
//
//  Created by admin on 04/03/15.
//  Copyright (c) 2015 voroboosheque. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class MBoard, MPost;

@interface MThread : NSManagedObject

@property (nonatomic, retain) NSNumber * num;
@property (nonatomic, retain) NSOrderedSet *posts;
@property (nonatomic, retain) MBoard *board;
@end

@interface MThread (CoreDataGeneratedAccessors)

- (void)insertObject:(MPost *)value inPostsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromPostsAtIndex:(NSUInteger)idx;
- (void)insertPosts:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removePostsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInPostsAtIndex:(NSUInteger)idx withObject:(MPost *)value;
- (void)replacePostsAtIndexes:(NSIndexSet *)indexes withPosts:(NSArray *)values;
- (void)addPostsObject:(MPost *)value;
- (void)removePostsObject:(MPost *)value;
- (void)addPosts:(NSOrderedSet *)values;
- (void)removePosts:(NSOrderedSet *)values;
@end
