//
//  MBoard.m
//  voroboosheque
//
//  Created by admin on 04/03/15.
//  Copyright (c) 2015 voroboosheque. All rights reserved.
//

#import "MBoard.h"
#import "MBoardCategory.h"
#import "MThread.h"

#import "MPost.h"


@implementation MBoard

@dynamic bumpLimit;
@dynamic defaultName;
@dynamic enablePosting;
@dynamic id;
@dynamic name;
@dynamic pages;
@dynamic sage;
@dynamic tripcodes;
@dynamic category;
@dynamic threads;

- (void)insertObject:(MThread *)value inThreadsAtIndex:(NSUInteger)idx
{
    NSMutableOrderedSet* tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.threads];
    
    if ([tempSet containsObject:value])
    {
        [tempSet removeObject:value];
    }
    
    [tempSet insertObject:value atIndex:idx];
    
    self.threads = tempSet;
}

@end
