#import "c_blocks.h"

@implementation CBlocks

-(void) configureDataStruct: (struct data_struct *) ds length: (uint64_t) len {
	ds->data = malloc(len);
	memset(ds->data,0,len);
	ds->place = 0;
}

-(struct cblock_struct *) allocateCBlockStructs {
	struct cblock_struct *cblock = &cblocks[place];
	memset(cblock,0,sizeof(*cblock));
	cblock->num = place;
    place += 1;
	return cblock;
}

-(void *) allocCdata: (uint64_t) s {
	void *retval;
	uint8_t *buffer = (uint8_t *) cdata.data;
	retval = &buffer[cdata.place];
	cdata.place += s;
	return retval;
}

-(void) compressCBlock: (struct cblock_struct *) cblock {
	struct axfs_node *node;
	uint8_t *uncomp = (uint8_t *) uncbuffer;
	uint64_t unclength = 0;
    node = cblock->nodes;
	if(cblock->cdata != NULL) {
		return;
	}
	memset(uncbuffer,0,acfg.block_size);
	memset(cbbuffer,0,acfg.block_size);
	while (node != NULL) {
		struct page_struct *page;
		page = node->page;
		memcpy(&uncomp[unclength],page->data,page->length);
		unclength += page->length;
		if (unclength >= acfg.block_size) {
			exit(-1);
		}
		node = node->next;
	}
	[compressor cdata: cbbuffer csize: &cblock->csize data: uncbuffer size: unclength];
	cblock->cdata = [self allocCdata: cblock->csize];
	memcpy(cblock->cdata,cbbuffer,cblock->csize);
}

-(void) addNodeToCBlock: (struct axfs_node *) node cblock: (struct cblock_struct *) cb {
	cb->length += node->page->length;
	if (cb->nodes == NULL) {
		cb->nodes = node;
		cb->current_node = node;
	} else {
		cb->current_node->next = node;
		cb->current_node = node;
	}
	node->cboffset = cb->offset;
	cb->offset += cb->length;
}

-(void) addFullPageNode: (struct axfs_node *) node {
	if (fullpage_current == NULL) {
		fullpage_current = [self allocateCBlockStructs];
	} else if (fullpage_current->length == acfg.block_size) {
		fullpage_current->next = [self allocateCBlockStructs];
		fullpage_current = fullpage_current->next;
	}
	[self addNodeToCBlock: node cblock: fullpage_current];
}

-(void) addPartPageNode: (struct axfs_node *) node {
	struct cblock_struct *cb;
	if (partpages == NULL) {
		partpages = [self allocateCBlockStructs];
	}
	cb = partpages;
	while (cb != NULL) {
		printf("node->page->length=%llu\n",node->page->length);
		if ((acfg.block_size - cb->length) >= node->page->length) {
			break;
		}
		if (cb->next == NULL) {
			cb->next = [self allocateCBlockStructs];
			cb = cb->next;
			break;	
		}
		cb = cb->next;
	}
	[self addNodeToCBlock: node cblock: cb];
	printf("  )part\n");
}

-(void) addNode: (struct axfs_node *) node {
    printf("node { page=0x%08llx next=0x%08llx cboffset=0x%08llx\n",node->page,node->next,node->cboffset);


	if (node->page->length == acfg.page_size) {
		return [self addFullPageNode: node];
	} else {
		return [self addPartPageNode: node];
	}
}

-(uint64_t) size {
	uint64_t s = 0;
	struct cblock_struct *cb = partpages;
		printf("size\n");
	while (cb != NULL) {
		[self compressCBlock: cb];
		s += cb->csize;
		cb = cb->next;
	}
	cb = fullpages;
	while (cb != NULL) {
		[self compressCBlock: cb];
		s += cb->csize;
		cb = cb->next;
	}
	return s;
}

-(uint64_t) length {
	return place;
}

-(void *) data {
	uint8_t *dout = (uint8_t *) data.data;
	struct cblock_struct *cb = partpages;
	uint64_t num = 0;
	while (cb != NULL) {
		cb->num = num;
		num += 1;
		[self compressCBlock: cb];
		memcpy(dout,cb->cdata,cb->csize);
		dout += cb->csize;
		cb = cb->next;
	}
	cb = fullpages;
	while (cb != NULL) {
		cb->num = num;
		num += 1;
		[self compressCBlock: cb];
		memcpy(dout,cb->cdata,cb->csize);
		dout += cb->csize;
		cb = cb->next;
	}
	return data.data;
}

-(void) initialize {
	compressor = [[Compressor alloc] init];
	[compressor initialize];
	[compressor algorithm: acfg.compression];
	uncbuffer = malloc(acfg.block_size*2);
	cbbuffer = malloc(acfg.block_size*2);
	cblocks = malloc(sizeof(*cblocks)*(acfg.page_size/acfg.block_size)*acfg.max_nodes);
	place = 0;
	fullpages = 0;//[self allocateCBlockStructs];
	fullpage_current = fullpages;
	partpages = 0;//[self allocateCBlockStructs];
	[self configureDataStruct: &cdata length: acfg.page_size*acfg.max_nodes];
	[self configureDataStruct: &data length: acfg.page_size*acfg.max_nodes];
}

-(void) free {
	free(uncbuffer);
	free(cbbuffer);
	free(cblocks);
	free(data.data);
	free(cdata.data);
	[compressor free];
	[compressor release];
}

@end

