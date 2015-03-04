//
//  MBoardCategory.h
//  voroboosheque
//
//  Created by admin on 04/03/15.
//  Copyright (c) 2015 voroboosheque. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class MBoard;

@interface MBoardCategory : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSOrderedSet *boards;
@end

@interface MBoardCategory (CoreDataGeneratedAccessors)

- (void)insertObject:(MBoard *)value inBoardsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromBoardsAtIndex:(NSUInteger)idx;
- (void)insertBoards:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeBoardsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInBoardsAtIndex:(NSUInteger)idx withObject:(MBoard *)value;
- (void)replaceBoardsAtIndexes:(NSIndexSet *)indexes withBoards:(NSArray *)values;
- (void)addBoardsObject:(MBoard *)value;
- (void)removeBoardsObject:(MBoard *)value;
- (void)addBoards:(NSOrderedSet *)values;
- (void)removeBoards:(NSOrderedSet *)values;
@end
