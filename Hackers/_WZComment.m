// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to WZComment.m instead.

#import "_WZComment.h"

const struct WZCommentAttributes WZCommentAttributes = {
	.content = @"content",
	.id = @"id",
	.level = @"level",
	.timeAgo = @"timeAgo",
	.user = @"user",
};

const struct WZCommentRelationships WZCommentRelationships = {
	.children = @"children",
	.parent = @"parent",
	.post = @"post",
};

const struct WZCommentFetchedProperties WZCommentFetchedProperties = {
};

@implementation WZCommentID
@end

@implementation _WZComment

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"Comment" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"Comment";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"Comment" inManagedObjectContext:moc_];
}

- (WZCommentID*)objectID {
	return (WZCommentID*)[super objectID];
}

+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
	
	if ([key isEqualToString:@"idValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"id"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
	}
	if ([key isEqualToString:@"levelValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"level"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
	}

	return keyPaths;
}




@dynamic content;






@dynamic id;



- (int64_t)idValue {
	NSNumber *result = [self id];
	return [result longLongValue];
}

- (void)setIdValue:(int64_t)value_ {
	[self setId:[NSNumber numberWithLongLong:value_]];
}

- (int64_t)primitiveIdValue {
	NSNumber *result = [self primitiveId];
	return [result longLongValue];
}

- (void)setPrimitiveIdValue:(int64_t)value_ {
	[self setPrimitiveId:[NSNumber numberWithLongLong:value_]];
}





@dynamic level;



- (int32_t)levelValue {
	NSNumber *result = [self level];
	return [result intValue];
}

- (void)setLevelValue:(int32_t)value_ {
	[self setLevel:[NSNumber numberWithInt:value_]];
}

- (int32_t)primitiveLevelValue {
	NSNumber *result = [self primitiveLevel];
	return [result intValue];
}

- (void)setPrimitiveLevelValue:(int32_t)value_ {
	[self setPrimitiveLevel:[NSNumber numberWithInt:value_]];
}





@dynamic timeAgo;






@dynamic user;






@dynamic children;

	
- (NSMutableSet*)childrenSet {
	[self willAccessValueForKey:@"children"];
  
	NSMutableSet *result = (NSMutableSet*)[self mutableSetValueForKey:@"children"];
  
	[self didAccessValueForKey:@"children"];
	return result;
}
	

@dynamic parent;

	

@dynamic post;

	






@end
