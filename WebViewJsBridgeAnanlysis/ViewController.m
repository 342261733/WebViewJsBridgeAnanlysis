
//  ViewController.m
//  WebViewJsBridgeAnanlysis
//
//  Created by Semyon on 17/1/5.
//  Copyright © 2017年 Semyon. All rights reserved.
//

#import "ViewController.h"
#import "WebViewJavascriptBridge.h"
#import <objc/runtime.h>

@interface ViewController () <UIWebViewDelegate> {
    UIWebView *_webView;
}

@property WebViewJavascriptBridge *bridge;
@property WebViewJavascriptBridgeBase *base;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    _webView = [[UIWebView alloc] init];
    _webView.frame = self.view.frame;
    [self.view addSubview:_webView];
    
    NSString *strJsBundlePath = [[NSBundle mainBundle] pathForResource:@"jsbridge" ofType:@"html"]; // ExampleApp // jsbridge 
    NSURL *url = [NSURL URLWithString:strJsBundlePath]; // @"https://www.baidu.com"
    NSURLRequest *urlRequest = [[NSURLRequest alloc] initWithURL:url];
    [_webView loadRequest:urlRequest];

    [self setupWVJSBridge];
    
    [self injectJSBridgeBase]; // OC 主动注入js
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)injectJSBridgeBase {
    unsigned int count = 0;
    Ivar *members = class_copyIvarList([_bridge class], &count);
    for (int i=0; i<count; i++) {
        Ivar var = members[i];
        const char * memberName = ivar_getName(var);
        const char * memberType = ivar_getTypeEncoding(var);
        NSLog(@"memberName:%s ----- memberType:%s",memberName,memberType);
        NSString *strMemberType = [NSString stringWithFormat:@"%s", memberType];
        if ([strMemberType rangeOfString:@"WebViewJavascriptBridgeBase"].location != NSNotFound) {
            _base = object_getIvar(_bridge, var);
            break;
        }
    }
    free(members);
}

- (void)setupWVJSBridge {
    [WebViewJavascriptBridge enableLogging];
    _bridge = [WebViewJavascriptBridge bridgeForWebView:_webView];
    [_bridge setWebViewDelegate:self]; // 设置代理，使得self具有捕获webview回调的能力
    [self setupJSOCHybird];
}

- (void)setupJSOCHybird {
    [_bridge registerHandler:@"Hybird" handler:^(id data, WVJBResponseCallback responseCallback) {
        NSLog(@"data %@ responseCallBack %@", data, responseCallback);
        NSDictionary* dicResult = @{@"ret":@"OK"}; // js 会自动解析json格式
        responseCallback(dicResult);
    }];
    
    [_bridge callHandler:@"invokeJavascriptHandler" data:@{ @"say":@"Hello" } responseCallback:^(id responseData) {
        NSLog(@"OC get call back from js when OC invoke %@", responseData);
    }];
}

#pragma mark - UIWebview delegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    NSLog(@"--- %@ , type %lu", request, navigationType);
    return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
    NSLog(@"webViewDidStartLoad %@", webView);
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    NSLog(@"webViewDidFinishLoad %@", webView);

    [self injectJSBridge];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    [webView stringByEvaluatingJavaScriptFromString:@"alert('Hi')"];
    NSLog(@"didFailLoadWithError %@", error);
}

- (void)injectJSBridge {
    [_base performSelector:@selector(injectJavascriptFile)];
}

@end
