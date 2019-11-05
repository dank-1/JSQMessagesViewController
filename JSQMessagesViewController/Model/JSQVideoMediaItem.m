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

#import "JSQVideoMediaItem.h"

#import "JSQMessagesMediaPlaceholderView.h"
#import "JSQMessagesMediaViewBubbleImageMasker.h"

#import "UIImage+JSQMessages.h"

#import <CommonCrypto/CommonDigest.h>


@interface JSQVideoMediaItem ()

@property (strong, nonatomic) UIImageView *cachedVideoImageView;

@end


@implementation JSQVideoMediaItem

#pragma mark - Initialization

- (instancetype)initWithFileURL:(NSURL *)fileURL isReadyToPlay:(BOOL)isReadyToPlay
{
    self = [super init];
    if (self) {
        _fileURL = [fileURL copy];
        _isReadyToPlay = isReadyToPlay;
        _cachedVideoImageView = nil;
    }
    return self;
}

- (instancetype)initWithThumbnail:(UIImage *)thumbnail isReadyToPlay:(BOOL)isReadyToPlay
{
    self = [super init];
    if (self) {
        _thumbnail = thumbnail;
        _isReadyToPlay = isReadyToPlay;
        _cachedVideoImageView = nil;
    }
    return self;
}

- (void)clearCachedMediaViews
{
    [super clearCachedMediaViews];
    _cachedVideoImageView = nil;
}

#pragma mark - Setters

- (void)setFileURL:(NSURL *)fileURL
{
    _fileURL = [fileURL copy];
    _cachedVideoImageView = nil;
}

- (void)setIsReadyToPlay:(BOOL)isReadyToPlay
{
    _isReadyToPlay = isReadyToPlay;
    _cachedVideoImageView = nil;
}

- (void)setAppliesMediaViewMaskAsOutgoing:(BOOL)appliesMediaViewMaskAsOutgoing
{
    [super setAppliesMediaViewMaskAsOutgoing:appliesMediaViewMaskAsOutgoing];
    _cachedVideoImageView = nil;
}

#pragma mark - JSQMessageMediaData protocol

- (UIView *)mediaView
{
//    if (self.fileURL == nil || !self.isReadyToPlay) {
//        return nil;
//    }
    if (!self.isReadyToPlay) {
        return nil;
    }
    
    if (self.cachedVideoImageView == nil) {
        CGSize size = [self mediaViewDisplaySize];
        UIImage *playIcon = [[UIImage jsq_defaultPlayImage] jsq_imageMaskedWithColor:[UIColor lightGrayColor]];
        
        UIImageView *imageView = [[UIImageView alloc] initWithImage:_thumbnail];
        imageView.backgroundColor = [UIColor blackColor];
        imageView.frame = CGRectMake(0.0f, 0.0f, size.width, size.height);
        imageView.contentMode = UIViewContentModeCenter;
        imageView.clipsToBounds = YES;
        
        UIImageView *iconView = [[UIImageView alloc] initWithImage:playIcon];
        iconView.backgroundColor = [UIColor clearColor];
        iconView.frame = CGRectMake(0.0f, 0.0f, size.width, size.height);
        iconView.contentMode = UIViewContentModeCenter;
        iconView.clipsToBounds = YES;
        
        [imageView addSubview:iconView];
        [JSQMessagesMediaViewBubbleImageMasker applyBubbleImageMaskToMediaView:imageView isOutgoing:self.appliesMediaViewMaskAsOutgoing];
        if ([self thumbCheck:_thumbnail]) {
            self.cachedVideoImageView = imageView;
        }
    }
    
    return self.cachedVideoImageView;
}

- (NSUInteger)mediaHash
{
    return self.hash;
}

#pragma mark - NSObject

- (BOOL)isEqual:(id)object
{
    if (![super isEqual:object]) {
        return NO;
    }
    
    JSQVideoMediaItem *videoItem = (JSQVideoMediaItem *)object;
    
    return [self.fileURL isEqual:videoItem.fileURL]
            && self.isReadyToPlay == videoItem.isReadyToPlay;
}

- (NSUInteger)hash
{
    return super.hash ^ self.fileURL.hash;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: fileURL=%@, isReadyToPlay=%@, appliesMediaViewMaskAsOutgoing=%@>",
            [self class], self.fileURL, @(self.isReadyToPlay), @(self.appliesMediaViewMaskAsOutgoing)];
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        _fileURL = [aDecoder decodeObjectForKey:NSStringFromSelector(@selector(fileURL))];
        _isReadyToPlay = [aDecoder decodeBoolForKey:NSStringFromSelector(@selector(isReadyToPlay))];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:self.fileURL forKey:NSStringFromSelector(@selector(fileURL))];
    [aCoder encodeBool:self.isReadyToPlay forKey:NSStringFromSelector(@selector(isReadyToPlay))];
}

#pragma mark - NSCopying

- (instancetype)copyWithZone:(NSZone *)zone
{
    JSQVideoMediaItem *copy = [[[self class] allocWithZone:zone] initWithFileURL:self.fileURL
                                                                   isReadyToPlay:self.isReadyToPlay];
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
