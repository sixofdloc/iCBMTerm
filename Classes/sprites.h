#import <UIKit/UIKit.h>
#import "OpenGLCommon.h"

int LoadTexture(NSString *pathToFile, int spriteWidth, int spriteHeight);
void DrawImage(int spriteHandle, int x, int y, int frame);
void DrawImageColor(int spriteHandle, int x, int y,  int frame, GLfloat r, GLfloat g, GLfloat b);
void DeleteTextures();

@interface SpriteDefinition : NSObject {
@public
	unsigned int textureId;
	int numColumns;
	int numRows;
	int spriteWidth;
	int spriteHeight;
	GLfloat textureWidth;
	GLfloat textureHeight;
}
@end