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

// HOÀN TOÀN BỎ CƠ CHẾ DỰ PHÒNG / MASTER KEYS
// Mọi bản quyền bắt buộc phải kích hoạt và chứng thực qua Server thật!

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

// Trả về 8 ký tự hex viết hoa mã máy, vd "A3F98B2C"
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

// Khách dán Key vào và ấn Kích hoạt -> Gửi mã máy lên server để tự động gắn Key vào máy
static void activateKeyOnServer(id controller, UIViewController *topVC, NSString *enteredKey, NSString *rawId) {
    NSString *cleanKey = [[enteredKey stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] uppercaseString];
    if (cleanKey.length == 0) {
        showActivationPrompt(controller, @"Vui lòng nhập Key kích hoạt.");
        return;
    }

    NSString *modelName = getDeviceModelName();
    NSString *iosVer = [UIDevice currentDevice].systemVersion ?: @"";
    NSString *devFullName = [NSString stringWithFormat:@"%@ (iOS %@)", modelName, iosVer];

    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/vcam/api/activate", kServerBaseUrl]];
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
    req.HTTPMethod = @"POST";
    req.timeoutInterval = 10.0;
    [req setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];

    NSDictionary *payload = @{
        @"key": cleanKey,
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
                        message:@"Không kết nối được server để kích hoạt Key. Vui lòng kiểm tra Wifi/4G rồi thử lại."
                        preferredStyle:UIAlertControllerStyleAlert];
                    [errAlert addAction:[UIAlertAction actionWithTitle:@"Đã hiểu" style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
                        showActivationPrompt(controller, nil);
                    }]];
                    [topVC presentViewController:errAlert animated:YES completion:nil];
                    return;
                }

                NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                if ([json isKindOfClass:[NSDictionary class]] && [json[@"ok"] boolValue]) {
                    // Kích hoạt thành công: lưu license được server ký
                    NSMutableDictionary *prefs = loadPrefs();
                    prefs[@"licenseKey"] = json[@"key"] ?: cleanKey;
                    prefs[@"deviceId"] = rawId;
                    prefs[@"expireAt"] = json[@"expire_at"] ?: @"20991231";
                    prefs[@"expireFormatted"] = json[@"expire_at_fmt"] ?: @"Vĩnh viễn";
                    prefs[@"signature"] = json[@"signature"] ?: @"";
                    savePrefs(prefs);

                    [[NSUserDefaults standardUserDefaults] setObject:(json[@"key"] ?: cleanKey) forKey:kKeyGuardDefaultsKey];
                    [[NSUserDefaults standardUserDefaults] synchronize];

                    NSString *expFmt = json[@"expire_at_fmt"] ?: @"Vĩnh viễn";
                    UIAlertController *okAlert = [UIAlertController alertControllerWithTitle:@"Kích hoạt thành công!"
                        message:[NSString stringWithFormat:@"Bản quyền VCAM đã được kích hoạt cho thiết bị này.\n\nHạn dùng: %@", expFmt]
                        preferredStyle:UIAlertControllerStyleAlert];
                    [okAlert addAction:[UIAlertAction actionWithTitle:@"Mở VCAM" style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
                        if (orig_showMenu) {
                            orig_showMenu(controller, @selector(showMenu));
                        }
                    }]];
                    [topVC presentViewController:okAlert animated:YES completion:nil];
                } else {
                    NSString *msg = json[@"message"] ?: @"Key không hợp lệ hoặc không thể kích hoạt.";
                    showActivationPrompt(controller, msg);
                }
            });
        }];
    [task resume];
}

// Gửi yêu cầu xin cấp Key lên server (nếu khách chưa có key)
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
                        activateKeyOnServer(controller, topVC, availKey, rawId);
                        return;
                    }

                    // Đã gửi yêu cầu thành công, chờ admin duyệt
                    UIAlertController *okAlert = [UIAlertController alertControllerWithTitle:@"Đã gửi yêu cầu thành công!"
                        message:[NSString stringWithFormat:@"Mã máy của bạn: %@\n\nYêu cầu đã được gửi lên hệ thống. Vui lòng báo Admin / Người bán để nhận Key kích hoạt.", displayId]
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

        NSMutableString *msg = [NSMutableString stringWithFormat:@"Mã máy: %@\nNhập hoặc dán Key để mở khóa VCAM.", displayId];
        if (customError.length > 0) {
            [msg appendFormat:@"\n\n⚠️ %@", customError];
        }

        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"VCAM — Kích hoạt bản quyền"
                                                                       message:msg
                                                                preferredStyle:UIAlertControllerStyleAlert];

        // Tự động kiểm tra Clipboard xem khách có vừa copy Key không
        NSString *clipboardText = [UIPasteboard generalPasteboard].string ?: @"";
        NSString *prefillKey = @"";
        NSString *trimmedClip = [clipboardText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if ([trimmedClip hasPrefix:@"VCAM-"] || trimmedClip.length >= 10) {
            prefillKey = trimmedClip;
        }

        [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            textField.placeholder = @"Dán Key vào đây (VD: VCAM-...)";
            textField.text = prefillKey;
            textField.autocapitalizationType = UITextAutocapitalizationTypeAllCharacters;
            textField.autocorrectionType = UITextAutocorrectionTypeNo;
            textField.clearButtonMode = UITextFieldViewModeWhileEditing;
        }];

        // Nút 1: Kích hoạt Key trực tiếp với server
        UIAlertAction *activateAction = [UIAlertAction actionWithTitle:@"Kích hoạt"
                                                                 style:UIAlertActionStyleDefault
                                                               handler:^(UIAlertAction *action) {
            NSString *entered = alert.textFields.firstObject.text ?: @"";
            activateKeyOnServer(controller, topVC, entered, rawId);
        }];

        // Nút 2: Yêu cầu cấp Key (dành cho ai chưa có key)
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

static BOOL isVerifyingKey = NO;

static void my_showMenu(id targetObj, SEL targetCmd) {
    NSString *rawId = getDeviceIdRaw();
    NSMutableDictionary *prefs = loadPrefs();
    NSString *savedKey = prefs[@"licenseKey"];
    if (!savedKey || savedKey.length == 0) {
        savedKey = [[NSUserDefaults standardUserDefaults] stringForKey:kKeyGuardDefaultsKey];
    }

    if (!savedKey || savedKey.length == 0) {
        showActivationPrompt(targetObj, nil);
        return;
    }

    if (isVerifyingKey) return;
    isVerifyingKey = YES;

    __strong id strongTarget = targetObj;
    SEL strongCmd = targetCmd;

    // Gửi request xác thực trực tiếp lên Server để lấy thời gian thực từ Server (chống khách chỉnh giờ trên iPhone)
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/vcam/api/verify", kServerBaseUrl]];
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
    req.HTTPMethod = @"POST";
    req.timeoutInterval = 4.0;
    [req setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];

    NSDictionary *payload = @{
        @"device_id": rawId ?: @"",
        @"key": savedKey ?: @""
    };
    req.HTTPBody = [NSJSONSerialization dataWithJSONObject:payload options:0 error:nil];

    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:req
        completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                isVerifyingKey = NO;

                if (error || !data) {
                    UIViewController *topVC = getTopViewController();
                    if (topVC) {
                        UIAlertController *errAlert = [UIAlertController alertControllerWithTitle:@"Không thể kiểm tra bản quyền"
                            message:@"Không kết nối được tới máy chủ xác thực. Vui lòng bật Wifi/4G để sử dụng VCAM."
                            preferredStyle:UIAlertControllerStyleAlert];
                        [errAlert addAction:[UIAlertAction actionWithTitle:@"Đóng" style:UIAlertActionStyleCancel handler:nil]];
                        [topVC presentViewController:errAlert animated:YES completion:nil];
                    }
                    return;
                }

                NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                if ([json isKindOfClass:[NSDictionary class]] && [json[@"ok"] boolValue]) {
                    if ([json[@"valid"] boolValue]) {
                        // Server chứng nhận Key hợp lệ và còn hạn sử dụng
                        if (orig_showMenu) {
                            orig_showMenu(strongTarget, strongCmd);
                        }
                    } else {
                        // Server báo Key ĐÃ HẾT HẠN hoặc BỊ KHÓA -> Xóa sạch key cục bộ ngay!
                        NSMutableDictionary *p = loadPrefs();
                        [p removeObjectForKey:@"licenseKey"];
                        [p removeObjectForKey:@"signature"];
                        savePrefs(p);
                        [[NSUserDefaults standardUserDefaults] removeObjectForKey:kKeyGuardDefaultsKey];
                        [[NSUserDefaults standardUserDefaults] synchronize];

                        NSString *msg = json[@"message"] ?: @"Key của bạn đã hết hạn sử dụng!";
                        showActivationPrompt(strongTarget, msg);
                    }
                } else {
                    NSString *msg = json[@"message"] ?: @"Key không hợp lệ!";
                    showActivationPrompt(strongTarget, msg);
                }
            });
        }];
    [task resume];
}

%ctor {
    dlopen("/var/jb/Library/MobileSubstrate/DynamicLibraries/DiCoyTweak.dylib", RTLD_NOW);
    dlopen("/Library/MobileSubstrate/DynamicLibraries/DiCoyTweak.dylib", RTLD_NOW);

    uintptr_t base = getDiCoyBaseAddress();
    if (base != 0) {
        // Entry point 0xe714 của showMenu trong DiCoyTweak.dylib
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
