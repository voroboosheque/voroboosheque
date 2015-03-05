//
//  MPost.h
//  voroboosheque
//
//  Created by admin on 04/03/15.
//  Copyright (c) 2015 voroboosheque. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class MThread;

@interface MPost : NSManagedObject

@property (nonatomic, retain) NSString * comment;
@property (nonatomic, retain) NSNumber * num;
@property (nonatomic, retain) MThread *parent;

@end
