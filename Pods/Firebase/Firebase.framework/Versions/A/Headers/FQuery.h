/*
 * Firebase iOS Client Library
 *
 * Copyright © 2013 Firebase - All Rights Reserved
 * https://www.firebase.com
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice, this
 * list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binaryform must reproduce the above copyright notice,
 * this list of conditions and the following disclaimer in the documentation
 * and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY FIREBASE AS IS AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
 * EVENT SHALL FIREBASE BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
 * OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import <Foundation/Foundation.h>
#import "FEventType.h"
#import "FDataSnapshot.h"

typedef NSUInteger FirebaseHandle;

/**
 * An FQuery instance represents a query over the data at a particular location.
 * 
 * You create one by calling one of the query methods (queryStartingAtPriority:, queryEndingAtPriority:, etc.) 
 * on a Firebase reference. The query methods can be chained to further specify the data you are interested in 
 * observing
 */
@interface FQuery : NSObject


/** @name Attaching observers to read data */


/**
 * observeEventType:withBlock: is used to listen for data changes at a particular location.
 * This is the primary way to read data from Firebase. Your block will be triggered
 * for the initial data and again whenever the data changes.
 *
 * Use removeObserverWithHandle: to stop receiving updates.
 *
 * @param eventType The type of event to listen for.
 * @param block The block that should be called with initial data and updates.
 * @return A handle used to unregister this block later using removeObserverWithHandle:
 */
- (FirebaseHandle) observeEventType:(FEventType)eventType withBlock:(void (^)(FDataSnapshot* snapshot))block;


/**
 * observeEventType:andPreviousSiblingWithBlock: is used to listen for data changes at a particular location.
 * This is the primary way to read data from Firebase. Your block will be triggered
 * for the initial data and again whenever the data changes. In addition, for FEventTypeChildAdded, FEventTypeChildMoved, and
 * FEventTypeChildChanged events, your block will be passed the name of the previous node by priority order.
 *
 * Use removeObserverWithHandle: to stop receiving updates.
 *
 * @param eventType The type of event to listen for.
 * @param block The block that should be called with initial data and updates, as well as the previous child's name.
 * @return A handle used to unregister this block later using removeObserverWithHandle:
 */
- (FirebaseHandle) observeEventType:(FEventType)eventType andPreviousSiblingNameWithBlock:(void (^)(FDataSnapshot* snapshot, NSString* prevName))block;


/**
 * observeEventType:withBlock: is used to listen for data changes at a particular location.
 * This is the primary way to read data from Firebase. Your block will be triggered
 * for the initial data and again whenever the data changes.
 *
 * The cancelBlock will be called if you will no longer receive new events due to no longer having permission.
 *
 * Use removeObserverWithHandle: to stop receiving updates.
 *
 * @param eventType The type of event to listen for.
 * @param block The block that should be called with initial data and updates.
 * @param cancelBlock The block that should be called if this client no longer has permission to receive these events
 * @return A handle used to unregister this block later using removeObserverWithHandle:
 */
- (FirebaseHandle) observeEventType:(FEventType)eventType withBlock:(void (^)(FDataSnapshot* snapshot))block withCancelBlock:(void (^)(NSError* error))cancelBlock;


/**
 * observeEventType:andPreviousSiblingWithBlock: is used to listen for data changes at a particular location.
 * This is the primary way to read data from Firebase. Your block will be triggered
 * for the initial data and again whenever the data changes. In addition, for FEventTypeChildAdded, FEventTypeChildMoved, and
 * FEventTypeChildChanged events, your block will be passed the name of the previous node by priority order.
 *
 * The cancelBlock will be called if you will no longer receive new events due to no longer having permission.
 *
 * Use removeObserverWithHandle: to stop receiving updates.
 *
 * @param eventType The type of event to listen for.
 * @param block The block that should be called with initial data and updates, as well as the previous child's name.
 * @param cancelBlock The block that should be called if this client no longer has permission to receive these events
 * @return A handle used to unregister this block later using removeObserverWithHandle:
 */
- (FirebaseHandle) observeEventType:(FEventType)eventType andPreviousSiblingNameWithBlock:(void (^)(FDataSnapshot* snapshot, NSString* prevName))block withCancelBlock:(void (^)(NSError* error))cancelBlock;


/**
 * This is equivalent to observeEventType:withBlock:, except the block is immediately canceled after the initial data is returned.
 *
 * @param eventType The type of event to listen for.
 * @param block The block that should be called with initial data and updates.
 */
- (void) observeSingleEventOfType:(FEventType)eventType withBlock:(void (^)(FDataSnapshot* snapshot))block;


/**
 * This is equivalent to observeEventType:withBlock:, except the block is immediately canceled after the initial data is returned. In addition, for FEventTypeChildAdded, FEventTypeChildMoved, and
 * FEventTypeChildChanged events, your block will be passed the name of the previous node by priority order.
 *
 * @param eventType The type of event to listen for.
 * @param block The block that should be called with initial data and updates.
 */
- (void) observeSingleEventOfType:(FEventType)eventType andPreviousSiblingNameWithBlock:(void (^)(FDataSnapshot* snapshot, NSString* prevName))block;


/**
 * This is equivalent to observeEventType:withBlock:, except the block is immediately canceled after the initial data is returned.
 *
 * The cancelBlock will be called if you do not have permission to read data at this location.
 *
 * @param eventType The type of event to listen for.
 * @param block The block that should be called with initial data and updates.
 * @param cancelBlock The block that will be called if you don't have permission to access this data
 */
- (void) observeSingleEventOfType:(FEventType)eventType withBlock:(void (^)(FDataSnapshot* snapshot))block withCancelBlock:(void (^)(NSError* error))cancelBlock;


/**
 * This is equivalent to observeEventType:withBlock:, except the block is immediately canceled after the initial data is returned. In addition, for FEventTypeChildAdded, FEventTypeChildMoved, and
 * FEventTypeChildChanged events, your block will be passed the name of the previous node by priority order.
 *
 * The cancelBlock will be called if you do not have permission to read data at this location.
 *
 * @param eventType The type of event to listen for.
 * @param block The block that should be called with initial data and updates.
 * @param cancelBlock The block that will be called if you don't have permission to access this data
 */
- (void) observeSingleEventOfType:(FEventType)eventType andPreviousSiblingNameWithBlock:(void (^)(FDataSnapshot* snapshot, NSString* prevName))block withCancelBlock:(void (^)(NSError* error))cancelBlock;

/** @name Detaching observers */

/**
 * Detach a block previously attached with observeEventType:withBlock:.
 *
 * @param handle The handle returned by the call to observeEventType:withBlock: which we are trying to remove.
 */
- (void) removeObserverWithHandle:(FirebaseHandle)handle;


/**
 * Detach all blocks previously attached to this Firebase location with observeEventType:withBlock:
 */
- (void) removeAllObservers;


/** @name Querying and limiting */


/**
 * queryStartingAtPriority: is used to generate a reference to a limited view of the data at this location.
 * The FQuery instance returned by queryStartingAtPriority: will respond to events at nodes with a priority
 * greater than or equal to startPriority
 *
 * @param startPriority The lower bound, inclusive, for the priority of data visible to the returned FQuery
 * @return An FQuery instance, limited to data with priority greater than or equal to startPriority
 */
- (FQuery *) queryStartingAtPriority:(id)startPriority;


/**
 * queryStartingAtPriority:andChildName: is used to generate a reference to a limited view of the data at this location.
 * The FQuery instance returned by queryStartingAtPriority:andChildName will respond to events at nodes with a priority
 * greater than startPriority, or equal to startPriority and with a name greater than or equal to childName
 *
 * @param startPriority The lower bound, inclusive, for the priority of data visible to the returned FQuery
 * @param childName The lower bound, inclusive, for the name of nodes with priority equal to startPriority
 * @return An FQuery instance, limited to data with priority greater than or equal to startPriority
 */
- (FQuery *) queryStartingAtPriority:(id)startPriority andChildName:(NSString *)childName;


/**
 * queryEndingAtPriority: is used to generate a reference to a limited view of the data at this location.
 * The FQuery instance returned by queryEndingAtPriority: will respond to events at nodes with a priority
 * less than or equal to startPriority and with a name greater than or equal to childName
 *
 * @param endPriority The upper bound, inclusive, for the priority of data visible to the returned FQuery
 * @return An FQuery instance, limited to data with priority less than or equal to endPriority
 */
- (FQuery *) queryEndingAtPriority:(id)endPriority;


/**
 * queryEndingAtPriority:andChildName: is used to generate a reference to a limited view of the data at this location.
 * The FQuery instance returned by queryEndingAtPriority:andChildNAme will respond to events at nodes with a priority
 * less than endPriority, or equal to endPriority and with a name less than or equal to childName
 *
 * @param endPriority The upper bound, inclusive, for the priority of data visible to the returned FQuery
 * @param childName The upper bound, inclusive, for the name of nodes with priority equal to endPriority
 * @return An FQuery instance, limited to data with priority less than endPriority or equal to endPriority and with a name less than or equal to childName
 */
- (FQuery *) queryEndingAtPriority:(id)endPriority andChildName:(NSString *)childName;


/**
* queryEqualToPriority: is used to generate a reference to a limited view of the data at this location.
* The FQuery instance returned by queryEqualToPriority: will respond to events at nodes with a priority equal to
* supplied argument.
*
* @param priority The priority that the data returned by this FQuery will have
* @return An Fquery instance, limited to data with the supplied priority.
*/
- (FQuery *) queryEqualToPriority:(id)priority;


/**
* queryEqualToPriority:andChildName: is used to generate a reference to a limited view of the data at this location.
* The FQuery instance returned by queryEqualToPriority:andChildNAme will respond to events at nodes with a priority
* equal to the supplied argument with a name equal to childName. There will be at most one node that matches because
* child names are unique.
*
* @param priority The priority that the data returned by this FQuery will have
* @param childName The name of nodes with the right priority
* @return An FQuery instance, limited to data with the supplied priority and the name.
*/
- (FQuery *) queryEqualToPriority:(id)priority andChildName:(NSString *)childName;


/**
 * queryLimitedToNumberOfChildren: is used to generate a reference to a limited view of the data at this location.
 * The FQuery instance returned by queryLimitedToNumberOfChildren: will respond to events at from at most limit child nodes
 *
 * @param limit The upper bound, inclusive, for the number of child nodes to receive events for
 * @return An FQuery instance, limited to at most limit child nodes.
 */
- (FQuery *) queryLimitedToNumberOfChildren:(NSUInteger)limit;

@end
