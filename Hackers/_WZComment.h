// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to WZComment.h instead.

#import <CoreData/CoreData.h>


extern const struct WZCommentAttributes {
	__unsafe_unretained NSString *content;
	__unsafe_unretained NSString *id;
	__unsafe_unretained NSString *level;
	__unsafe_unretained NSString *timeAgo;
	__unsafe_unretained NSString *user;
} WZCommentAttributes;

extern const struct WZCommentRelationships {
	__unsafe_unretained NSString *children;
	__unsafe_unretained NSString *parent;
	__unsafe_unretained NSString *post;
} WZCommentRelationships;

extern const struct WZCommentFetchedProperties {
} WZCommentFetchedProperties;

@class WZComment;
@class WZComment;
@class WZPost;







@interface WZCommentID : NSManagedObjectID {}
@end

@interface _WZComment : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (WZCommentID*)objectID;




@property (nonatomic, strong) NSString* content;


//- (BOOL)validateContent:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSNumber* id;


@property int64_t idValue;
- (int64_t)idValue;
- (void)setIdValue:(int64_t)value_;

//- (BOOL)validateId:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSNumber* level;


@property int32_t levelValue;
- (int32_t)levelValue;
- (void)setLevelValue:(int32_t)value_;

//- (BOOL)validateLevel:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSString* timeAgo;


//- (BOOL)validateTimeAgo:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSString* user;


//- (BOOL)validateUser:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSSet* children;

- (NSMutableSet*)childrenSet;




@property (nonatomic, strong) WZComment* parent;

//- (BOOL)validateParent:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) WZPost* post;

//- (BOOL)validatePost:(id*)value_ error:(NSError**)error_;





@end

@interface _WZComment (CoreDataGeneratedAccessors)

- (void)addChildren:(NSSet*)value_;
- (void)removeChildren:(NSSet*)value_;
- (void)addChildrenObject:(WZComment*)value_;
- (void)removeChildrenObject:(WZComment*)value_;

@end

@interface _WZComment (CoreDataGeneratedPrimitiveAccessors)


- (NSString*)primitiveContent;
- (void)setPrimitiveContent:(NSString*)value;




- (NSNumber*)primitiveId;
- (void)setPrimitiveId:(NSNumber*)value;

- (int64_t)primitiveIdValue;
- (void)setPrimitiveIdValue:(int64_t)value_;




- (NSNumber*)primitiveLevel;
- (void)setPrimitiveLevel:(NSNumber*)value;

- (int32_t)primitiveLevelValue;
- (void)setPrimitiveLevelValue:(int32_t)value_;




- (NSString*)primitiveTimeAgo;
- (void)setPrimitiveTimeAgo:(NSString*)value;




- (NSString*)primitiveUser;
- (void)setPrimitiveUser:(NSString*)value;





- (NSMutableSet*)primitiveChildren;
- (void)setPrimitiveChildren:(NSMutableSet*)value;



- (WZComment*)primitiveParent;
- (void)setPrimitiveParent:(WZComment*)value;



- (WZPost*)primitivePost;
- (void)setPrimitivePost:(WZPost*)value;


@end
