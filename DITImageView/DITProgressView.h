/*
 * DITProgressView.h
 */


#import <UIKit/UIKit.h>

@interface DITProgressView : UIView {
}

@property (nonatomic, strong) UIColor *innerColor ;
@property (nonatomic, strong) UIColor *outerColor ;
@property (nonatomic, strong) UIColor *emptyColor ;
@property (nonatomic)         float   progress ;

@end
