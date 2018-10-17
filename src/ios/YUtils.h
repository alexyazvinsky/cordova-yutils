#import <Cordova/CDVPlugin.h>

@interface YUtils : CDVPlugin

- (void)getDeviceName:(CDVInvokedUrlCommand*)command;

- (void)promptPin:(CDVInvokedUrlCommand*)command;

- (void)validatePin:(CDVInvokedUrlCommand*)command;

- (void)presentAlertOnCurrentViewController:(UIAlertController*)alert;

- (void)setFieldFocus;

- (void)showAlertWithMessage:(NSString *)message
                   andComand:(CDVInvokedUrlCommand *)command
              andIsValidated:(bool)isValidated;

@property(nonatomic, strong) UITextField * pinField;

@end
