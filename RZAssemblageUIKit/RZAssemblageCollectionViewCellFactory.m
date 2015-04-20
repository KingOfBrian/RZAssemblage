//
//  RZAssemblageCollectionViewCellFactory.m
//  RZTree
//
//  Created by Brian King on 3/19/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZAssemblageCollectionViewCellFactory.h"

@interface RZAssemblageCollectionViewCellFactory ()

@property (strong, nonatomic, readonly) NSMutableDictionary *classToReuseIdentifier;
@property (strong, nonatomic, readonly) NSMutableDictionary *reuseIdentifierToBlock;

@end

@implementation RZAssemblageCollectionViewCellFactory

- (instancetype)init
{
    self = [super init];
    if ( self ) {
        _classToReuseIdentifier = [NSMutableDictionary dictionary];
        _reuseIdentifierToBlock = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)configureCellForClass:(Class)objectClass reuseIdentifier:(NSString *)reuseIdentifier block:(RZCollectionViewCellFactoryBlock)block;
{
    NSParameterAssert(objectClass);
    NSParameterAssert(reuseIdentifier);
    NSParameterAssert(block);
    NSAssert(self.classToReuseIdentifier[NSStringFromClass(objectClass)] == nil, @"Class is already configured");
    NSAssert(self.reuseIdentifierToBlock[reuseIdentifier] == nil, @"Reuse identifier is already configured");
    self.classToReuseIdentifier[NSStringFromClass(objectClass)] = reuseIdentifier;
    self.reuseIdentifierToBlock[reuseIdentifier] = [block copy];
}

- (void)configureReusableViewForClass:(Class)objectClass kind:(NSString *)kind reuseIdentifier:(NSString *)reuseIdentifier block:(RZCollectionViewReusableViewFactoryBlock)block
{
    NSParameterAssert(objectClass);
    NSParameterAssert(reuseIdentifier);
    NSParameterAssert(block);
    NSAssert(self.classToReuseIdentifier[NSStringFromClass(objectClass)] == nil, @"Class is already configured");
    NSAssert(self.reuseIdentifierToBlock[reuseIdentifier] == nil, @"Reuse identifier is already configured");
    self.classToReuseIdentifier[NSStringFromClass(objectClass)] = reuseIdentifier;
    self.reuseIdentifierToBlock[[reuseIdentifier stringByAppendingString:kind]] = [block copy];
}

- (NSString *)reuseIdentifierForObject:(id)object
{
    __block NSString *identifier = nil;
    [self.classToReuseIdentifier enumerateKeysAndObjectsUsingBlock:^(NSString *classname, NSString *reuseIdentifier, BOOL *stop) {
        if ( [object isKindOfClass:NSClassFromString(classname)] ) {
            identifier = reuseIdentifier;
            *stop = YES;
        }
    }];
    return identifier;
}


- (UICollectionViewCell *)cellForObject:(id)object
                            atIndexPath:(NSIndexPath *)indexPath
                     fromCollectionView:(UICollectionView *)collectionView
{
    NSParameterAssert(object);
    NSParameterAssert(indexPath);
    NSParameterAssert(collectionView);

    NSString *identifier = [self reuseIdentifierForObject:object];
    NSAssert(identifier != nil, @"Unable to find re-use identifer for %@", object);
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:indexPath];
    RZCollectionViewCellFactoryBlock configureBlock = self.reuseIdentifierToBlock[identifier];
    configureBlock(cell, object, indexPath);
    return cell;
}

- (UICollectionReusableView *)reusableViewOfKind:(NSString *)kind
                                       forObject:(id)object
                                     atIndexPath:(NSIndexPath *)indexPath
                              fromCollectionView:(UICollectionView *)collectionView;
{
    NSParameterAssert(kind);
    NSParameterAssert(object);
    NSParameterAssert(indexPath);
    NSParameterAssert(collectionView);

    NSString *identifier = [self reuseIdentifierForObject:object];
    UICollectionReusableView *reusableView = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:identifier forIndexPath:indexPath];
    NSAssert(reusableView != nil, @"Reuse Identifier '%@' is not registered with tableview", identifier);
    RZCollectionViewReusableViewFactoryBlock configureBlock = self.reuseIdentifierToBlock[[identifier stringByAppendingString:kind]];
    configureBlock(reusableView, object);
    return reusableView;
}

@end
