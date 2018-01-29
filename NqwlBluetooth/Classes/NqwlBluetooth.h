//
//  NqwlBluetooth.h
//  BabyBluetoothDemo
//
//  Created by 亲点 on 2018/1/10.
//  Copyright © 2018年 陈辉. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

#define BlueToothPrint @"BluetoothPrint"

@protocol NqwlBluetoothDelegate<NSObject>
-(void) onScannedWithNewDevice:(CBPeripheral *) peripheral;
-(void) onConnectedTo:(NSString *) uuid;
-(void) onFailedToConnect:(NSString *) uuid;
-(void) onDisconnectedTo:(NSString *) uuid;
-(void) onWriteSucceed;
-(void) onReadCharacteristic:(NSString *)value;
@end

@interface NqwlBluetooth : NSObject
+(NqwlBluetooth *) sharedInstance;
-(void) setDelegate:(id<NqwlBluetoothDelegate>) delegate;
-(void) onScan;
-(void) onCancelScan;
-(BOOL) onConnectTo:(NSString *) uuid;
-(void) onWriteMessage:(NSString *) message;
-(void) onClearCachedPeripheralsAndScan;
-(void) onDisconnect;
@end

