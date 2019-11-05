//
//  Created by Jesse Squires
//  http://www.jessesquires.com
//
//
//  Documentation
//  http://cocoadocs.org/docsets/JSQMessagesViewController
//
//
//  GitHub
//  https://github.com/jessesquires/JSQMessagesViewController
//
//
//  License
//  Copyright (c) 2014 Jesse Squires
//  Released under an MIT license: http://opensource.org/licenses/MIT
//

#import "JSQPhotoMediaItem.h"

#import "JSQMessagesMediaPlaceholderView.h"
#import "JSQMessagesMediaViewBubbleImageMasker.h"

#import <CommonCrypto/CommonDigest.h>


@interface JSQPhotoMediaItem ()

@property (strong, nonatomic) UIImageView *cachedImageView;

@end


@implementation JSQPhotoMediaItem

#pragma mark - Initialization

- (instancetype)initWithImage:(UIImage *)image
{
    self = [super init];
    if (self) {
        _image = [image copy];
        _cachedImageView = nil;
    }
    return self;
}

- (void)clearCachedMediaViews
{
    [super clearCachedMediaViews];
    _cachedImageView = nil;
}

#pragma mark - Setters

- (void)setImage:(UIImage *)image
{
    _image = [image copy];
    _cachedImageView = nil;
}

- (void)setAppliesMediaViewMaskAsOutgoing:(BOOL)appliesMediaViewMaskAsOutgoing
{
    [super setAppliesMediaViewMaskAsOutgoing:appliesMediaViewMaskAsOutgoing];
    _cachedImageView = nil;
}

#pragma mark - JSQMessageMediaData protocol

- (UIView *)mediaView
{
    if (self.image == nil) {
        return nil;
    }
    
    if (self.cachedImageView == nil) {
        CGSize size = [self mediaViewDisplaySize];
        UIImageView *imageView = [[UIImageView alloc] initWithImage:self.image];
        imageView.frame = CGRectMake(0.0f, 0.0f, size.width, size.height);
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        imageView.clipsToBounds = YES;
        [JSQMessagesMediaViewBubbleImageMasker applyBubbleImageMaskToMediaView:imageView isOutgoing:self.appliesMediaViewMaskAsOutgoing];
        if ([self thumbCheck:self.image]) {
            self.cachedImageView = imageView;
        }
    }
    
    return self.cachedImageView;
}

- (NSUInteger)mediaHash
{
    return self.hash;
}

#pragma mark - NSObject

- (NSUInteger)hash
{
    return super.hash ^ self.image.hash;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: image=%@, appliesMediaViewMaskAsOutgoing=%@>",
            [self class], self.image, @(self.appliesMediaViewMaskAsOutgoing)];
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        _image = [aDecoder decodeObjectForKey:NSStringFromSelector(@selector(image))];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:self.image forKey:NSStringFromSelector(@selector(image))];
}

#pragma mark - NSCopying

- (instancetype)copyWithZone:(NSZone *)zone
{
    JSQPhotoMediaItem *copy = [[JSQPhotoMediaItem allocWithZone:zone] initWithImage:self.image];
    copy.appliesMediaViewMaskAsOutgoing = self.appliesMediaViewMaskAsOutgoing;
    return copy;
}

#pragma mark - Add Methods
- (BOOL)thumbCheck:(UIImage*)targetImage {
    // データ保存がまだの場合(1回のみ実行)
    NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
    NSData *thumbMd5 = [def dataForKey:@"load_image"];
    if ([thumbMd5 isEqual:[NSNull null]] || thumbMd5 == nil) {
        unsigned char       hash1[16];
        CGDataProviderRef   dataProvider1;
        NSData*             data;
        UIImage *image = [UIImage imageNamed:@"loading_image.png"];
        dataProvider1 = CGImageGetDataProvider(image.CGImage);
        data = (NSData*)CFBridgingRelease(CGDataProviderCopyData(dataProvider1));
        CC_MD5([data bytes], (CC_LONG)[data length], hash1);
        thumbMd5 = [NSData dataWithBytes:hash1 length:sizeof(hash1)];
        [def setObject:thumbMd5 forKey:@"load_image"];
        [def synchronize];
    }
    
    unsigned char       hash2[16];
    CGDataProviderRef   dataProvider2;
    NSData*             data;
    NSData*             data2;
    dataProvider2 = CGImageGetDataProvider(targetImage.CGImage);
    data = (NSData*)CFBridgingRelease(CGDataProviderCopyData(dataProvider2));
    CC_MD5([data bytes], (CC_LONG)[data length], hash2);
    data2 = [NSData dataWithBytes:hash2 length:sizeof(hash2)];
    
    if ([thumbMd5 isEqualToData:data2]) {
        return NO;
    }
    return YES;
}

@end
