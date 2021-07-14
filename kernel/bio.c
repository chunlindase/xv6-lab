// Buffer cache.
//
// The buffer cache is a linked list of buf structures holding
// cached copies of disk block contents.  Caching disk blocks
// in memory reduces the number of disk reads and also provides
// a synchronization point for disk blocks used by multiple processes.
//
// Interface:
// * To get a buffer for a particular disk block, call bread.
// * After changing buffer data, call bwrite to write it to disk.
// * When done with the buffer, call brelse.
// * Do not use the buffer after calling brelse.
// * Only one process at a time can use a buffer,
//     so do not keep them longer than necessary.


#include "types.h"
#include "param.h"
#include "spinlock.h"
#include "sleeplock.h"
#include "riscv.h"
#include "defs.h"
#include "fs.h"
#include "buf.h"

struct bbucket {
  struct spinlock lock;
  struct buf *bentry[NBUF];
  uint entry_num;
};

struct {
  struct spinlock lock;
  struct buf buf[NBUF];
  struct bbucket hashbkt[NBUCKET];
  uint glob_tstamp;
} bcache;

// struct spinlock dbglk;

struct bbucket*
bhash(uint blockno) {
  return &bcache.hashbkt[blockno % NBUCKET];
}


void
binit(void) {
    struct buf* b;

    // 初始化 bcache
    initlock(&bcache.lock, "bcache");
    bcache.glob_tstamp = 0;

    // 初始化所有 bbucket
    struct bbucket* bkt;
    for (bkt = bcache.hashbkt; bkt < bcache.hashbkt + NBUCKET; bkt++) {
        initlock(&bkt->lock, "bbucket");
        bkt->entry_num = 0;
    }

    // 初始化 bcache.buf 数组（即缓存池）中的所有缓存块
    for (int i = 0; i < NBUF; i++) {
        b = &bcache.buf[i];
        initsleeplock(&b->lock, "buffer");
        // bcache.buf[i] 设为 blockno 为 i 的块。
        b->blockno = i;
        b->refcnt = 0;
        b->tstamp = 0;
        // 注意 valid 一定要设为 0
        //表示缓存块中的数据是无效的，bread 到这个块时需要从磁盘重新读取数据
        b->valid = 0;
        // 向对应的哈希桶中分发这个块
        bkt = bhash(b->blockno);
        b->bktord = bkt->entry_num;
        bkt->bentry[bkt->entry_num++] = b;
    }
}

// Look through buffer cache for block on device dev.
// If not found, allocate a buffer.
// In either case, return locked buffer.
static struct buf*

bget(uint dev, uint blockno)
{
  struct bbucket* bkt=bhash(blockno);
  acquire(&bkt->lock);
  for(int i=0;i<bkt->entry_num;i++){
    struct buf* b=bkt->bentry[i];
    if(b->dev==dev&&b->blockno==blockno){
      b->refcnt++;
      release(&bkt->lock);
      acquiresleep(&b->lock);
      return b;
    }
  }

  release(&bkt->lock);
  acquire(&bcache.lock);
  acquire(&bkt->lock);
  for (int i = 0; i < bkt->entry_num; i++) {
        struct buf* b = bkt->bentry[i];
        if (b->dev == dev && b->blockno == blockno) {
            b->refcnt++;
            release(&bcache.lock);
            release(&bkt->lock);
            acquiresleep(&b->lock);
            return b;
        }
    }

 while(1){
        struct buf* evict_buf = 0;
        uint min_tstamp = 0xffffffff;
        for (struct buf* b = bcache.buf; b < bcache.buf + NBUF; b++) {
            if (b->refcnt == 0 && b->tstamp < min_tstamp) {
                min_tstamp = b->tstamp;
                evict_buf = b;
            }
        }
        if (!evict_buf) {
            panic("bget: no buffers");
        }
        struct bbucket* evict_bkt = bhash(evict_buf->blockno);
        if (evict_bkt != bkt) {
            acquire(&evict_bkt->lock);
        }
        if (evict_buf->refcnt != 0) {
            if (evict_bkt != bkt) {
                release(&evict_bkt->lock);
            }
            // refcnt is not 0, reseek for an available buffer block
            continue;
        }
        uint num = evict_bkt->entry_num;
        if (evict_buf->bktord < num - 1) {
            evict_bkt->bentry[evict_buf->bktord] = evict_bkt->bentry[num - 1];
            evict_bkt->bentry[evict_buf->bktord]->bktord = evict_buf->bktord;
        }
        evict_bkt->entry_num--;
        if (evict_bkt != bkt) {
            release(&evict_bkt->lock);
        }
        evict_buf->bktord = bkt->entry_num;
        bkt->bentry[bkt->entry_num++] = evict_buf;
        evict_buf->dev = dev;
        evict_buf->blockno = blockno;
        evict_buf->valid = 0;
        evict_buf->refcnt = 1;
        acquiresleep(&evict_buf->lock);
        release(&bcache.lock);
        release(&bkt->lock);
        return evict_buf;
 }


}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
  struct buf *b;

  b = bget(dev, blockno);
  b->tstamp=++bcache.glob_tstamp;
  if(!b->valid) {
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{

  if(!holdingsleep(&b->lock))
    panic("bwrite");
  b->tstamp = ++bcache.glob_tstamp;
  virtio_disk_rw(b, 1);
}

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
  if (!holdingsleep(&b->lock))
        panic("brelse");

    struct bbucket* bkt = bhash(b->blockno);
    releasesleep(&b->lock);

    acquire(&bkt->lock);
    b->refcnt--;
    if (b->refcnt == 0) {
        // no one is waiting for it.
        b->tstamp = 0;
    }

    release(&bkt->lock);
}

void
bpin(struct buf* b) {
    struct bbucket* bkt = bhash(b->blockno);
    acquire(&bkt->lock);
    b->refcnt++;
    b->tstamp = ++bcache.glob_tstamp;
    release(&bkt->lock);
}

void
bunpin(struct buf* b) {
    struct bbucket* bkt = bhash(b->blockno);
    acquire(&bkt->lock);
    b->refcnt--;
    release(&bkt->lock);
}


