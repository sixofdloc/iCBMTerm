//
//  base64.h
//  Term
//
//  Created by Oliver VieBrooks on 10/6/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface base64 : NSObject {
}
+ (NSString*) encode:(const uint8_t*) input length:(NSInteger) length;
+ (NSData*) decode:(const char*) string length:(NSInteger) inputLength;

@end
