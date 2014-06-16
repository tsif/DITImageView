/*
 * DITImageView.h
 */


#import <Foundation/Foundation.h>

@interface DITImageView : UIView {
    
}

@property(nonatomic, strong) NSString *url;
@property(nonatomic)         BOOL     ignoreCache;
@property(nonatomic)         BOOL     customProgress;
@property(nonatomic, strong) NSString *defaultImage;

- (UIImage*)getImage;

@end
