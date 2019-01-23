#import "sprites.h"
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>

@implementation SpriteDefinition
@end

NSMutableArray *spriteArray = 0;

void DeleteTextures()
{
	if(0!=spriteArray) {
		NSEnumerator * enumerator = [spriteArray objectEnumerator];
		SpriteDefinition *element;

		while(element = [enumerator nextObject])
		{
			glDeleteTextures (1, &(element->textureId));
		}

		// Delete the array
		[spriteArray removeAllObjects];
		[spriteArray release];
	}
}

int LoadTexture(NSString *pathToFile, int spriteWidth, int spriteHeight)
{
	if(0==spriteArray) {
		// Create the array
		spriteArray = [[NSMutableArray array] retain];
	}
	// Create a SpriteDefinition
	SpriteDefinition *sd = [[SpriteDefinition alloc] init];
	sd->spriteWidth = spriteWidth;
	sd->spriteHeight = spriteHeight;
	// Bind the number of textures we need, in this case one.
	glGenTextures(1, &sd->textureId);
	glBindTexture(GL_TEXTURE_2D, sd->textureId);

	NSData *texData = [[NSData alloc] initWithContentsOfFile:pathToFile];
	UIImage *image = [[UIImage alloc] initWithData:texData];

	// TODO: Do real error checking here
	if (image == nil)
		NSLog(@"Do real error checking here");

 	GLuint width = CGImageGetWidth(image.CGImage);
	GLuint height = CGImageGetHeight(image.CGImage);

	// keep track of the animation frames
	sd->numColumns = width / spriteWidth;
	sd->numRows = height / spriteHeight;
	sd->textureWidth = width;
	sd->textureHeight = height;

	void *imageData = malloc( height * width * 4 );
	CGContextRef context = CGBitmapContextCreate( imageData, width, height, 8, 4 * width, CGImageGetColorSpace(image.CGImage),kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big );

	// Flip the Y-axis
	CGContextTranslateCTM (context, 0, height);
	CGContextScaleCTM (context, 1.0, -1.0);

	CGContextDrawImage( context, CGRectMake( 0, 0, width, height ), image.CGImage );
	CGContextRelease(context);

	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, imageData);
	free(imageData);

	glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);
	glEnable(GL_TEXTURE_2D); // Enable Textures

	[image release];
	[texData release];

	// Add the SpriteDefinition to our list and return it's index (our handle)
	[spriteArray addObject:sd];
	[sd release];
	return [spriteArray count] - 1;
}



void DrawImageRoot(
	int spriteHandle, int x, int y,  int frame, GLfloat r, GLfloat g, GLfloat b
	)
{
	// fetch our sprite definition
	SpriteDefinition *sd = [spriteArray objectAtIndex:spriteHandle];

	glEnableClientState(GL_VERTEX_ARRAY);
	glEnableClientState(GL_NORMAL_ARRAY);
	glEnableClientState(GL_TEXTURE_COORD_ARRAY);
	glEnableClientState(GL_COLOR_ARRAY);

	glPushMatrix();
	glLoadIdentity();
	glTranslatef(x, y, 1);


	Vertex3D vertices[] = {
		{0,  sd->spriteHeight, 0},
		{sd->spriteWidth,  sd->spriteHeight, 0},
		{0,  0,  0},
		{sd->spriteWidth,  0,  0}
	};

	static const Vector3D normals[] = {
		{0.0, 0.0, 1.0},
		{0.0, 0.0, 1.0},
		{0.0, 0.0, 1.0},
		{0.0, 0.0, 1.0}
	};

	static GLfloat color[] = {
		1, 1, 1, 1.0,
		1, 1, 1, 1.0,
		1, 1, 1, 1.0,
		1, 1, 1, 1.0
	};
	color[0] = r;
	color[4] = r;
	color[8] = r;
	color[12] = r;
	color[1] = g;
	color[5] = g;
	color[9] = g;
	color[13] = g;
	color[2] = b;
	color[6] = b;
	color[10] = b;
	color[14] =b;

	int xFrame = frame % sd->numColumns;
	int yFrame = frame / sd->numColumns;

	GLfloat x1 = (sd->spriteWidth / sd->textureWidth) * xFrame;
	GLfloat y1 = 1.0 - ((sd->spriteHeight / sd->textureHeight) * yFrame);
	GLfloat x2 = (sd->spriteWidth / sd->textureWidth) * (xFrame + 1);
	GLfloat y2 = 1.0 - ((sd->spriteHeight / sd->textureHeight) * (yFrame + 1));

	GLfloat texCoords[] = {
		x1, y2,
		x2, y2,
		x1, y1,
		x2, y1
	};

	glBindTexture(GL_TEXTURE_2D, sd->textureId);
	glVertexPointer(3, GL_FLOAT, 0, vertices);
	glNormalPointer(GL_FLOAT, 0, normals);
	glTexCoordPointer(2, GL_FLOAT, 0, texCoords);
	glColorPointer(4, GL_FLOAT, 0,color);
	glEnable(GL_TEXTURE_2D);
	glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
	glEnable(GL_BLEND);
	glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);

	glPopMatrix();

	glDisableClientState(GL_VERTEX_ARRAY);
	glDisableClientState(GL_NORMAL_ARRAY);
	glDisableClientState(GL_TEXTURE_COORD_ARRAY);
	glDisableClientState(GL_COLOR_ARRAY);
}
void DrawImage(int spriteHandle, int x, int y, int frame)
{
	DrawImageRoot(spriteHandle,x,y,frame,1,1,1);
}
void DrawImageColor(int spriteHandle, int x, int y,  int frame,GLfloat r, GLfloat g, GLfloat b){
	DrawImageRoot(spriteHandle,x,y,frame,r,g,b);
}


