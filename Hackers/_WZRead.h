// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to WZRead.h instead.

#import <CoreData/CoreData.h>


extern const struct WZReadAttributes {
	__unsafe_unretained NSString *id;
} WZReadAttributes;

extern const struct WZReadRelationships {
} WZReadRelationships;

extern const struct WZReadFetchedProperties {
} WZReadFetchedProperties;




@interface WZReadID : NSManagedObjectID {}
@end

@interface _WZRead : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (WZReadID*)objectID;




@property (nonatomic, strong) NSNumber* id;


@property int64_t idValue;
- (int64_t)idValue;
- (void)setIdValue:(int64_t)value_;

//- (BOOL)validateId:(id*)value_ error:(NSError**)error_;






@end

@interface _WZRead (CoreDataGeneratedAccessors)

@end

@interface _WZRead (CoreDataGeneratedPrimitiveAccessors)


- (NSNumber*)primitiveId;
- (void)setPrimitiveId:(NSNumber*)value;

- (int64_t)primitiveIdValue;
- (void)setPrimitiveIdValue:(int64_t)value_;




@end
