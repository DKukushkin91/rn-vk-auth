#import "RnVkAuth.h"
#import "rn_vk_auth-Swift.h"

@implementation RnVkAuth {
  RnVkAuthImpl *moduleImpl;
}

- (instancetype) init {
  self = [super init];

  if (self) {
    moduleImpl = [RnVkAuthImpl new];
  }

  return self;
}

RCT_EXPORT_MODULE()

- (std::shared_ptr<facebook::react::TurboModule>)getTurboModule:
    (const facebook::react::ObjCTurboModule::InitParams &)params
{
    return std::make_shared<facebook::react::NativeRnVkAuthSpecJSI>(params);
}

- (void)initialize:(JS::NativeRnVkAuth::IInitializeParams &)params
           resolve:(RCTPromiseResolveBlock)resolve
            reject:(RCTPromiseRejectBlock)reject {
    NSString *clientId = params.clientId();
    NSString *clientSecret = params.clientSecret();
    bool loggingEnabled = params.loggingEnabled();

    NSDictionary *paramsDict = @{
        @"clientId": clientId,
        @"clientSecret": clientSecret,
        @"loggingEnabled": [NSNumber numberWithBool:loggingEnabled]
    };

  [moduleImpl initialize:paramsDict resolve:^(NSDictionary * _Nonnull result) {
    resolve(result);
  } reject:^(NSString * _Nullable code, NSString * _Nullable message, NSError * _Nullable error) {
    reject(code, message, error);
  }];
}

- (void)toggleOneTapBottomSheet:(JS::NativeRnVkAuth::IToggleOneTapBottomSheetParams &)params
                       fetchApi:(RCTResponseSenderBlock)fetchApi
                        resolve:(RCTPromiseResolveBlock)resolve
                         reject:(RCTPromiseRejectBlock)reject {
  NSString *serviceName = params.serviceName();
  facebook::react::LazyVector<NSString *> scope = params.scope();
  double cornerRadius = params.cornerRadius();
  bool autoDismissOnSuccess = params.autoDismissOnSuccess();
  
  NSMutableArray<NSString *> *scopeArray = [NSMutableArray arrayWithCapacity:scope.size()];
  
  for (size_t i=0; i < scope.size(); i++) {
    NSString *value = scope.at(i);
    
    if (value != nil) {
      [scopeArray addObject:value];
    }
  }
  
  NSDictionary *paramsDict = @{
      @"serviceName": serviceName,
      @"scope": scopeArray,
      @"cornerRadius": @(cornerRadius),
      @"autoDismissOnSuccess": [NSNumber numberWithBool:autoDismissOnSuccess]
  };
  
  [moduleImpl toggleOneTapBottomSheet:paramsDict
                             fetchApi:^(NSArray * _Nonnull result) {
    fetchApi(result);
  } resolve:^(NSDictionary * _Nonnull result) {
    resolve(result);
  } reject:^(NSString * _Nullable code, NSString * _Nullable message, NSError * _Nullable error) {
    reject(code, message, error);
  }];
}

- (void)logout:(RCTPromiseResolveBlock)resolve
        reject:(RCTPromiseRejectBlock)reject {
  [moduleImpl logoutWithResolve:^(NSDictionary * _Nonnull result) {
    resolve(result);
  } reject:^(NSString * _Nullable code, NSString * _Nullable message, NSError * _Nullable error) {
    reject(code, message, error);
  }];
}

@end
