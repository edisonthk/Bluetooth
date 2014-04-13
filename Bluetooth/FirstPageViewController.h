//
//  FirstPageViewController.h
//  Bluetooth
//
//  Created by Edisonthk on 4/13/14.
//  Copyright (c) 2014 Edisonthk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>

@interface FirstPageViewController : UIViewController<CBCentralManagerDelegate,CBPeripheralDelegate>{
    CBCentralManager* manager;
    CBPeripheral* connectedPeripheral;
}
@property CBCentralManager* manager;
@property CBPeripheral* connectedPeripheral;
@end
