//
//  WTVideoTransitionIris.m
//  PiccollageQuiz1
//
//  Created by WeiTing Ruan on 2021/3/31.
//

#import "WTVideoTransitionIris.h"

NSString *const kGPUImageWTIrisBlendFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 varying highp vec2 textureCoordinate2;

 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2;
 
 uniform lowp float radius;
 uniform lowp float ratio;

 void main()
 {
    lowp vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
    lowp vec4 textureColor2 = texture2D(inputImageTexture2, textureCoordinate2);
    lowp vec2 center = vec2(0.5,0.5);
    lowp vec2 p = vec2((textureCoordinate.x - 0.5) * ratio, (textureCoordinate.y - 0.5));
    lowp float dist = length(p);
    if(dist < radius) {
      gl_FragColor = textureColor2;
    }
    else {
      gl_FragColor = textureColor;
    }
 }
);

@interface WTVideoTransitionIris ()
{
    GLuint uniform_ra;
    GLuint uniform_ro;
    CGFloat width;
    CGFloat height;
    float radius;
    float maxRadius;
    float durationFrameCount;
}

@end

@implementation WTVideoTransitionIris

- (instancetype)initWithSize:(CGSize)size duration:(float)duration
{
    self = [super initWithFragmentShaderFromString:kGPUImageWTIrisBlendFragmentShaderString];
    if(self) {
        radius = 0;
        width = size.width;
        height = size.height;
        maxRadius = sqrtf((width / 2.0) * (width / 2.0) + (height / 2.0) * (height / 2.0));
        durationFrameCount = duration;
        uniform_ra = [filterProgram uniformIndex:@"radius"];
        uniform_ro = [filterProgram uniformIndex:@"ratio"];
        [self setFloat:0.0 forUniform:uniform_ra program:filterProgram];
        [self setFloat:(width/height) forUniform:uniform_ro program:filterProgram];
    }
    return self;
}

- (void)newFrameReadyAtTime:(CMTime)frameTime atIndex:(NSInteger)textureIndex
{
    [super newFrameReadyAtTime:frameTime atIndex:textureIndex];
    
    if(radius <= maxRadius) {
        radius = radius + (maxRadius / durationFrameCount);
    } else {
        radius = maxRadius;
    }
    
    [self setFloat:(radius/maxRadius) forUniform:uniform_ra program:filterProgram];
}

@end

