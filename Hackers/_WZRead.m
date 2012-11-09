// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to WZRead.m instead.

#import "_WZRead.h"

const struct WZReadAttributes WZReadAttributes = {
	.id = @"id",
};

const struct WZReadRelationships WZReadRelationships = {
};

const struct WZReadFetchedProperties WZReadFetchedProperties = {
};

@implementation WZReadID
@end

@implementation _WZRead

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"Read" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"Read";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"Read" inManagedObjectContext:moc_];
}

- (WZReadID*)objectID {
	return (WZReadID*)[super objectID];
}

+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
	
	if ([key isEqualToString:@"idValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"id"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
	}

	return keyPaths;
}




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










@end
