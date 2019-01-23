//
//  DataBase.h
//  mCoup
//
//  Created by Oliver VieBrooks on 8/20/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
@interface DataBase : NSObject {
}

+ (DataBase *)sharedInstance;

-(bool) init_database: (NSString *)filename;
-(bool) open_database;
-(bool) close_database;
-(bool) execute_sql: (NSString *)sql;
-(bool) query: (NSString *)sql;
-(bool) first_record;
-(bool) next_record;
-(bool) bEOF;
-(int) get_int: (int) colnum;
-(double) get_double: (int) colnum;
-(NSString *) get_string: (int) colnum;

-(NSString *)GetDefaults:(NSString *)fieldname;
-(void)SetDefaults:(NSString *)fieldname value:(NSString *)value;
-(bool)HasDefaults:(NSString *)fieldname;
-(NSString *)SQLString:(NSString *)instring;
@end

