//
//  NqwlBluetooth.m
//  BabyBluetoothDemo
//
//  Created by 亲点 on 2018/1/10.
//  Copyright © 2018年 陈辉. All rights reserved.
//

#import "NqwlBluetooth.h"
#import "BabyBluetooth.h"


@implementation NqwlBluetooth {
    BabyBluetooth *currentBluetooth;
    NSMutableArray *curCBPeripheralArray;
    NSString *curConnectedBluetoothUUID;
    id<NqwlBluetoothDelegate> curDelegate;
    CBCentralManagerState currentBluetoothState;
}
static NqwlBluetooth *theSharedInstance = nil;
+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        theSharedInstance = [[self alloc] init];
    });
    return theSharedInstance;
}

+ (id)allocWithZone:(struct _NSZone *)zone
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        theSharedInstance = [super allocWithZone:zone];
    });
    return theSharedInstance;
}

+ (id)copyWithZone:(NSZone *)zone {
    return self;
}
+ (id)mutableCopyWithZone:(NSZone *)zone {
    return self;
}
- (id)init {
    self = [super init];
    [self initManager];
    return self;
}
- (void)initManager {
    curCBPeripheralArray = [[NSMutableArray alloc] init];
    currentBluetooth = [BabyBluetooth shareBabyBluetooth];
    [self setBluetoothDelegate];
    currentBluetooth.scanForPeripherals().begin();
}
#define BluetoothChannel @"channel"
- (BOOL)checkBluetoothState {
    BOOL state =  currentBluetoothState == CBCentralManagerStatePoweredOn;
    return state;
}
- (void)setDelegate:(id<NqwlBluetoothDelegate>)delegate {
    curDelegate = delegate;
}
- (void)onScan {
    if([self checkBluetoothState]) {
        currentBluetooth.scanForPeripherals().connectToPeripherals().discoverServices().discoverCharacteristics().readValueForCharacteristic().discoverDescriptorsForCharacteristic().readValueForDescriptors().begin();
    }
}
- (void)onCancelScan {
    [currentBluetooth cancelScan];
}
- (BOOL)onConnectTo:(NSString *)uuid {
    BOOL found = NO;
    if([self checkBluetoothState]) {
        curConnectedBluetoothUUID = uuid;
        if(curCBPeripheralArray.count>0) {
            for (int i = 0; i<curCBPeripheralArray.count; i++) {
                CBPeripheral *per = [curCBPeripheralArray objectAtIndex:i];
                if([per.identifier.UUIDString isEqualToString:curConnectedBluetoothUUID]) {
                    [currentBluetooth cancelScan];
                    currentBluetooth.having([curCBPeripheralArray objectAtIndex:0]).and.channel(BluetoothChannel).then.connectToPeripherals().discoverServices().discoverCharacteristics().readValueForCharacteristic().discoverDescriptorsForCharacteristic().readValueForDescriptors().begin();
                    found = YES;
                    break;
                }
            }
        }
    }
    return found;
}
- (void)onDisconnect {
    [self setDelegate:nil];
    [curCBPeripheralArray removeAllObjects];
    [currentBluetooth cancelScan];
    [currentBluetooth cancelAllPeripheralsConnection];
    [currentBluetooth stop];
}
- (void)onWriteMessage:(NSString *)message {
    if([self checkBluetoothState]) {
        for(int i = 0;i<curCBPeripheralArray.count;i++) {
            CBPeripheral *per = [curCBPeripheralArray objectAtIndex:i];
            CBCharacteristic *cbCha = nil;
            NSData *data = [message dataUsingEncoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000)];
            if([per.identifier.UUIDString isEqualToString:curConnectedBluetoothUUID]) {
                for (int a = 0; a<per.services.count; a++) {
                    CBService *service = [per.services objectAtIndex:a];
                    for (int b = 0; b<service.characteristics.count; b++) {
                        CBCharacteristic *cbchar = [service.characteristics objectAtIndex:b];
                        if(cbchar.properties& CBCharacteristicPropertyWrite) {
                            cbCha = cbchar;
                            break;
                        }
                    }
                }
            }
            if(cbCha) {
                NSLog(@"%@",message);
                [per writeValue:data forCharacteristic:cbCha type:CBCharacteristicWriteWithResponse];
            }
        }
    }
}
- (void)onDiscovedNewPeripheral:(CBPeripheral *)peripheral {
    NSString *uuidStr  = @"";
    if(peripheral.identifier&&peripheral.identifier.UUIDString) {
        uuidStr = peripheral.identifier.UUIDString;
    }
    BOOL found = NO;
    for (int i = 0; i<curCBPeripheralArray.count; i++) {
        CBPeripheral *per = [curCBPeripheralArray objectAtIndex:i];
        NSString *uuid = @"";
        if(per.identifier&&per.identifier.UUIDString) {
            uuid = per.identifier.UUIDString;
        }
        if([uuidStr isEqualToString:uuid]) {
            found = YES;
            break;
        }
    }
    if(!found) {
        if(curDelegate) {
            [curDelegate onScannedWithNewDevice:peripheral];
        }
        [curCBPeripheralArray addObject:peripheral];
    }
}
- (void)onClearCachedPeripheralsAndScan {
    if([self checkBluetoothState]) {
        [curCBPeripheralArray removeAllObjects];
        [self onScan];
    }
}
//
- (void)delegateForConnected:(NSString *)uuid {
    if(curDelegate) {
        [curDelegate onConnectedTo:uuid];
    }
}
- (void)delegateForFailedToConnect:(NSString *)uuid {
    if(curDelegate) {
        [curDelegate onFailedToConnect:uuid];
    }
}
- (void)delegateForDisconnected:(NSString *)uuid {
    if(curDelegate) {
        [curDelegate onDisconnectedTo:uuid];
    }
}
- (void)delegateForWriteSucceed {
    if(curDelegate) {
        [curDelegate onWriteSucceed];
    }
}
- (void)delegateForReadCharacteristic:(NSString *)value {
    if(curDelegate) {
        [curDelegate onReadCharacteristic:value];
    }
}
//设置蓝牙委托
- (void)setBluetoothDelegate {
    __weak typeof(self)weakSelf = self;
    //
    NSDictionary *scanForPeripheralsWithOptions = @ {CBCentralManagerScanOptionAllowDuplicatesKey:@NO};
    /*连接选项- >
     CBConnectPeripheralOptionNotifyOnConnectionKey :当应用挂起时，如果有一个连接成功时，如果我们想要系统为指定的peripheral显示一个提示时，就使用这个key值。
     CBConnectPeripheralOptionNotifyOnDisconnectionKey :当应用挂起时，如果连接断开时，如果我们想要系统为指定的peripheral显示一个断开连接的提示时，就使用这个key值。
     CBConnectPeripheralOptionNotifyOnNotificationKey:
     当应用挂起时，使用该key值表示只要接收到给定peripheral端的通知就显示一个提
     */
    NSDictionary *connectOptions = @ {CBConnectPeripheralOptionNotifyOnConnectionKey:@YES,
                                     CBConnectPeripheralOptionNotifyOnDisconnectionKey:@YES,
                                     CBConnectPeripheralOptionNotifyOnNotificationKey:@YES};
    [currentBluetooth setBabyOptionsAtChannel:BluetoothChannel scanForPeripheralsWithOptions:scanForPeripheralsWithOptions connectPeripheralWithOptions:connectOptions scanForPeripheralsWithServices:nil discoverWithServices:nil discoverWithCharacteristics:nil];
    //设置监听到蓝牙状态的委托
    [currentBluetooth setBlockOnCentralManagerDidUpdateState:^(CBCentralManager *central) {
        currentBluetoothState = central.state;
    }];
    //设置扫描到设备的委托
    [currentBluetooth setBlockOnDiscoverToPeripherals:^(CBCentralManager *central, CBPeripheral *peripheral, NSDictionary *advertisementData, NSNumber *RSSI) {
        NSLog(@"搜索到了设备:%@",peripheral.name);
        [weakSelf onDiscovedNewPeripheral:peripheral];
    }];
    //设备连接成功的委托
    [currentBluetooth setBlockOnConnectedAtChannel:BluetoothChannel block:^(CBCentralManager *central, CBPeripheral *peripheral) {
        NSLog(@"设备：%@- - 连接成功",peripheral.name);
        if(peripheral.identifier&&peripheral.identifier.UUIDString) {
            [weakSelf delegateForConnected:peripheral.identifier.UUIDString];
        }
    }];
    //设置设备连接失败的委托
    [currentBluetooth setBlockOnFailToConnectAtChannel:BluetoothChannel block:^(CBCentralManager *central, CBPeripheral *peripheral, NSError *error) {
        NSLog(@"设备：%@- - 连接失败",peripheral.name);
        if(peripheral.identifier&&peripheral.identifier.UUIDString) {
            [weakSelf delegateForFailedToConnect:peripheral.identifier.UUIDString];
        }
    }];
    //设置设备断开连接的委托
    [currentBluetooth setBlockOnDisconnectAtChannel:BluetoothChannel block:^(CBCentralManager *central, CBPeripheral *peripheral, NSError *error) {
        NSLog(@"设备：%@- - 断开连接",peripheral.name);
        if(peripheral.identifier&&peripheral.identifier.UUIDString) {
            [weakSelf delegateForDisconnected:peripheral.identifier.UUIDString];
        }
    }];
    [currentBluetooth setBlockOnCancelAllPeripheralsConnectionBlock:^(CBCentralManager *centralManager) {
        NSLog(@"取消所有连接 setBlockOnCancelAllPeripheralsConnectionBlock");
    }];

    [currentBluetooth setBlockOnCancelScanBlock:^(CBCentralManager *centralManager) {
        NSLog(@"取消扫描 setBlockOnCancelScanBlock");
    }];
    //设置写数据成功的block
    [currentBluetooth setBlockOnDidWriteValueForCharacteristicAtChannel:BluetoothChannel block:^(CBCharacteristic *characteristic, NSError *error) {
        //        NSLog(@"写数据成功 setBlockOnDidWriteValueForCharacteristicAtChannel characteristic:%@ and new value:%@",characteristic.UUID, characteristic.value);
        if(error) {
            NSLog(@"%@",error.localizedDescription);
        }else {
            [weakSelf delegateForWriteSucceed];
        }
    }];
    //    设置读取characteristics的委托
    [currentBluetooth setBlockOnReadValueForCharacteristic:^(CBPeripheral *peripheral, CBCharacteristic *characteristics, NSError *error) {
        NSLog(@"characteristic name:%@ value is:%@",characteristics.UUID,characteristics.value);
        if (error) {
            NSLog(@"%@",error.localizedDescription);
        }else {
            [weakSelf delegateForReadCharacteristic:[NSString stringWithFormat:@"%@",characteristics.value]];
        }
    }];

    //设置发现characteristics的descriptors的委托
    //    [currentBluetooth setBlockOnDiscoverDescriptorsForCharacteristic:^(CBPeripheral *peripheral, CBCharacteristic *characteristic, NSError *error) {
    //        NSLog(@" = = = characteristic name:%@",characteristic.service.UUID);
    //        for (CBDescriptor *d in characteristic.descriptors) {
    //            NSLog(@"CBDescriptor name is :%@",d.UUID);
    //        }
    //    }];

    //设置读取Descriptor的委托
    //    [currentBluetooth setBlockOnReadValueForDescriptors:^(CBPeripheral *peripheral, CBDescriptor *descriptor, NSError *error) {
    //        NSLog(@"Descriptor name:%@ value is:%@",descriptor.characteristic.UUID, descriptor.value);
    //    }];

    //设置查找设备的过滤器
    //    [currentBluetooth setFilterOnDiscoverPeripherals:^BOOL(NSString *peripheralName) {
    //        //设置查找规则是名称大于1 ， the search rule is peripheral.name length > 1
    //        if (peripheralName.length >1) {
    //            return YES;
    //        }
    //        return NO;
    //    }];

    //设置发现设备的Services的委托
    //    [currentBluetooth setBlockOnDiscoverServices:^(CBPeripheral *peripheral, NSError *error) {
    //    }];

    //设置发现设service的Characteristics的委托
    //    [currentBluetooth setBlockOnDiscoverCharacteristics:^(CBPeripheral *peripheral, CBService *service, NSError *error) {
    //        NSLog(@" = = = service name:%@",service.UUID);
    //        for (CBCharacteristic *c in service.characteristics) {
    //            NSLog(@"charateristic name is :%@",c.UUID);
    //        }
    //    }];
}
@end
