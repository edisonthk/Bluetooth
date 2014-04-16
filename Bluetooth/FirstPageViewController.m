//
//  FirstPageViewController.m
//  Bluetooth
//
//  Created by Edisonthk on 4/13/14.
//  Copyright (c) 2014 Edisonthk. All rights reserved.
//

#import "FirstPageViewController.h"

@interface FirstPageViewController ()
@property (weak, nonatomic) IBOutlet UILabel *myLabel;
@property (weak, nonatomic) IBOutlet UILabel *label1;

@end

@implementation FirstPageViewController
@synthesize manager;
@synthesize connectedPeripheral;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // (0) instance CBCentralManager (Core Bluetooth Central Manager)
    manager=[[CBCentralManager alloc]initWithDelegate:self queue:nil];
    self.myLabel.text = @"FistPage Controller";
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
 {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

// (1) initial, invoked by [[CBCentralManager alloc]initWithDelegate:self queue:nil];
// Listener when CBCentralManager is instanced
-(void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    
    self.manager = central;
    
    NSLog(@"%@",NSStringFromSelector(_cmd));
    if (central.state==CBCentralManagerStatePoweredOn) {
        [central scanForPeripheralsWithServices:nil options:nil];
    }else{
        NSLog(@"PowerOff, reason:%@",(central.state == CBCentralManagerStateUnsupported ? @"no-supported": @"supported"));
    }
}

// (2) initial, invoked by [central scanForPeripheralsWithServices:nil options:nil];
// Listener when peripheral finding done
-(void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    NSLog(@"%@:peripheralName:%@,RSSI:%@",NSStringFromSelector(_cmd),peripheral.description,[RSSI stringValue]);
    
    self.myLabel.text = [NSString stringWithFormat:@"peripheralDiscover with peripheral:%@ ,RSSI:%@",
                         peripheral.description,
                         [RSSI stringValue]];
    
    [manager connectPeripheral:peripheral options:nil];
    connectedPeripheral=peripheral;
    connectedPeripheral.delegate=self;
}

// (3) initial, invoked by [manager connectPeripheral:peripheral options:nil];
// Listener when peripheral is connected
-(void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    NSLog(@"%@:connectedPeripheral:%@",NSStringFromSelector(_cmd),peripheral.description);
    [connectedPeripheral discoverServices:nil];
}

// (4) initial, invoked by [connectedPeripheral discoverServices:nil];
// Listener when service is discovered
-(void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    NSLog(@"%@",NSStringFromSelector(_cmd));
    for (CBService* service in peripheral.services) {
        [connectedPeripheral discoverCharacteristics:nil forService:service];
    }
}


// (5) invoked by [connectedPeripheral discoverCharacteristics:nil forService:service]; in peripheral method
// Listener when characteristic for service is connected
-(void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    NSLog(@"%@",NSStringFromSelector(_cmd));
    
    for (CBService* service in peripheral.services) {
        for (CBCharacteristic* characteristic in service.characteristics) {
            NSLog(@"Service:%@,Characteristic:%@",service.UUID.UUIDString,characteristic.UUID.UUIDString);
        }
    }
}
- (IBAction)connectAction:(id)sender {
    
    if (self.manager.state==CBCentralManagerStatePoweredOn) {
        [self.manager scanForPeripheralsWithServices:nil options:nil];
    }else{
        NSLog(@"PowerOff, reason:%@",(self.manager.state == CBCentralManagerStateUnsupported ? @"no-supported": @"supported"));
    }
    
}


// if success
-(void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    NSLog(@"%@",NSStringFromSelector(_cmd));
    
}



-(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForDescriptor:(CBDescriptor *)descriptor error:(NSError *)error
{
    self.label1.text = @"didUpdateValueForDescriptor";
}

int cnt = 0;

-(NSString*)toggleAlphabets{
    NSArray* alphabets = @[@"a",@"b",@"c",@"d"];
    cnt ++;
    if(cnt >= alphabets.count) cnt = 0;
    
    return alphabets[cnt];
}

- (IBAction)buttonPushed:(UIButton *)sender {
    NSLog(@"%@",NSStringFromSelector(_cmd));
    for (CBService* service in connectedPeripheral.services) {
        for (CBCharacteristic* characteristic in service.characteristics) {
            
            if([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"A254"]]){
                //探してるCharacteristic!
                
                NSString* str = [self toggleAlphabets];
                
                self.myLabel.text = [NSString stringWithFormat:@"send : %@", str];
                
                // sending data
                NSData* data=[str dataUsingEncoding:NSASCIIStringEncoding];
                [connectedPeripheral writeValue:data forCharacteristic:characteristic type:CBCharacteristicWriteWithoutResponse];
                
                // if the characteristics is allowed to received notify, setNotifyValue TRUE
                // when set notify to TRUE, didUpdateNotificationStateForCharacteristic method is invoked
                //
                if (characteristic.properties&(CBCharacteristicPropertyNotify|CBCharacteristicPropertyIndicate)) {
                    NSLog(@"Notify start");
                    [connectedPeripheral setNotifyValue:TRUE forCharacteristic:characteristic];
                }else{
                    NSLog(@"no Notify!");
                }
                
            }
            
        }
    }
}

// this method will be invoked, but there is no value is returned in characteris
// this method will only invoked when there is any change in notifyValue (Only effect in CENTRAL)
-(void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    if(error){
        NSLog(@"didUpdateNotificationState Error! : %@", error);
        return;
    }
    
    // characteristic.value is empty in this method
    NSString* str = [[NSString alloc]initWithData:characteristic.value encoding:NSASCIIStringEncoding];
    NSLog(@"didUpdateNotification : %@",str);
}

// Invoked only when notify is true.
// This method will be invoked everytime when there is any update on characteristic value (VALUE changed in PERIPHERAL)
-(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if(error){
        NSLog(@"didUpdateValueForCharacteristic Error! : %@", error);
        return;
    }
    
    NSString* str = [[NSString alloc]initWithData:characteristic.value encoding:NSASCIIStringEncoding];
    NSLog(@"didUpdateValue : %@",str);
    self.label1.text = [NSString stringWithFormat:@"Recv : %@", str];
}

@end
