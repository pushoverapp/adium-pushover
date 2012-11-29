#import "PushoverPlugin.h"
#import "PushoverDetailPane.h"
#import <AIUtilities/AIImageAdditions.h>
#import <Adium/AIContentObject.h>
#import <Adium/AIListContact.h>
#import <Adium/ESDebugAILog.h>
#import "JSONKit.h"

#define PUSHOVER_IDENTIFIER	@"Pushover"
#define	PUSHOVER_DESC		@"Forward to Pushover"

@implementation PushoverPlugin

/* adium glue */

- (void)installPlugin
{
	[adium.contactAlertsController
		registerActionID:PUSHOVER_IDENTIFIER withHandler:self];

	/* register for screensaver events */
	screen_saver_running = NO;
	[[NSDistributedNotificationCenter defaultCenter] addObserver:self
		selector:@selector(screenSaverDidStart)
		name:@"com.apple.screensaver.didstart"
		object:nil];
	[[NSDistributedNotificationCenter defaultCenter] addObserver:self
		selector:@selector(screenSaverDidStart)
		name:@"com.apple.screenIsLocked"
		object:nil];

	[[NSDistributedNotificationCenter defaultCenter] addObserver:self
		selector:@selector(screenSaverDidStop)
		name:@"com.apple.screensaver.didstop"
		object:nil];
	[[NSDistributedNotificationCenter defaultCenter] addObserver:self
		selector:@selector(screenSaverDidStop)
		name:@"com.apple.screenIsUnlocked"
		object:nil];
}

/* text for the "Action:" drop down */
- (NSString *)shortDescriptionForActionID:(NSString *)actionID
{
	return PUSHOVER_DESC;
}

/* subtext for the "When you receive any message" line, and the text in the
 * full events list */
- (NSString *)longDescriptionForActionID:(NSString *)actionID
			     withDetails:(NSDictionary *)details
{
	NSString *desc = PUSHOVER_DESC;

	NSString *device = [details objectForKey:KEY_PUSHOVER_DEVICE_NAME];
	if (device && [device length] > 0)
		desc = [NSString stringWithFormat:@"%@ device \"%@\"", desc,
			device];

	NSNumber *when_away = [details objectForKey:KEY_ONLY_WHEN_AWAY];
	NSNumber *when_locked = [details objectForKey:KEY_ONLY_WHEN_LOCKED];
	if ([when_away boolValue] == YES && [when_locked boolValue] == YES)
		desc = [NSString stringWithFormat:@"%@ only when away and "
			"screen locked", desc];
	else if ([when_away boolValue] == YES)
		desc = [NSString stringWithFormat:@"%@ only when away", desc];
	else if ([when_locked boolValue] == YES)
		desc = [NSString stringWithFormat:@"%@ only when screen "
			"locked", desc];

	return desc;
}

- (NSImage *)imageForActionID:(NSString *)actionID
{
	return [NSImage imageNamed:@"PushoverIcon" forClass:[self class]];
}

- (AIModularPane *)detailsPaneForActionID:(NSString *)actionID
{
	return [PushoverDetailPane actionDetailsPane];
}

- (BOOL)allowMultipleActionsWithID:(NSString *)actionID
{
	/* we can be setup with different commands for different things, so,
	 * yeah */
	return YES;
}

- (NSString *)pluginAuthor
{
	return @"Superblock";
}

- (NSString *)pluginVersion
{
	return @"1.2";
}

- (NSString *)pluginDescription
{
	return @"This plugin forwards messages through Pushover while away.";
}

- (NSString *)pluginURL
{
	return @"https://pushover.net/";
}

/* screen saver callbacks */

- (void)screenSaverDidStart
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	screen_saver_running = YES;
	[pool release];
}
- (void)screenSaverDidStop
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	screen_saver_running = NO;
	[pool release];
}

/* the actual event handler */

- (BOOL)performActionID:(NSString *)actionID
	  forListObject:(AIListObject *)listObject
	    withDetails:(NSDictionary *)details
      triggeringEventID:(NSString *)eventID
	       userInfo:(id)userInfo
{
	NSString *title;
	NSString *message = [adium.contactAlertsController
		naturalLanguageDescriptionForEventID:eventID
		listObject:listObject
		userInfo:userInfo
		includeSubject:NO];
	NSString *sender;
	AIChat *chat = nil;
	BOOL is_away = NO;

	/* parse out from dictionary of saved settings */
	NSString *key = [details objectForKey:KEY_PUSHOVER_KEY];
	NSString *device_name = [details
		objectForKey:KEY_PUSHOVER_DEVICE_NAME];
	BOOL when_away = [(NSNumber *)[details
		objectForKey:KEY_ONLY_WHEN_AWAY] boolValue];
	BOOL when_locked = [(NSNumber *)[details
		objectForKey:KEY_ONLY_WHEN_LOCKED] boolValue];
	NSString *sound = [details objectForKey:KEY_PUSHOVER_SOUND];

	/* extract out account info and account away status */
	if ([adium.contactAlertsController isMessageEvent:eventID] &&
	    [userInfo respondsToSelector:@selector(objectForKey:)] &&
	    [userInfo objectForKey:@"AIContentObject"]) {
		AIContentObject *contentObject = [userInfo
			objectForKey:@"AIContentObject"];
		AIListObject *source = [contentObject source];
		chat = [userInfo objectForKey:@"AIChat"];

		if ([chat.account.statusState statusType] !=
		AIAvailableStatusType)
			is_away = YES;

		if (source)
			listObject = source;
	}

	if (listObject) {
		if ([listObject isKindOfClass:[AIListContact class]]) {
			// use the parent
			listObject = [(AIListContact *)listObject
				parentContact];
			sender = [listObject longDisplayName];
		}
		else
			sender = listObject.displayName;
	}
	else if (chat)
		sender = chat.displayName;

	if (sender)
		title = [NSString stringWithFormat:@"Message from %@", sender];

	/* now that we have our title and message, find out if we're actually
	 * supposed to do anything with it */

	if (when_away && !is_away)
		AILog(@"%@: Only sending while away; not away", self);
	else if (when_locked && !screen_saver_running)
		AILog(@"%@: Only sending while screen locked; screen not "
			"locked", self);
	else {
		AILog(@"%@: [%@, %@] [%@, %@] Forwarding to %@ (%@) (%@)",
			self,
			(when_away ? @"only when away" : @"always"),
			(is_away ? @"currently away" : @"not away"),
			(when_locked ? @"only when locked" : @"always"),
			(screen_saver_running ? @"currently locked" :
				@"not locked"),
			key,
			(device_name != nil && [device_name length] > 0 ?
				[NSString stringWithFormat:@"device %@",
				device_name] : @"all devices"),
			sound);

		[self pushMessage:message
			withTitle:title
			to:key
			forDevice:device_name
			withSound:sound];
	}

	return YES;
}

- (void)pushMessage:(NSString *)message
	withTitle:(NSString *)title
	to:(NSString *)user_key
	forDevice:(NSString *)device_name
	withSound:(NSString *)sound
{
	NSString *token = [NSString stringWithFormat:@"%s", PUSHOVER_API_TOKEN];
	NSString *timestamp = [NSString stringWithFormat:@"%ld", (long)[[NSDate
		date] timeIntervalSince1970]];

	NSMutableDictionary *post = [NSMutableDictionary dictionaryWithCapacity:1];

	[post setObject:token forKey:@"token"];
	[post setObject:user_key forKey:@"user"];
	[post setObject:device_name forKey:@"device"];
	[post setObject:timestamp forKey:@"timestamp"];

	[post setObject:message forKey:@"message"];

	if (title != nil && [title length] > 0)
		[post setObject:title forKey:@"title"];
	
	if (sound != nil && [sound length] > 0)
		[post setObject:sound forKey:@"sound"];

	NSString *postString = [self URLEncodedFromDictionary:post];
	NSString *postLength = [NSString stringWithFormat:@"%lu",
		[postString length]];

	NSMutableURLRequest *request = [[[NSMutableURLRequest alloc] init]
		autorelease];
	[request setURL:[NSURL URLWithString:@"" PUSHOVER_API_MESSAGE_URL]];
	[request setHTTPMethod:@"POST"];
	[request setValue:postLength forHTTPHeaderField:@"Content-Length"];
	[request setValue:@"application/x-www-form-urlencoded"
		forHTTPHeaderField:@"Content-Type"];
	[request setHTTPBody:[postString dataUsingEncoding:[NSString
		defaultCStringEncoding]]];

	responseData = [[NSMutableData data] retain];
	[[[NSURLConnection alloc] initWithRequest:request delegate:self]
		autorelease];
}

/* url helpers */

- (NSString *)URLEncodedFromDictionary:(NSDictionary *)dict {
	NSString *ret = [[NSString new] autorelease];

	for (NSString *key in dict) {
		NSString *val = [dict valueForKey:key];
		NSString *encoded = [self urlEncodeValue:val];

		NSString *kvf;
		if ([ret length]==0)
			kvf = @"%@%@=%@";
		else
			kvf = @"%@&%@=%@";

		ret = [NSString stringWithFormat:kvf, ret, key, encoded];
	}

	return ret;
}

- (NSString *)urlEncodeValue:(NSString *)str
{
	NSString *result = (NSString *)CFURLCreateStringByAddingPercentEscapes(
		kCFAllocatorDefault, (CFStringRef)str, NULL,
		CFSTR("!$&'()*+,-./:;=?@_~"), kCFStringEncodingUTF8);
	return [result autorelease];
}

/* url delegate stuff */

- (void)connection:(NSURLConnection *)connection
	didReceiveResponse:(NSURLResponse *)response
{
	[responseData setLength:0];
}
 
- (void)connection:(NSURLConnection *)connection
	didReceiveData:(NSData *)data
{
	[responseData appendData:data];
}
 
- (void)connection:(NSURLConnection *)connection
	didFailWithError:(NSError *)error
{
	NSLog(@"Failed POSTing to Pushover: %@", error);
}
 
- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	/* TODO: release responseData? */
}

@end
