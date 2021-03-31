//
//  WTVideoTransitionIris.h
//  PiccollageQuiz1
//
//  Created by WeiTing Ruan on 2021/3/31.
//

#import <Foundation/Foundation.h>
#import <GPUImage/GPUImageTwoInputFilter.h>

@interface WTVideoTransitionIrisFilter : GPUImageTwoInputFilter

- (instancetype)initWithSize:(CGSize)size duration:(float)duration;

@end
