#import <Foundation/Foundation.h>
#import "axfs_helper.h"
#import "getopts.h"
#import "opts_validator.h"
#import "image_builder.h"

#import "dir_walker.h"
#import "falloc.h"
#import <Foundation/NSAutoreleasePool.h>

struct axfs_config acfg;
struct axfs_objects aobj;

bool validate_args(int argc, const char *argv[]) {
	bool retval;
	char *msg;

	msg = malloc(1024);
	memset(msg,0,1024);
	do_getopts(argc,argv);
	retval = do_opts_validator(&msg);
	if(!retval)
		printf("do_opts_validator failed %s", msg);
	free(msg);
	return retval;
}

int main(int argc, const char *argv[]) {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	ImageBuilder *builder;

	if (!validate_args(argc, argv)) {
		[pool drain];
		return -1;
	}

	acfg.version_major = 2;
	acfg.version_minor = 9;
	acfg.version_sub = 1;
	builder = [[ImageBuilder alloc] init];

	[builder sizeup];
	printf("sizedup\n");
	[builder setupObjs];
	printf("setted up\n");
	[builder setupRegions];
	printf("etupRegions up\n");
	[builder walk];
	printf("walked\n");
	[builder build];
	printf("built\n");

	[pool drain];
	return 0;
}

/*
    AxfsDirWalker *dw;
	AxfsDataObject *ado;
	falloc *f;
	char *data;
	
	ado = [[AxfsDataObject alloc] init];
	
	f = [[falloc alloc] init];
	data = (char *) [f allocSize: 1024 path: "foo"];
	if (*data == -1)
		return 1;
	*data++ = 0x30;
	*data = 0x31;
	[f free];
	dw = [[AxfsDirWalker alloc] init];
	[dw setDataObject: ado];
	[dw walk: @"/usr/"];

	[ado printstats];
	
	[pool drain];
	return 0;
}
*/