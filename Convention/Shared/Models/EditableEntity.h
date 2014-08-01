//
//  EditableEntity.h
//  Pods
//
//  Created by David Jafari on 7/30/14.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Error;

@interface EditableEntity : NSManagedObject

@property (nonatomic, retain) NSSet *errors;
@property (nonatomic, retain) NSSet *warnings;
@end

@interface EditableEntity (CoreDataGeneratedAccessors)

- (void)addErrorsObject:(Error *)value;
- (void)removeErrorsObject:(Error *)value;
- (void)addErrors:(NSSet *)values;
- (void)removeErrors:(NSSet *)values;

- (void)addWarningsObject:(Error *)value;
- (void)removeWarningsObject:(Error *)value;
- (void)addWarnings:(NSSet *)values;
- (void)removeWarnings:(NSSet *)values;

@end
