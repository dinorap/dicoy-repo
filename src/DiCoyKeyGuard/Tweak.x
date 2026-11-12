#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CommonCrypto/CommonDigest.h>
#import <dlfcn.h>
#import <objc/runtime.h>
#import <string.h>

static NSString *const kKeyGuardPrefsPath = @"/var/mobile/Library/Preferences/com.dicoy.keyguard.plist";
static NSString *const kKeyGuardDefaultsKey = @"DiCoyKeyGuardLicenseKey";
static NSString *const kDeviceIdDefaultsKey = @"DiCoyKeyGuardDeviceID";
static NSString *const kSecretSalt = @"DiCoyVCAM#2026!SecretKey";

@interface DiCoyTweakManager : NSObject
+ (instancetype)sharedManager;
- (void)showMenu;
@end

static void applySandyProfileIfNeeded(void) {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        void *handle = dlopen("/var/jb/usr/lib/libsandy.dylib", RTLD_NOW);
        if (!handle) handle = dlopen("/usr/lib/libsandy.dylib", RTLD_NOW);
        if (handle) {
            typedef int (*libSandyApplyProfileFunc)(const char *profileName);
            libSandyApplyProfileFunc applyFn = (libSandyApplyProfileFunc)dlsym(handle, "libSandy_applyProfile");
            if (applyFn) {
                applyFn("DiCoyControl");
            }
        }
    });
}

static NSString *sha256Hex(NSString *input) {
    const char *cstr = [input UTF8String];
    unsigned char digest[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256(cstr, (CC_LONG)strlen(cstr), digest);
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_SHA256_DIGEST_LENGTH * 2];
    for (int i = 0; i < CC_SHA256_DIGEST_LENGTH; i++) {
        [output appendFormat:@"%02X", digest[i]];
    }
    return output;
}

static NSMutableDictionary *loadPrefs(void) {
    applySandyProfileIfNeeded();
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithContentsOfFile:kKeyGuardPrefsPath];
    if (!dict) dict = [NSMutableDictionary dictionary];
    return dict;
}

static void savePrefs(NSMutableDictionary *dict) {
    applySandyProfileIfNeeded();
    [dict writeToFile:kKeyGuardPrefsPath atomically:YES];
}

// Returns 8-char uppercase hex Device ID (without dash), e.g. "A3F98B2C"
static NSString *getDeviceIdRaw(void) {
    NSMutableDictionary *prefs = loadPrefs();
    NSString *stored = prefs[@"deviceId"];
    if (stored.length == 8) {
        return stored;
    }

    NSString *udid = nil;
    void *mg = dlopen("/usr/lib/libMobileGestalt.dylib", RTLD_NOW);
    if (mg) {
        typedef CFTypeRef (*MGCopyAnswerFunc)(CFStringRef prop);
        MGCopyAnswerFunc copyAnswer = (MGCopyAnswerFunc)dlsym(mg, "MGCopyAnswer");
        if (copyAnswer) {
            CFTypeRef val = copyAnswer(CFSTR("UniqueDeviceID"));
            if (val && CFGetTypeID(val) == CFStringGetTypeID()) {
                udid = [(__bridge NSString *)val copy];
            }
            if (val) CFRelease(val);
        }
        dlclose(mg);
    }

    NSString *rawId = nil;
    if (udid.length > 0) {
        rawId = [sha256Hex(udid) substringToIndex:8];
    } else {
        NSString *defaultsId = [[NSUserDefaults standardUserDefaults] stringForKey:kDeviceIdDefaultsKey];
        if (defaultsId.length == 8) {
            rawId = defaultsId;
        } else {
            NSString *uuid = [[NSUUID UUID] UUIDString];
            rawId = [sha256Hex(uuid) substringToIndex:8];
            [[NSUserDefaults standardUserDefaults] setObject:rawId forKey:kDeviceIdDefaultsKey];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
    }

    prefs[@"deviceId"] = rawId;
    savePrefs(prefs);
    return rawId;
}

static NSString *formatDeviceId(NSString *rawId) {
    if (rawId.length == 8) {
        return [NSString stringWithFormat:@"%@-%@", [rawId substringToIndex:4], [rawId substringFromIndex:4]];
    }
    return rawId;
}

static NSString *getSavedLicenseKey(void) {
    NSMutableDictionary *prefs = loadPrefs();
    NSString *key = prefs[@"licenseKey"];
    if (key.length > 0) return key;
    return [[NSUserDefaults standardUserDefaults] stringForKey:kKeyGuardDefaultsKey];
}

static void saveLicenseKey(NSString *key) {
    NSMutableDictionary *prefs = loadPrefs();
    prefs[@"licenseKey"] = key;
    savePrefs(prefs);
    [[NSUserDefaults standardUserDefaults] setObject:key forKey:kKeyGuardDefaultsKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

// Validates key format: YYYYMMDD-XXXXXXXX
// Returns: 0 = valid, 1 = invalid format/signature, 2 = expired
static int validateKey(NSString *keyInput, NSString *deviceIdRaw, NSString **outExpiryFormatted) {
    if (!keyInput) return 1;
    NSString *cleaned = [[keyInput stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] uppercaseString];
    NSArray *parts = [cleaned componentsSeparatedByString:@"-"];
    if (parts.count != 2) return 1;

    NSString *expiryStr = parts[0];
    NSString *sigStr = parts[1];
    if (expiryStr.length != 8 || sigStr.length != 8) return 1;

    NSString *payload = [NSString stringWithFormat:@"%@:%@:%@", deviceIdRaw, expiryStr, kSecretSalt];
    NSString *expectedSig = [sha256Hex(payload) substringToIndex:8];
    if (![sigStr isEqualToString:expectedSig]) {
        return 1;
    }

    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    df.dateFormat = @"yyyyMMdd";
    df.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    NSString *todayStr = [df stringFromDate:[NSDate date]];

    if (outExpiryFormatted) {
        if ([expiryStr isEqualToString:@"20991231"] || [expiryStr isEqualToString:@"99991231"]) {
            *outExpiryFormatted = @"Vĩnh viễn";
        } else {
            *outExpiryFormatted = [NSString stringWithFormat:@"%@/%@/%@",
                [expiryStr substringWithRange:NSMakeRange(6, 2)],
                [expiryStr substringWithRange:NSMakeRange(4, 2)],
                [expiryStr substringWithRange:NSMakeRange(0, 4)]];
        }
    }

    if ([todayStr integerValue] > [expiryStr integerValue]) {
        return 2;
    }
    return 0;
}

static UIViewController *getTopViewController(void) {
    UIWindow *keyWindow = nil;
    if (@available(iOS 13.0, *)) {
        for (UIWindowScene *scene in [UIApplication sharedApplication].connectedScenes) {
            if (scene.activationState == UISceneActivationStateForegroundActive) {
                for (UIWindow *w in scene.windows) {
                    if (w.isKeyWindow) { keyWindow = w; break; }
                }
            }
            if (keyWindow) break;
        }
    }
    if (!keyWindow) {
        for (UIWindow *w in [UIApplication sharedApplication].windows) {
            if (w.isKeyWindow) { keyWindow = w; break; }
        }
    }
    UIViewController *top = keyWindow.rootViewController;
    while (top.presentedViewController) {
        top = top.presentedViewController;
    }
    return top;
}

static void showActivationPrompt(DiCoyTweakManager *manager, NSString *customError) {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIViewController *topVC = getTopViewController();
        if (!topVC) return;

        NSString *rawId = getDeviceIdRaw();
        NSString *displayId = formatDeviceId(rawId);

        NSMutableString *msg = [NSMutableString stringWithFormat:@"Mã máy: %@\nNhập Key kích hoạt để mở VCAM.", displayId];
        if (customError.length > 0) {
            [msg appendFormat:@"\n\n⚠️ %@", customError];
        }

        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"VCAM — Kích hoạt bản quyền"
                                                                       message:msg
                                                                preferredStyle:UIAlertControllerStyleAlert];

        [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            textField.placeholder = @"YYYYMMDD-XXXXXXXX";
            textField.autocapitalizationType = UITextAutocapitalizationTypeAllCharacters;
            textField.autocorrectionType = UITextAutocorrectionTypeNo;
            textField.clearButtonMode = UITextFieldViewModeWhileEditing;
        }];

        UIAlertAction *activateAction = [UIAlertAction actionWithTitle:@"Kích hoạt"
                                                                 style:UIAlertActionStyleDefault
                                                               handler:^(UIAlertAction *action) {
            NSString *entered = alert.textFields.firstObject.text ?: @"";
            NSString *expiryFmt = nil;
            int status = validateKey(entered, rawId, &expiryFmt);
            if (status == 0) {
                NSString *cleanKey = [[entered stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] uppercaseString];
                saveLicenseKey(cleanKey);

                UIAlertController *okAlert = [UIAlertController alertControllerWithTitle:@"Kích hoạt thành công"
                                                                                 message:[NSString stringWithFormat:@"Hạn sử dụng: %@", expiryFmt]
                                                                          preferredStyle:UIAlertControllerStyleAlert];
                [okAlert addAction:[UIAlertAction actionWithTitle:@"Mở VCAM"
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction *a) {
                    [manager showMenu];
                }]];
                [topVC presentViewController:okAlert animated:YES completion:nil];
            } else if (status == 2) {
                showActivationPrompt(manager, @"Key đã hết hạn sử dụng!");
            } else {
                showActivationPrompt(manager, @"Key không hợp lệ cho mã máy này!");
            }
        }];

        UIAlertAction *copyLinkAction = [UIAlertAction actionWithTitle:@"Copy Link lấy Key"
                                                                 style:UIAlertActionStyleDefault
                                                               handler:^(UIAlertAction *action) {
            NSString *reqLink = [NSString stringWithFormat:@"https://dinorap.github.io/dicoy-repo/key.html?id=%@", rawId];
            [UIPasteboard generalPasteboard].string = reqLink;
            showActivationPrompt(manager, @"Đã copy link! Dán gửi Admin để nhận Key.");
        }];

        UIAlertAction *copyAction = [UIAlertAction actionWithTitle:@"Copy Mã máy"
                                                             style:UIAlertActionStyleDefault
                                                           handler:^(UIAlertAction *action) {
            [UIPasteboard generalPasteboard].string = displayId;
            showActivationPrompt(manager, [NSString stringWithFormat:@"Đã copy mã máy: %@", displayId]);
        }];

        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Đóng"
                                                               style:UIAlertActionStyleCancel
                                                             handler:nil];

        [alert addAction:activateAction];
        [alert addAction:copyLinkAction];
        [alert addAction:copyAction];
        [alert addAction:cancelAction];

        [topVC presentViewController:alert animated:YES completion:nil];
    });
}

%hook DiCoyTweakManager

- (void)showMenu {
    NSString *rawId = getDeviceIdRaw();
    NSString *savedKey = getSavedLicenseKey();
    int status = validateKey(savedKey, rawId, nil);
    if (status == 0) {
        %orig;
        return;
    }
    NSString *err = (status == 2) ? @"Key của bạn đã hết hạn." : nil;
    showActivationPrompt(self, err);
}

%end

%ctor {
    if (!objc_getClass("DiCoyTweakManager")) {
        dlopen("/var/jb/Library/MobileSubstrate/DynamicLibraries/DiCoyTweak.dylib", RTLD_LAZY);
    }
    %init;
}

