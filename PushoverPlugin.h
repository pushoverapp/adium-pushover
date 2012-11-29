#import <Cocoa/Cocoa.h>
#import <Adium/AIPlugin.h>
#import <Adium/AISharedAdium.h>
#import <Adium/AIContactAlertsControllerProtocol.h>

#define KEY_PUSHOVER_KEY		@"PushoverKey"
#define KEY_PUSHOVER_DEVICE_NAME	@"PushoverDeviceName"
#define KEY_PUSHOVER_SOUND		@"PushoverSound"
#define KEY_ONLY_WHEN_AWAY		@"PushoverOnlyWhenAway"
#define KEY_ONLY_WHEN_LOCKED		@"PushoverOnlyWhenLocked"

/* token for adium app */
#define PUSHOVER_API_TOKEN		"IyulbcJ6RTdTfHrDtwhzPKFjiSiZyD"
#define PUSHOVER_API_MESSAGE_URL	"https://api.pushover.net/1/messages.json"
#define PUSHOVER_API_SOUNDS_URL 	"https://api.pushover.net/1/sounds.json"

@protocol AIContentFilter;

@interface PushoverPlugin : AIPlugin <AIActionHandler> {
	NSMutableData	*responseData;
	BOOL		screen_saver_running;
}

- (void)pushMessage:(NSString *)message
	withTitle:(NSString *)title
	to:(NSString *)user_key
	forDevice:(NSString *)device_name
	withSound:(NSString *)sound;

- (NSString *)URLEncodedFromDictionary:(NSDictionary *)dict;

- (NSString *)urlEncodeValue:(NSString *)str;

@end

