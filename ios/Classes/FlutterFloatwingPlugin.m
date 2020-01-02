#import "FlutterFloatwingPlugin.h"
#if __has_include(<flutter_floatwing/flutter_floatwing-Swift.h>)
#import <flutter_floatwing/flutter_floatwing-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "flutter_floatwing-Swift.h"
#endif

@implementation FlutterFloatwingPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftFlutterFloatwingPlugin registerWithRegistrar:registrar];
}
@end
