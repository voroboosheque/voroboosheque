//
//  MBoard.h
//  voroboosheque
//
//  Created by admin on 24/02/15.
//  Copyright (c) 2015 voroboosheque. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface MBoard : NSManagedObject

@property (nonatomic, retain) NSNumber * bumpLimit;
@property (nonatomic, retain) NSString * defaultName;
@property (nonatomic, retain) NSNumber * enablePosting;
@property (nonatomic, retain) NSString * id;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * pages;
@property (nonatomic, retain) NSNumber * sage;
@property (nonatomic, retain) NSNumber * tripcodes;
@property (nonatomic, retain) NSManagedObject *category;

@end
