//
//  EditableEntity.h
//  Convention
//
//  Created by septerr on 12/27/13.
//  Copyright (c) 2013 Convention Innovations. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface EditableEntity : NSManagedObject

@property(nonatomic, retain) NSSet *errors;
@end

@interface EditableEntity (CoreDataGeneratedAccessors)

- (void)addErrorsObject:(NSManagedObject *)value;

- (void)removeErrorsObject:(NSManagedObject *)value;

- (void)addErrors:(NSSet *)values;

- (void)removeErrors:(NSSet *)values;

@end
