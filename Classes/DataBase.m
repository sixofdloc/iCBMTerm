//
//  DataBase.m
//  mCoup
//
//  Created by Oliver VieBrooks on 8/20/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "DataBase.h"
#import <sqlite3.h>
#define SQLITE_OK 0
#define SQLITE_ROW 100 //Another row is ready
#define SQLITE_DONE 101 //Done finished with sqlite_step


// This is a singleton class, see below
static DataBase *sharedDataBase = nil;
static NSString *databaseName = @"cbmterm.sqlite";
static sqlite3 *database;
static NSString *databasePath;
//static sqlite3_stmt *statement;
static sqlite3_stmt *compiledStatement;
static bool bEOF;

@implementation DataBase

-(bool) init_database: (NSString *)filename
{
#ifdef SQL_DEBUG
	NSLog(@"DATABASE INIT:%@",filename);
#endif
    // First, test for existence.
    BOOL success;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    NSArray *fpaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    databasePath = [fpaths objectAtIndex:0];
    NSString *writableDBPath = [databasePath stringByAppendingPathComponent:(NSString *)databaseName];
    success = [fileManager fileExistsAtPath:writableDBPath];
    if (success) return true;
	
#ifdef SQL_DEBUG
	NSLog(@"DATABASE CREATING:%@",filename);
#endif
    // The writable database does not exist, so copy the default to the appropriate location.
    NSString *defaultDBPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:filename];
	NSLog(@"defaultDBPath: %@\nWritableDBPath:%@", defaultDBPath,writableDBPath);
   success = [fileManager copyItemAtPath:defaultDBPath toPath:writableDBPath error:&error];
    if (!success) {
        NSAssert1(0, @"Failed to create writable database file with message '%@'.", [error localizedDescription]);
 		return false;
    }
//	databasePath = writableDBPath;
	[self open_database];
	[self execute_sql:@"CREATE TABLE bbs(name varchar(80),url varchar(255),port varchar(5),description varchar(255));"];
	[self execute_sql:@"CREATE TABLE defaults (fieldname varchar(40),value varchar(80));"];
	[self execute_sql:@"CREATE TABLE buffers (created datetime,title varchar(40),buff blob);"];

	//Initial values
	[self execute_sql:@"INSERT INTO defaults VALUES ('Baud','3')"];
	[self execute_sql:@"INSERT INTO defaults VALUES ('LocalEcho','0')"];
	[self close_database];
	
	bEOF = TRUE;
	return TRUE;
}

-(NSString *)GetDefaults:(NSString *)fieldname{
	[self query:[NSString stringWithFormat:@"SELECT value FROM defaults WHERE fieldname=\"%@\";",fieldname]];
	if (![self bEOF]) return [self get_string:0];
	return (NSString *)@"";
}

-(void)SetDefaults:(NSString *)fieldname value:(NSString *)value{
	[self execute_sql:[NSString stringWithFormat:@"DELETE FROM defaults WHERE fieldname=\"%@\";",fieldname]];
	[self execute_sql:[NSString stringWithFormat:@"INSERT INTO defaults (fieldname,value) VALUES (\"%@\",\"%@\");",fieldname,[self SQLString:value]]];
}

-(bool) open_database
{
#ifdef SQL_DEBUG
	NSLog(@"DATABASE OPEN");
#endif
	static int opendatabase_result;
	opendatabase_result = sqlite3_open([[databasePath stringByAppendingPathComponent:databaseName
										] UTF8String], &database);
	return (opendatabase_result == SQLITE_OK);
}

-(bool) close_database
{
#ifdef SQL_DEBUG
	NSLog(@"DATABASE CLOSE");
#endif
	sqlite3_close(database);
	return true;
}
	
-(bool) execute_sql: (NSString *)sql
{
#ifdef SQL_DEBUG
	NSLog(@"DATABASE EXECSQL:%@",sql);
#endif
	if (sqlite3_prepare_v2(database,[sql UTF8String],-1,&compiledStatement,NULL)!=SQLITE_OK)
	{
		return false;
	}
	if (sqlite3_step(compiledStatement)!=SQLITE_DONE)
	{
		return false;
	}
	sqlite3_reset(compiledStatement);
	return true;
}

-(bool) query: (NSString *)sql
{
#ifdef SQL_DEBUG
	NSLog(@"DATABASE QUERY:%@",sql);
#endif
	int queryresult;
	queryresult = sqlite3_prepare_v2(database,[sql UTF8String],-1,&compiledStatement,NULL);
	if (queryresult!=SQLITE_OK)
	{
		NSLog(@"SQLITE_ERROR: %s",sqlite3_errmsg(database));
		return false;
	}
	queryresult = sqlite3_step(compiledStatement);
	if (queryresult==SQLITE_DONE)
	{
		bEOF = true;
		return bEOF;
	}
	if(queryresult==SQLITE_ROW)
	{
		bEOF = false;
		return true;
	}
	
	sqlite3_reset(compiledStatement);
	return true;
}

-(bool) first_record
{
#ifdef SQL_DEBUG
	NSLog(@"DATABASE FIRST RECORD");
#endif
	static int firstrec_result;
	firstrec_result = sqlite3_reset(compiledStatement);
	return true;
}

-(bool) next_record
{
#ifdef SQL_DEBUG
	NSLog(@"DATABASE NEXT RECORD");
#endif	
	static int nextrec_result;
	nextrec_result = sqlite3_step(compiledStatement);
	bEOF = (nextrec_result!=SQLITE_ROW);
	return ((nextrec_result!=SQLITE_ROW)||(nextrec_result==SQLITE_DONE));
}

-(bool) bEOF
{
	return bEOF;
}

-(int) get_int: (int) colnum
{
#ifdef SQL_DEBUG
	NSLog(@"DATABASE GET_INT COLNUM:%d",colnum);
#endif
	return sqlite3_column_int(compiledStatement,colnum);
}

-(double) get_double: (int) colnum
{
#ifdef SQL_DEBUG
	NSLog(@"DATABASE GET_DOUBLE COLNUM:%d",colnum);
#endif
	return sqlite3_column_double(compiledStatement,colnum);
}

-(NSString *) get_string: (int) colnum
{
#ifdef SQL_DEBUG
	NSLog(@"DATABASE GET_STRING COLNUM:%d",colnum);
#endif
NS_DURING
	return [NSString stringWithCString:(char *)sqlite3_column_text(compiledStatement,colnum) encoding:NSUTF8StringEncoding];
NS_HANDLER
	return @"";
NS_ENDHANDLER
}

- (id) init {
	self = [super init];
	if (self != nil) {
		//Init stuff
	}
	return self;
}

#pragma mark ---- singleton object methods ----

// See "Creating a Singleton Instance" in the Cocoa Fundamentals Guide for more info

+ (DataBase *)sharedInstance {
    @synchronized(self) {
        if (sharedDataBase == nil) {
            [[self alloc] init]; // assignment not done here
        }
    }
    return sharedDataBase;
}

+ (id)allocWithZone:(NSZone *)zone {
    @synchronized(self) {
        if (sharedDataBase == nil) {
            sharedDataBase = [super allocWithZone:zone];
            return sharedDataBase;  // assignment and return on first allocation
        }
    }
    return nil; // on subsequent allocation attempts return nil
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

- (id)retain {
    return self;
}

- (unsigned)retainCount {
    return UINT_MAX;  // denotes an object that cannot be released
}

- (void)release {
    //do nothing
}

- (id)autorelease {
    return self;
}

-(NSString *)SQLString:(NSString *)instring{
	NSRange range;
	NSMutableString *tempstr;
	range = NSMakeRange(0,[instring length]);
	tempstr = (NSMutableString *)[instring stringByReplacingOccurrencesOfString:@"'" withString:@"''" options:NSCaseInsensitiveSearch range:range];
	return (NSString *)tempstr;
}


@end