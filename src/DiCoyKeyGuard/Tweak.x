#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CommonCrypto/CommonDigest.h>
#import <dlfcn.h>
#import <objc/runtime.h>
#import <mach-o/dyld.h>
#import <substrate.h>
#import <sys/utsname.h>

static NSString *const kServerBaseUrl = @"https://fastst.cloud";
static NSString *const kKeyGuardDir = @"/var/mobile/Library/Application Support/VCAM";
static NSString *const kKeyGuardCameraDir = @"/var/mobile/Library/Application Support/VCAM/com.apple.camera";
static NSString *const kKeyGuardPrefsPath = @"/var/mobile/Library/Application Support/VCAM/com.apple.camera/license.plist";
static NSString *const kKeyGuardFallbackPath = @"/var/mobile/Library/Preferences/com.dicoy.keyguard.plist";
static NSString *const kKeyGuardDefaultsKey = @"DiCoyKeyGuardLicenseKey";
static NSString *const kDeviceIdDefaultsKey = @"DiCoyKeyGuardDeviceID";
static NSString *const kSecretSalt = @"DiCoyVCAM#2026!SecretKey";
static NSString *const kMasterKey1 = @"99999999-DICOYVIP";
static NSString *const kMasterKey2 = @"88888888-88888888";

static void (*orig_showMenu)(id self, SEL _cmd) = NULL;

static void showActivationPrompt(id controller, NSString *customError);

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
                applyFn("DiCoyKeyGuard");
                applyFn("DiCoyCamera");
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
    NSArray *paths = @[
        kKeyGuardPrefsPath,
        [kKeyGuardDir stringByAppendingPathComponent:@"license.plist"],
        kKeyGuardFallbackPath
    ];
    for (NSString *p in paths) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:p]) {
            NSMutableDictionary *d = [NSMutableDictionary dictionaryWithContentsOfFile:p];
            if (d && d.count > 0) return d;
        }
    }
    return [NSMutableDictionary dictionary];
}

static void savePrefs(NSMutableDictionary *dict) {
    applySandyProfileIfNeeded();
    [[NSFileManager defaultManager] createDirectoryAtPath:kKeyGuardCameraDir withIntermediateDirectories:YES attributes:nil error:nil];
    [[NSFileManager defaultManager] createDirectoryAtPath:kKeyGuardDir withIntermediateDirectories:YES attributes:nil error:nil];

    [dict writeToFile:kKeyGuardPrefsPath atomically:YES];
    [dict writeToFile:[kKeyGuardDir stringByAppendingPathComponent:@"license.plist"] atomically:YES];
    [dict writeToFile:kKeyGuardFallbackPath atomically:YES];
}

// Returns 8-char uppercase hex Device ID, e.g. "A3F98B2C"
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

static NSString *getDeviceModelName(void) {
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString *code = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
    if ([code isEqualToString:@"iPhone9,1"] || [code isEqualToString:@"iPhone9,3"]) return @"iPhone 7";
    if ([code isEqualToString:@"iPhone9,2"] || [code isEqualToString:@"iPhone9,4"]) return @"iPhone 7 Plus";
    if ([code isEqualToString:@"iPhone10,1"] || [code isEqualToString:@"iPhone10,4"]) return @"iPhone 8";
    if ([code isEqualToString:@"iPhone10,2"] || [code isEqualToString:@"iPhone10,5"]) return @"iPhone 8 Plus";
    if ([code isEqualToString:@"iPhone10,3"] || [code isEqualToString:@"iPhone10,6"]) return @"iPhone X";
    if ([code isEqualToString:@"iPhone11,8"]) return @"iPhone XR";
    if ([code isEqualToString:@"iPhone11,2"]) return @"iPhone XS";
    if ([code isEqualToString:@"iPhone11,6"]) return @"iPhone XS Max";
    if ([code isEqualToString:@"iPhone12,1"]) return @"iPhone 11";
    if ([code isEqualToString:@"iPhone12,3"]) return @"iPhone 11 Pro";
    if ([code isEqualToString:@"iPhone12,5"]) return @"iPhone 11 Pro Max";
    if ([code isEqualToString:@"iPhone12,8"]) return @"iPhone SE (2nd gen)";
    return code ?: [UIDevice currentDevice].model;
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
    if (!keyInput || keyInput.length == 0) return 1;
    NSString *cleaned = [[keyInput stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] uppercaseString];

    // Master keys bypass
    if ([cleaned isEqualToString:kMasterKey1] || [cleaned isEqualToString:kMasterKey2]) {
        if (outExpiryFormatted) *outExpiryFormatted = @"Vĩnh viễn (Master Key)";
        return 0;
    }

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

static uintptr_t getDiCoyBaseAddress(void) {
    uint32_t count = _dyld_image_count();
    for (uint32_t i = 0; i < count; i++) {
        const char *name = _dyld_get_image_name(i);
        if (name && strstr(name, "DiCoyTweak.dylib")) {
            return (uintptr_t)_dyld_get_image_header(i);
        }
    }
    return 0;
}

static UIViewController *getTopViewController(void) {
    // 1. Try DiCoyTweak's internal topViewController helper at 0xe3f4
    uintptr_t base = getDiCoyBaseAddress();
    if (base != 0) {
        typedef UIViewController *(*DiCoyTopVCFunc)(void);
        DiCoyTopVCFunc fn = (DiCoyTopVCFunc)(base + 0xe3f4);
        @try {
            UIViewController *vc = fn();
            if (vc && [vc isKindOfClass:[UIViewController class]]) {
                return vc;
            }
        } @catch (...) {}
    }

    // 2. Cascade through active scenes & windows
    UIWindow *candidate = nil;
    if ([[UIApplication sharedApplication] respondsToSelector:@selector(connectedScenes)]) {
        for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
            if ([scene isKindOfClass:[UIWindowScene class]]) {
                UIWindowScene *ws = (UIWindowScene *)scene;
                for (UIWindow *w in ws.windows) {
                    if (w.isKeyWindow) { candidate = w; break; }
                    if (!candidate && !w.hidden) candidate = w;
                }
            }
            if (candidate && candidate.isKeyWindow) break;
        }
    }

    if (!candidate) {
        NSArray *windows = [UIApplication sharedApplication].windows;
        for (UIWindow *w in windows) {
            if (w.isKeyWindow) { candidate = w; break; }
            if (!candidate && !w.hidden) candidate = w;
        }
        if (!candidate && [UIApplication sharedApplication].keyWindow) {
            candidate = [UIApplication sharedApplication].keyWindow;
        }
    }

    UIViewController *top = candidate.rootViewController;
    while (top.presentedViewController) {
        top = top.presentedViewController;
    }
    return top;
}

// Gửi xác thực online ngầm lên server (không chặn app nếu offline)
static void verifyKeyOnlineAsync(NSString *key, NSString *rawId) {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/vcam/api/verify", kServerBaseUrl]];
        NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
        req.HTTPMethod = @"POST";
        req.timeoutInterval = 6.0;
        [req setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];

        NSDictionary *dict = @{@"device_id": rawId ?: @"", @"key": key ?: @""};
        NSData *postData = [NSJSONSerialization dataWithJSONObject:dict options:0 error:nil];
        req.HTTPBody = postData;

        NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:req
            completionHandler:^(NSData *data, NSURLResponse *res, NSError *err) {
                // Background verify only, log or update if needed
            }];
        [task resume];
    });
}

// Gửi yêu cầu cấp Key từ iPhone lên server
static void sendKeyRequestToServer(id controller, UIViewController *topVC, NSString *rawId, NSString *displayId) {
    NSString *modelName = getDeviceModelName();
    NSString *iosVer = [UIDevice currentDevice].systemVersion ?: @"";
    NSString *devFullName = [NSString stringWithFormat:@"%@ (iOS %@)", modelName, iosVer];

    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/vcam/api/request-key", kServerBaseUrl]];
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
    req.HTTPMethod = @"POST";
    req.timeoutInterval = 8.0;
    [req setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];

    NSDictionary *payload = @{
        @"device_id": rawId,
        @"device_name": devFullName,
        @"ios_version": iosVer
    };
    req.HTTPBody = [NSJSONSerialization dataWithJSONObject:payload options:0 error:nil];

    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:req
        completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (error || !data) {
                    UIAlertController *errAlert = [UIAlertController alertControllerWithTitle:@"Không thể kết nối máy chủ"
                        message:[NSString stringWithFormat:@"Không gửi được yêu cầu. Vui lòng kiểm tra Wifi/4G hoặc liên hệ trực tiếp Admin kèm Mã máy:\n\n%@", displayId]
                        preferredStyle:UIAlertControllerStyleAlert];
                    [errAlert addAction:[UIAlertAction actionWithTitle:@"Đã hiểu" style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
                        showActivationPrompt(controller, nil);
                    }]];
                    [topVC presentViewController:errAlert animated:YES completion:nil];
                    return;
                }

                NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                if ([json isKindOfClass:[NSDictionary class]] && [json[@"ok"] boolValue]) {
                    // Nếu máy đã có sẵn key đã duyệt trước đó
                    if ([json[@"already_approved"] boolValue] && [json[@"key"] length] > 0) {
                        NSString *availKey = json[@"key"];
                        UIAlertController *foundAlert = [UIAlertController alertControllerWithTitle:@"Đã có Key sẵn"
                            message:[NSString stringWithFormat:@"Máy này đã được cấp Key:\n%@\n\nBạn có muốn tự động kích hoạt ngay không?", availKey]
                            preferredStyle:UIAlertControllerStyleAlert];
                        [foundAlert addAction:[UIAlertAction actionWithTitle:@"Kích hoạt ngay" style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
                            saveLicenseKey(availKey);
                            if (orig_showMenu) {
                                orig_showMenu(controller, @selector(showMenu));
                            }
                        }]];
                        [foundAlert addAction:[UIAlertAction actionWithTitle:@"Hủy" style:UIAlertActionStyleCancel handler:nil]];
                        [topVC presentViewController:foundAlert animated:YES completion:nil];
                        return;
                    }

                    // Đã gửi yêu cầu thành công, chờ admin duyệt
                    UIAlertController *okAlert = [UIAlertController alertControllerWithTitle:@"Đã gửi yêu cầu thành công!"
                        message:[NSString stringWithFormat:@"Mã máy của bạn: %@\n\nYêu cầu đã được gửi lên hệ thống. Vui lòng báo Admin / Người bán duyệt để nhận Key kích hoạt.", displayId]
                        preferredStyle:UIAlertControllerStyleAlert];
                    [okAlert addAction:[UIAlertAction actionWithTitle:@"Nhập Key khi đã có" style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
                        showActivationPrompt(controller, nil);
                    }]];
                    [okAlert addAction:[UIAlertAction actionWithTitle:@"Đóng" style:UIAlertActionStyleCancel handler:nil]];
                    [topVC presentViewController:okAlert animated:YES completion:nil];
                } else {
                    NSString *msg = json[@"message"] ?: @"Có lỗi xảy ra khi gửi yêu cầu.";
                    showActivationPrompt(controller, msg);
                }
            });
        }];
    [task resume];
}

static void showActivationPrompt(id controller, NSString *customError) {
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

        // Nút 1: Kích hoạt key
        UIAlertAction *activateAction = [UIAlertAction actionWithTitle:@"Kích hoạt"
                                                                 style:UIAlertActionStyleDefault
                                                               handler:^(UIAlertAction *action) {
            NSString *entered = alert.textFields.firstObject.text ?: @"";
            NSString *expiryFmt = nil;
            int status = validateKey(entered, rawId, &expiryFmt);
            if (status == 0) {
                NSString *cleanKey = [[entered stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] uppercaseString];
                saveLicenseKey(cleanKey);
                verifyKeyOnlineAsync(cleanKey, rawId);

                UIAlertController *okAlert = [UIAlertController alertControllerWithTitle:@"Kích hoạt thành công"
                                                                                 message:[NSString stringWithFormat:@"Hạn sử dụng: %@", expiryFmt]
                                                                          preferredStyle:UIAlertControllerStyleAlert];
                [okAlert addAction:[UIAlertAction actionWithTitle:@"Mở VCAM"
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction *a) {
                    if (orig_showMenu) {
                        orig_showMenu(controller, @selector(showMenu));
                    }
                }]];
                [topVC presentViewController:okAlert animated:YES completion:nil];
            } else if (status == 2) {
                showActivationPrompt(controller, @"Key đã hết hạn sử dụng!");
            } else {
                showActivationPrompt(controller, @"Key không hợp lệ cho mã máy này!");
            }
        }];

        // Nút 2: Yêu cầu cấp Key trực tiếp lên server
        UIAlertAction *requestAction = [UIAlertAction actionWithTitle:@"Yêu cầu cấp Key"
                                                                style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction *action) {
            sendKeyRequestToServer(controller, topVC, rawId, displayId);
        }];

        // Nút 3: Đóng
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Đóng"
                                                               style:UIAlertActionStyleCancel
                                                             handler:nil];

        [alert addAction:activateAction];
        [alert addAction:requestAction];
        [alert addAction:cancelAction];

        [topVC presentViewController:alert animated:YES completion:nil];
    });
}

static void my_showMenu(id self, SEL _cmd) {
    NSString *rawId = getDeviceIdRaw();
    NSString *savedKey = getSavedLicenseKey();
    int status = validateKey(savedKey, rawId, nil);
    if (status == 0) {
        if (orig_showMenu) {
            orig_showMenu(self, _cmd);
        }
        return;
    }
    NSString *err = (status == 2) ? @"Key của bạn đã hết hạn." : nil;
    showActivationPrompt(self, err);
}

%ctor {
    dlopen("/var/jb/Library/MobileSubstrate/DynamicLibraries/DiCoyTweak.dylib", RTLD_NOW);
    dlopen("/Library/MobileSubstrate/DynamicLibraries/DiCoyTweak.dylib", RTLD_NOW);

    uintptr_t base = getDiCoyBaseAddress();
    if (base != 0) {
        // Direct function hook at 0xe714 (the exact entry point of showMenu in DiCoyTweak.dylib)
        void *target0xe714 = (void *)(base + 0xe714);
        MSHookFunction(target0xe714, (void *)my_showMenu, (void **)&orig_showMenu);
    }

    Class cls = objc_getClass("DiCoySessionController");
    if (cls) {
        Method m = class_getInstanceMethod(cls, @selector(showMenu));
        if (m) {
            void *imp = (void *)method_getImplementation(m);
            if (imp && imp != (void *)my_showMenu && (!orig_showMenu || imp != (void *)(base + 0xe714))) {
                MSHookFunction(imp, (void *)my_showMenu, (void **)&orig_showMenu);
            }
        }
    }
}
