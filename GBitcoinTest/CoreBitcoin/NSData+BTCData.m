// Oleg Andreev <oleganza@gmail.com>

#import "NSData+BTCData.h"
#import <CommonCrypto/CommonCrypto.h>

@implementation NSData (BTC)



#pragma mark - Hash Functions


- (NSData*) SHA1 { return BTCSHA1(self); }
- (NSData*) SHA256 { return BTCSHA256(self); }
- (NSData*) BTCHash256 { return BTCHash256(self); }

#if BTCDataRequiresOpenSSL
- (NSData*) RIPEMD160 { return BTCRIPEMD160(self); }
- (NSData*) BTCHash160 { return BTCHash160(self); }
#endif




#pragma mark - Formatting


- (NSString*) hex {
    return BTCHexFromData(self);
}

- (NSString*) uppercaseHex {
    return BTCUppercaseHexFromData(self);
}
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"
- (NSString*) hexString {
    return BTCHexFromData(self);
}

- (NSString*) hexUppercaseString {
    return BTCUppercaseHexFromData(self);
}
#pragma clang diagnostic pop


//[GDChiefHomeManager chiefFocus_netRequestwith:self.allModel completeWithSuccess:^{
//    
//    if ([weakSelf.allModel.sx_info.is_attention isEqualToString:@"1"]) {
//        weakSelf.allModel.sx_info.is_attention = @"0";
//        
//        if (![weakSelf.allModel.sx_info.dy_count containsString:@"万"]) {
//            weakSelf.allModel.sx_info.dy_count = [NSString stringWithFormat:@"%d",[weakSelf.allModel.sx_info.dy_count intValue]-1];
//        }
//        
//        [[NSNotificationCenter defaultCenter] postNotificationName:First_ChiefAttentionNotification object:nil userInfo:@{@"type":@"down",@"chief_id":weakSelf.allModel.sx_info.ud_ub_id}];
//        
//        if (weakSelf.refresh_attention) {
//            weakSelf.refresh_attention(@"down");
//        }
//        
//    }else{
//        [MobClick event:shouxi_guanzhu];
//        
//        weakSelf.allModel.sx_info.is_attention = @"1";
//        if (![weakSelf.allModel.sx_info.dy_count containsString:@"万"]) {
//            if ([weakSelf.allModel.sx_info.dy_count intValue] == 9999) {
//                weakSelf.allModel.sx_info.dy_count = @"1万";
//            }else{
//                weakSelf.allModel.sx_info.dy_count = [NSString stringWithFormat:@"%d",[weakSelf.allModel.sx_info.dy_count intValue]+1];
//            }
//        }
//        [[NSNotificationCenter defaultCenter] postNotificationName:First_ChiefAttentionNotification object:nil userInfo:@{@"type":@"up",@"chief_id":weakSelf.allModel.sx_info.ud_ub_id}];
//        
//        if (weakSelf.refresh_attention) {
//            weakSelf.refresh_attention(@"up");
//        }
//    }
//    if (weakSelf.publicPrivateClassAttention) {
//        weakSelf.publicPrivateClassAttention(weakSelf.allModel.sx_info.dy_count);
//    }
//    if ([weakSelf.delegate respondsToSelector:@selector(needUpDataSource)]) {
//        [weakSelf.delegate needUpDataSource];
//    }
//    [weakSelf.headerView reload_HeaderView];
//    weakSelf.headerView.attentionButton.userInteractionEnabled = YES;
//    
//} failed:^{
//    [BullTipsView showMessage:@"请稍后再试"];
//}];



#pragma mark - Encryption / Decryption




+ (NSMutableData*) encryptData:(NSData*)data key:(NSData*)key iv:(NSData*)initializationVector {
    return [self cryptData:data key:key iv:initializationVector operation:kCCEncrypt];
}

+ (NSMutableData*) decryptData:(NSData*)data key:(NSData*)key iv:(NSData*)initializationVector {
    return [self cryptData:data key:key iv:initializationVector operation:kCCDecrypt];
}


+ (NSMutableData*) cryptData:(NSData*)data key:(NSData*)key iv:(NSData*)iv operation:(CCOperation)operation {
    if (!data || !key) return nil;
    
    int blockSize = kCCBlockSizeAES128;
    int encryptedDataCapacity = (int)(data.length / blockSize + 1) * blockSize;
    NSMutableData* encryptedData = [[NSMutableData alloc] initWithLength:encryptedDataCapacity];
    
    // Treat empty IV as nil
    if (iv.length == 0) {
        iv = nil;
    }
    
    // If IV is supplied, validate it.
    if (iv) {
        if (iv.length == blockSize) {
            // perfect.
        } else if (iv.length > blockSize) {
            // IV is bigger than the block size. CCCrypt will take only the first 16 bytes.
        } else {
            // IV is smaller than needed. This should not happen. It's better to crash than to leak something.
            @throw [NSException exceptionWithName:@"NSData+BTC IV is invalid"
                                           reason:[NSString stringWithFormat:@"Invalid size of IV: %d", (int)iv.length]
                                         userInfo:nil];
        }
    }
    
    size_t dataOutMoved = 0;
    CCCryptorStatus cryptstatus = CCCrypt(
                                          operation,                   // CCOperation op,         /* kCCEncrypt, kCCDecrypt */
                                          kCCAlgorithmAES,             // CCAlgorithm alg,        /* kCCAlgorithmAES128, etc. */
                                          kCCOptionPKCS7Padding,       // CCOptions options,      /* kCCOptionPKCS7Padding, etc. */
                                          key.bytes,                   // const void *key,
                                          key.length,                  // size_t keyLength,
                                          iv ? iv.bytes : NULL,        // const void *iv,         /* optional initialization vector */
                                          data.bytes,                  // const void *dataIn,     /* optional per op and alg */
                                          data.length,                 // size_t dataInLength,
                                          encryptedData.mutableBytes,  // void *dataOut,          /* data RETURNED here */
                                          encryptedData.length,        // size_t dataOutAvailable,
                                          &dataOutMoved                // size_t *dataOutMoved
                                          );
    
    if (cryptstatus == kCCSuccess) {
        // Resize the result key to the correct size.
        encryptedData.length = dataOutMoved;
        return encryptedData;
    } else {
        //kCCSuccess          = 0,
        //kCCParamError       = -4300,
        //kCCBufferTooSmall   = -4301,
        //kCCMemoryFailure    = -4302,
        //kCCAlignmentError   = -4303,
        //kCCDecodeError      = -4304,
        //kCCUnimplemented    = -4305,
        //kCCOverflow         = -4306
        @throw [NSException exceptionWithName:@"NSData+BTC CCCrypt failed"
                                       reason:[NSString stringWithFormat:@"error: %d", cryptstatus] userInfo:nil];
        return nil;
    }
}


@end
