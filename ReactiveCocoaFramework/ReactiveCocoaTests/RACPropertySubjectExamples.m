//
//  RACPropertySubjectExamples.m
//  ReactiveCocoa
//
//  Created by Uri Baghin on 30/12/2012.
//  Copyright (c) 2012 GitHub, Inc. All rights reserved.
//

#import "RACPropertySubjectExamples.h"

#import "NSObject+RACDeallocating.h"
#import "NSObject+RACPropertySubscribing.h"
#import "RACBinding.h"
#import "RACCompoundDisposable.h"
#import "RACDisposable.h"
#import "RACPropertySubject.h"

NSString * const RACPropertySubjectExamples = @"RACPropertySubjectExamples";
NSString * const RACPropertySubjectExampleGetPropertyBlock = @"RACPropertySubjectExampleGetPropertyBlock";

SharedExampleGroupsBegin(RACPropertySubjectExamples)

sharedExamplesFor(RACPropertySubjectExamples, ^(NSDictionary *data) {
	__block RACPropertySubject *(^getProperty)(void);
	__block RACPropertySubject *property;
	id value1 = @"test value 1";
	id value2 = @"test value 2";
	id value3 = @"test value 3";
	NSArray *values = @[ value1, value2, value3 ];
	
	before(^{
		getProperty = data[RACPropertySubjectExampleGetPropertyBlock];
		property = getProperty();
	});
	
	it(@"should send its current value on subscription", ^{
		__block id receivedValue = nil;
		[property sendNext:value1];
		[[property take:1] subscribeNext:^(id x) {
			receivedValue = x;
		}];
		expect(receivedValue).to.equal(value1);
		
		[property sendNext:value2];
		[[property take:1] subscribeNext:^(id x) {
			receivedValue = x;
		}];
		expect(receivedValue).to.equal(value2);
	});
	
	it(@"should send its value as it changes", ^{
		[property sendNext:value1];
		NSMutableArray *receivedValues = [NSMutableArray array];
		[property subscribeNext:^(id x) {
			[receivedValues addObject:x];
		}];
		[property sendNext:value2];
		[property sendNext:value3];
		expect(receivedValues).to.equal(values);
	});

	it(@"should complete manually", ^{
		__block BOOL completed = NO;
		[property subscribeCompleted:^{
			completed = YES;
		}];

		[property sendCompleted];
		expect(completed).to.beTruthy();
	});
	
	describe(@"memory management", ^{
		it(@"should dealloc when its subscribers are disposed", ^{
			RACDisposable *disposable = nil;
			__block BOOL deallocd = NO;
			@autoreleasepool {
				RACPropertySubject *property __attribute__((objc_precise_lifetime)) = getProperty();
				[property.rac_deallocDisposable addDisposable:[RACDisposable disposableWithBlock:^{
					deallocd = YES;
				}]];
				disposable = [property subscribeNext:^(id x) {}];
			}
			[disposable dispose];
			expect(deallocd).will.beTruthy();
		});
		
		it(@"should dealloc when its subscriptions are disposed", ^{
			RACDisposable *disposable = nil;
			__block BOOL deallocd = NO;
			@autoreleasepool {
				RACPropertySubject *property __attribute__((objc_precise_lifetime)) = getProperty();
				[property.rac_deallocDisposable addDisposable:[RACDisposable disposableWithBlock:^{
					deallocd = YES;
				}]];
				disposable = [RACSignal.never subscribe:property];
			}
			[disposable dispose];
			expect(deallocd).will.beTruthy();
		});
		
		it(@"should dealloc when its binding's subscribers are disposed", ^{
			RACDisposable *disposable = nil;
			__block BOOL deallocd = NO;
			@autoreleasepool {
				RACPropertySubject *property __attribute__((objc_precise_lifetime)) = getProperty();
				[property.rac_deallocDisposable addDisposable:[RACDisposable disposableWithBlock:^{
					deallocd = YES;
				}]];
				disposable = [[property binding] subscribeNext:^(id x) {}];
			}
			[disposable dispose];
			expect(deallocd).will.beTruthy();
		});
		
		it(@"should dealloc when its binding's subscriptions are disposed", ^{
			RACDisposable *disposable = nil;
			__block BOOL deallocd = NO;
			@autoreleasepool {
				RACPropertySubject *property __attribute__((objc_precise_lifetime)) = getProperty();
				[property.rac_deallocDisposable addDisposable:[RACDisposable disposableWithBlock:^{
					deallocd = YES;
				}]];
				disposable = [RACSignal.never subscribe:[property binding]];
			}
			[disposable dispose];
			expect(deallocd).will.beTruthy();
		});
		
		it(@"should dealloc if its binding with other properties is disposed", ^{
			RACDisposable *disposable1 = nil;
			RACDisposable *disposable2 = nil;
			__block BOOL deallocd1 = NO;
			__block BOOL deallocd2 = NO;
			@autoreleasepool {
				RACPropertySubject *property1 __attribute__((objc_precise_lifetime)) = getProperty();
				RACPropertySubject *property2 __attribute__((objc_precise_lifetime)) = getProperty();
				[property1.rac_deallocDisposable addDisposable:[RACDisposable disposableWithBlock:^{
					deallocd1 = YES;
				}]];
				[property2.rac_deallocDisposable addDisposable:[RACDisposable disposableWithBlock:^{
					deallocd2 = YES;
				}]];
				RACBinding *property1Binding = [property1 binding];
				RACBinding *property2Binding = [property2 binding];
				disposable1 = [property2Binding subscribe:property1Binding];
				disposable2 = [property1Binding subscribe:property2Binding];
			}
			[disposable1 dispose];
			[disposable2 dispose];
			expect(deallocd1).will.beTruthy();
			expect(deallocd2).will.beTruthy();
		});
	});
	
	describe(@"bindings", ^{
		__block RACBinding *binding1;
		__block RACBinding *binding2;
		
		before(^{
			binding1 = [property binding];
			binding2 = [property binding];
		});
		
		it(@"should send the property's current value on subscription", ^{
			__block id receivedValue = nil;
			[property sendNext:value1];
			[[binding1 take:1] subscribeNext:^(id x) {
				receivedValue = x;
			}];
			expect(receivedValue).to.equal(value1);
			
			[property sendNext:value2];
			[[binding1 take:1] subscribeNext:^(id x) {
				receivedValue = x;
			}];
			expect(receivedValue).to.equal(value2);
		});
		
		it(@"should send the current value on subscription even if it was set by itself", ^{
			__block id receivedValue = nil;
			[binding1 sendNext:value1];
			[[binding1 take:1] subscribeNext:^(id x) {
				receivedValue = x;
			}];
			expect(receivedValue).to.equal(value1);
			
			[binding1 sendNext:value2];
			[[binding1 take:1] subscribeNext:^(id x) {
				receivedValue = x;
			}];
			expect(receivedValue).to.equal(value2);
		});
		
		it(@"should send the property's value as it changes if it was set by the property", ^{
			[property sendNext:value1];
			NSMutableArray *receivedValues = [NSMutableArray array];
			[binding1 subscribeNext:^(id x) {
				[receivedValues addObject:x];
			}];
			[property sendNext:value2];
			[property sendNext:value3];
			expect(receivedValues).to.equal(values);
		});
		
		it(@"should not send the property's value as it changes if it was set by itself", ^{
			[property sendNext:value1];
			NSMutableArray *receivedValues = [NSMutableArray array];
			[binding1 subscribeNext:^(id x) {
				[receivedValues addObject:x];
			}];
			[binding1 sendNext:value2];
			[binding1 sendNext:value3];
			expect(receivedValues).to.equal(@[ value1 ]);
		});
		
		it(@"should send the property's value as it changes if it was set by another binding", ^{
			[property sendNext:value1];
			NSMutableArray *receivedValues1 = [NSMutableArray array];
			[binding1 subscribeNext:^(id x) {
				[receivedValues1 addObject:x];
			}];
			NSMutableArray *receivedValues2 = [NSMutableArray array];
			[binding2 subscribeNext:^(id x) {
				[receivedValues2 addObject:x];
			}];
			[binding1 sendNext:value2];
			[binding2 sendNext:value3];
			NSArray *expectedValues1 = @[ value1, value3 ];
			NSArray *expectedValues2 = @[ value1, value2 ];
			expect(receivedValues1).to.equal(expectedValues1);
			expect(receivedValues2).to.equal(expectedValues2);
		});

		it(@"should set the property's value to values it's sent", ^{
			__block id receivedValue = nil;
			[binding1 sendNext:value1];
			[[property take:1] subscribeNext:^(id x) {
				receivedValue = x;
			}];
			expect(receivedValue).to.equal(value1);
			
			[binding1 sendNext:value2];
			[[property take:1] subscribeNext:^(id x) {
				receivedValue = x;
			}];
			expect(receivedValue).to.equal(value2);
		});

		it(@"should complete when the property completes", ^{
			__block BOOL completed = NO;
			[binding1 subscribeCompleted:^{
				completed = YES;
			}];

			[property sendCompleted];
			expect(completed).to.beTruthy();
		});

		it(@"should complete manually", ^{
			__block BOOL completed = NO;
			[binding1 subscribeCompleted:^{
				completed = YES;
			}];

			[binding1 sendCompleted];
			expect(completed).to.beTruthy();
		});

		it(@"should complete its property", ^{
			__block BOOL completed = NO;
			[property subscribeCompleted:^{
				completed = YES;
			}];

			[binding1 sendCompleted];
			expect(completed).to.beTruthy();
		});
	});
});

SharedExampleGroupsEnd
