//
//  MBoardCategory.h
//  voroboosheque
//
//  Created by admin on 24/02/15.
//  Copyright (c) 2015 voroboosheque. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class MBoard;

@interface MBoardCategory : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSSet *boards;
@end

@interface MBoardCategory (CoreDataGeneratedAccessors)

- (void)addBoardsObject:(MBoard *)value;
- (void)removeBoardsObject:(MBoard *)value;
- (void)addBoards:(NSSet *)values;
- (void)removeBoards:(NSSet *)values;

@end
