// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to WZPost.m instead.

#import "_WZPost.h"

const struct WZPostAttributes WZPostAttributes = {
	.commentsCount = @"commentsCount",
	.domain = @"domain",
	.id = @"id",
	.points = @"points",
	.rank = @"rank",
	.timeAgo = @"timeAgo",
	.title = @"title",
	.type = @"type",
	.url = @"url",
	.user = @"user",
};

const struct WZPostRelationships WZPostRelationships = {
	.comments = @"comments",
};

const struct WZPostFetchedProperties WZPostFetchedProperties = {
};

@implementation WZPostID
@end

@implementation _WZPost

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"Post" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"Post";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"Post" inManagedObjectContext:moc_];
}

- (WZPostID*)objectID {
	return (WZPostID*)[super objectID];
}

+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
	
	if ([key isEqualToString:@"commentsCountValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"commentsCount"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
	}
	if ([key isEqualToString:@"idValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"id"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
	}
	if ([key isEqualToString:@"pointsValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"points"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
	}
	if ([key isEqualToString:@"rankValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"rank"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
	}

	return keyPaths;
}




@dynamic commentsCount;



- (int32_t)commentsCountValue {
	NSNumber *result = [self commentsCount];
	return [result intValue];
}

- (void)setCommentsCountValue:(int32_t)value_ {
	[self setCommentsCount:[NSNumber numberWithInt:value_]];
}

- (int32_t)primitiveCommentsCountValue {
	NSNumber *result = [self primitiveCommentsCount];
	return [result intValue];
}

- (void)setPrimitiveCommentsCountValue:(int32_t)value_ {
	[self setPrimitiveCommentsCount:[NSNumber numberWithInt:value_]];
}





@dynamic domain;






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





@dynamic points;



- (int32_t)pointsValue {
	NSNumber *result = [self points];
	return [result intValue];
}

- (void)setPointsValue:(int32_t)value_ {
	[self setPoints:[NSNumber numberWithInt:value_]];
}

- (int32_t)primitivePointsValue {
	NSNumber *result = [self primitivePoints];
	return [result intValue];
}

- (void)setPrimitivePointsValue:(int32_t)value_ {
	[self setPrimitivePoints:[NSNumber numberWithInt:value_]];
}





@dynamic rank;



- (int16_t)rankValue {
	NSNumber *result = [self rank];
	return [result shortValue];
}

- (void)setRankValue:(int16_t)value_ {
	[self setRank:[NSNumber numberWithShort:value_]];
}

- (int16_t)primitiveRankValue {
	NSNumber *result = [self primitiveRank];
	return [result shortValue];
}

- (void)setPrimitiveRankValue:(int16_t)value_ {
	[self setPrimitiveRank:[NSNumber numberWithShort:value_]];
}





@dynamic timeAgo;






@dynamic title;






@dynamic type;






@dynamic url;






@dynamic user;






@dynamic comments;

	
- (NSMutableSet*)commentsSet {
	[self willAccessValueForKey:@"comments"];
  
	NSMutableSet *result = (NSMutableSet*)[self mutableSetValueForKey:@"comments"];
  
	[self didAccessValueForKey:@"comments"];
	return result;
}
	






@end
