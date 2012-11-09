// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to WZPost.h instead.

#import <CoreData/CoreData.h>


extern const struct WZPostAttributes {
	__unsafe_unretained NSString *commentsCount;
	__unsafe_unretained NSString *domain;
	__unsafe_unretained NSString *id;
	__unsafe_unretained NSString *points;
	__unsafe_unretained NSString *rank;
	__unsafe_unretained NSString *timeAgo;
	__unsafe_unretained NSString *title;
	__unsafe_unretained NSString *type;
	__unsafe_unretained NSString *url;
	__unsafe_unretained NSString *user;
} WZPostAttributes;

extern const struct WZPostRelationships {
	__unsafe_unretained NSString *comments;
} WZPostRelationships;

extern const struct WZPostFetchedProperties {
} WZPostFetchedProperties;

@class WZComment;












@interface WZPostID : NSManagedObjectID {}
@end

@interface _WZPost : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (WZPostID*)objectID;




@property (nonatomic, strong) NSNumber* commentsCount;


@property int32_t commentsCountValue;
- (int32_t)commentsCountValue;
- (void)setCommentsCountValue:(int32_t)value_;

//- (BOOL)validateCommentsCount:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSString* domain;


//- (BOOL)validateDomain:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSNumber* id;


@property int64_t idValue;
- (int64_t)idValue;
- (void)setIdValue:(int64_t)value_;

//- (BOOL)validateId:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSNumber* points;


@property int32_t pointsValue;
- (int32_t)pointsValue;
- (void)setPointsValue:(int32_t)value_;

//- (BOOL)validatePoints:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSNumber* rank;


@property int16_t rankValue;
- (int16_t)rankValue;
- (void)setRankValue:(int16_t)value_;

//- (BOOL)validateRank:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSString* timeAgo;


//- (BOOL)validateTimeAgo:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSString* title;


//- (BOOL)validateTitle:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSString* type;


//- (BOOL)validateType:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSString* url;


//- (BOOL)validateUrl:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSString* user;


//- (BOOL)validateUser:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSSet* comments;

- (NSMutableSet*)commentsSet;





@end

@interface _WZPost (CoreDataGeneratedAccessors)

- (void)addComments:(NSSet*)value_;
- (void)removeComments:(NSSet*)value_;
- (void)addCommentsObject:(WZComment*)value_;
- (void)removeCommentsObject:(WZComment*)value_;

@end

@interface _WZPost (CoreDataGeneratedPrimitiveAccessors)


- (NSNumber*)primitiveCommentsCount;
- (void)setPrimitiveCommentsCount:(NSNumber*)value;

- (int32_t)primitiveCommentsCountValue;
- (void)setPrimitiveCommentsCountValue:(int32_t)value_;




- (NSString*)primitiveDomain;
- (void)setPrimitiveDomain:(NSString*)value;




- (NSNumber*)primitiveId;
- (void)setPrimitiveId:(NSNumber*)value;

- (int64_t)primitiveIdValue;
- (void)setPrimitiveIdValue:(int64_t)value_;




- (NSNumber*)primitivePoints;
- (void)setPrimitivePoints:(NSNumber*)value;

- (int32_t)primitivePointsValue;
- (void)setPrimitivePointsValue:(int32_t)value_;




- (NSNumber*)primitiveRank;
- (void)setPrimitiveRank:(NSNumber*)value;

- (int16_t)primitiveRankValue;
- (void)setPrimitiveRankValue:(int16_t)value_;




- (NSString*)primitiveTimeAgo;
- (void)setPrimitiveTimeAgo:(NSString*)value;




- (NSString*)primitiveTitle;
- (void)setPrimitiveTitle:(NSString*)value;




- (NSString*)primitiveType;
- (void)setPrimitiveType:(NSString*)value;




- (NSString*)primitiveUrl;
- (void)setPrimitiveUrl:(NSString*)value;




- (NSString*)primitiveUser;
- (void)setPrimitiveUser:(NSString*)value;





- (NSMutableSet*)primitiveComments;
- (void)setPrimitiveComments:(NSMutableSet*)value;


@end
