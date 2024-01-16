//  main.m
//  scadthumb
//
//  Created by David Phillip Oster on 1/15/24.
//

#import <Cocoa/Cocoa.h>

static const int notOK = 1;

// Resize smaller large thumbnails to fit in a 180x180 box.
static const float maxThumbnailDimension = 180;

static int Usage(const  char *name){
  fprintf(stderr, "usage: %s file.scad file.png\n", name);
  fprintf(stderr, "\tadd or update an embedded .png thumbnail to a .scad file.\n");
  return notOK;
}

/// @return a copy an image, scaled by scale factor 'scale'
static NSImage* ImageScaled(NSImage* img, float scale) {
  CGSize destSize = CGSizeMake(ceil(img.size.width*scale), ceil(img.size.height*scale));
  NSImage *result = [NSImage imageWithSize:destSize flipped:NO drawingHandler:^BOOL(NSRect dstRect) {
    [img drawInRect:CGRectMake(0, 0, destSize.width, destSize.height)];
    return YES;
  }];
  return result ? result : img;
}

/// @return image as a .png file, in an NSData.
static NSData *ImageAsPng(NSImage* img) {
  NSData *imageData = [img TIFFRepresentation];
  if (imageData) {
    NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithData:imageData];
    NSDictionary *imageProps = @{NSImageCompressionFactor: @(1.0)};
    return [imageRep representationUsingType:NSBitmapImageFileTypePNG properties:imageProps];
  }
  return nil;
}

/// @return data as a base64 string
static NSString *DataAsBase64(NSData *data) {
  return [data base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength|NSDataBase64EncodingEndLineWithLineFeed];
}

static NSString *const prefix = @"/*\nthumbnail begin ";
static NSString *const suffix = @"\nthumbnail end\n*/\n";

/// @return a base64 string wrapped in begin end directives, wrapped inside a block comment.
static NSString *WrapAsThumbString(NSString *s, NSSize size, NSInteger len){
  return [NSString stringWithFormat:@"%@%dx%d %d\n%@%@", prefix, (int)size.width, (int)size.height, (int)len, s, suffix];
}

/// @return remove the first existing wrapped thumbnail, if any.
static NSMutableString *RemoveAnyPreviousThumbString(NSMutableString *s) {
  NSRange start = [s rangeOfString:prefix];
  NSRange end = [s rangeOfString:suffix];
  if (start.location != NSNotFound && end.location != NSNotFound && start.location < end.location) {
    [s replaceCharactersInRange:NSMakeRange(start.location, end.location+end.length - start.location) withString:@""];
    if ([s rangeOfString:@"\n" options:NSBackwardsSearch|NSAnchoredSearch].location == NSNotFound) {
      [s appendString:@"\n"];
    }
  }
  return s;
}



int main(int argc, const char * argv[]) {
  @autoreleasepool {
    if (argc != 3) {
      return Usage(argv[0]);
    }
    if (0 == strcmp(argv[1], argv[2])) {
      fprintf(stderr, "“%s” “%s” are the same file\n", argv[1], argv[2]);
      return notOK;
    }
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *scadPath = [fm stringWithFileSystemRepresentation:argv[1] length:strlen(argv[1])];
    BOOL isDir;
    NSFileHandle *scad = nil;
    if([scadPath.pathExtension.lowercaseString isEqual:@"scad"]) {
      if ([fm fileExistsAtPath:scadPath isDirectory:&isDir] && !isDir) {
        scad = [NSFileHandle fileHandleForUpdatingAtPath:scadPath];
        if (nil == scad) {
          fprintf(stderr, "“%s” isn't writable\n", argv[1]);
        }
      } else {
        fprintf(stderr, "“%s” doesn't exist\n", argv[1]);
      }
    } else {
      fprintf(stderr, "“%s” doesn't have .scad file extension\n", argv[1]);
    }
    if (!scad) {
      return 1;
    }
    NSData *scadData = [scad readDataToEndOfFile];
    NSMutableString *scadString = scadData ? [[NSMutableString alloc] initWithData:scadData encoding:NSUTF8StringEncoding] : nil;
    if (!scadString) {
      fprintf(stderr, "“%s” can't be read as a UTF8 string\n", argv[1]);
      return 1;
    }
    NSString *imgPath = [fm stringWithFileSystemRepresentation:argv[2] length:strlen(argv[2])];
    NSImage *img = imgPath ? [[NSImage alloc] initWithContentsOfFile:imgPath] : nil;
    if (!img) {
      fprintf(stderr, "“%s” isn't readable as an image\n", argv[2]);
      return 1;
    }
    if (maxThumbnailDimension < MAX(img.size.width, img.size.height)) {
      img = ImageScaled(img, (maxThumbnailDimension-1)/MAX(img.size.width, img.size.height));
    }
    NSData *imgData = img ? ImageAsPng(img) : nil;
    NSString *imgBase64 = imgData ? DataAsBase64(imgData) : nil;
    NSString *thumbString = imgBase64 ? WrapAsThumbString(imgBase64, img.size, imgData.length) : nil;
    NSError *error = nil;
    if (thumbString) {
      [RemoveAnyPreviousThumbString(scadString) appendString:thumbString];
      unsigned long long off = 0;
      if ([scad seekToOffset:0 error:&error] &&
          [scad writeData:[scadString dataUsingEncoding:NSUTF8StringEncoding] error:&error] &&
          [scad getOffset:&off error:&error]) {
        [scad truncateAtOffset:off error:&error];
      } else {
        fprintf(stderr, "%s\n", [[error description] UTF8String]);
      }
    }

    [scad closeAndReturnError:&error];
    if (error) {
      fprintf(stderr, "%s\n", [[error description] UTF8String]);
      return 1;
    }
  }
  return 0;
}
