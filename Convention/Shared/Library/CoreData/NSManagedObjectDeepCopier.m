//
// Created by David Jafari on 2/21/15.
// Copyright (c) 2015 Urban Coding. All rights reserved.
//

#import "NSManagedObjectDeepCopier.h"

@interface NSManagedObjectDeepCopier ()

@property NSMutableDictionary *collisionDictionary;
@property NSMutableArray *excludedRelationships;
@property NSManagedObjectContext *context;

@end

@implementation NSManagedObjectDeepCopier

+ (NSManagedObject *)copyEntity:(NSManagedObject *)object {
    return [[[NSManagedObjectDeepCopier alloc] initInContext:object.managedObjectContext excluding:@[ ]] deepCopy:object parentEntity:nil];
}

+ (NSManagedObject *)copyEntity:(NSManagedObject *)object
         excludingRelationships:(NSArray *)relationshipsTraversed
                      toContext:(NSManagedObjectContext *)context {
    return [[[NSManagedObjectDeepCopier alloc] initInContext:context excluding:relationshipsTraversed] deepCopy:object parentEntity:nil];
}

- (id)init {
    [NSException raise:NSDestinationInvalidException format:@"Use static factory methods."];
}

- (id)initInContext:(NSManagedObjectContext *)context excluding:(NSArray *)relationships {
    self = [super init];
    if (self) {
        self.collisionDictionary = [NSMutableDictionary dictionary];
        self.excludedRelationships = [NSMutableArray array];
        self.context = context;
        [self.excludedRelationships addObjectsFromArray:relationships];
    }
    return self;
}

- (NSManagedObject *)deepCopy:(NSManagedObject *)object parentEntity:(NSString *)parentEntity {

    NSString *entityName = [[object entity] name];
    if (parentEntity == nil) parentEntity = @"";

    NSManagedObject *newObject = [NSEntityDescription
            insertNewObjectForEntityForName:entityName
                     inManagedObjectContext:self.context];
    [self.collisionDictionary setObject:newObject forKey:[object objectID]];

    NSArray *attKeys = [[[object entity] attributesByName] allKeys];
    NSDictionary *attributes = [object dictionaryWithValuesForKeys:attKeys];

    [newObject setValuesForKeysWithDictionary:attributes];

    id oldDestObject = nil;
    id temp = nil;
    NSDictionary *relationships = [[object entity] relationshipsByName];
    for (NSString *key in [relationships allKeys]) {

        NSRelationshipDescription *desc = [relationships valueForKey:key];
        NSString *destEntityName = [[desc destinationEntity] name];
        if ([destEntityName isEqualToString:parentEntity]) continue;

        if (![self isRelationExcluded:entityName destinationEntity:destEntityName]) {
            if ([desc isToMany]) {

                NSMutableSet *newDestSet = [NSMutableSet set];

                for (oldDestObject in [object valueForKey:key]) {
                    temp = [self.collisionDictionary objectForKey:[oldDestObject objectID]];
                    if (!temp) {
                        temp = [self deepCopy:oldDestObject
                                 parentEntity:entityName];
                    }
                    [newDestSet addObject:temp];
                }

                [newObject setValue:newDestSet forKey:key];

            } else {
                oldDestObject = [object valueForKey:key];
                if (!oldDestObject) continue;

                temp = [self.collisionDictionary objectForKey:[oldDestObject objectID]];
                if (!temp && ![destEntityName isEqualToString:parentEntity]) {
                    temp = [self deepCopy:oldDestObject
                             parentEntity:entityName];
                }

                [newObject setValue:temp forKey:key];
            }
        }
    }

    return newObject;
}

-(BOOL)isRelationExcluded:(NSString *)entityName destinationEntity:(NSString *)destEntityName {
    for (NSArray *tuple in self.excludedRelationships) {
        if ([entityName isEqualToString:tuple[0]] && [destEntityName isEqualToString:tuple[1]]) return YES;
    }
    return NO;
}

@end