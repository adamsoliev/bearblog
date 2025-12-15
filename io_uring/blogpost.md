#### Table of Contents

- [What and why](#what-and-why)

Mental model[^3]
<div style="text-align: center;">
<img src="https://github.com/adamsoliev/bearblog/blob/main/io_uring/images/io_uring.png?raw=true" alt="first example" style="border: 0px solid black; width: 100%; height: auto;">
</div>

submission consists of an array of indexes and actual queue; the reason for this is I/O ops may complete in an order different from submission order.

app polling

kernel polling; restart kernel polling

---

I/O requests get classified into two categories
- work that completes in a bounded time (reading from reg file or block device)
- work that may never complete (unbounded work); workers here are limited by `RLIMIT_NPROC` (network I/O, char devices)

---

Thankfully, io_uring comes with a set of ready to use static tracepoints, which save us the trouble of digging through the source code to decide where to hook up dynamic tracepoints, known as kprobes.

We can discover the tracepoints with perf list or bpftrace -l, or by browsing the events/ directory on the tracefs filesystem, usually mounted under /sys/kernel/tracing.

```bash
$ perf list 'io_uring:*'

    io_uring:io_uring_complete                         [Tracepoint event]
    io_uring:io_uring_cqe_overflow                     [Tracepoint event]
    io_uring:io_uring_cqring_wait                      [Tracepoint event]
    io_uring:io_uring_create                           [Tracepoint event]
    io_uring:io_uring_defer                            [Tracepoint event]
    io_uring:io_uring_fail_link                        [Tracepoint event]
    io_uring:io_uring_file_get                         [Tracepoint event]
    io_uring:io_uring_link                             [Tracepoint event]
    io_uring:io_uring_local_work_run                   [Tracepoint event]
    io_uring:io_uring_poll_arm                         [Tracepoint event]
    io_uring:io_uring_queue_async_work                 [Tracepoint event]
    io_uring:io_uring_register                         [Tracepoint event]
    io_uring:io_uring_req_failed                       [Tracepoint event]
    io_uring:io_uring_short_write                      [Tracepoint event]
    io_uring:io_uring_submit_req                       [Tracepoint event]
    io_uring:io_uring_task_add                         [Tracepoint event]
    io_uring:io_uring_task_work_run                    [Tracepoint event]
    syscalls:sys_enter_io_uring_enter                  [Tracepoint event]
    syscalls:sys_enter_io_uring_register               [Tracepoint event]
    syscalls:sys_enter_io_uring_setup                  [Tracepoint event]
    syscalls:sys_exit_io_uring_enter                   [Tracepoint event]
    syscalls:sys_exit_io_uring_register                [Tracepoint event]
    syscalls:sys_exit_io_uring_setup                   [Tracepoint event]
```

```C
// used in set up, passed in as null; returns init'd info
struct io_uring_params {
	__u32 sq_entries;
	__u32 cq_entries;
	__u32 flags;
	__u16 resv[10];
	struct io_sqring_offsets sq_off;
	struct io_cqring_offsets cq_off;
};

// submission and completion structures
struct io_uring_sqe {
	__u8	opcode;		/* type of operation (eg read/write/fsync) for this sqe */
	__u8	flags;		/* IOSQE_ flags */
	__u16	ioprio;		/* ioprio for the request */
	__s32	fd;				/* file descriptor to do IO on */
	__u64	off;			/* offset into file */
	void	*addr;		/* buffer or iovecs */
	__u32	len;			/* buffer size or number of iovecs */
	union {
    __kernel_rwf_t	rw_flags;
    __u32		fsync_flags;
	};
	__u64	user_data;	/* data to be passed back at completion time */
	__u16	buf_index;	/* index into fixed buffers, if used */
};

struct io_uring_cqe {
	__u64	user_data;	/* sqe->user_data submission passed back */
	__s32	res;		/* result code for this event */
	__u32	flags;
};

// submission and completion queues
struct io_sq_ring {
	struct io_uring		r;
	u32			ring_mask;
	u32			ring_entries;
	u32			dropped;
	u32			flags;
	u32			array[];
};

struct io_cq_ring {
	struct io_uring		r;
	u32			ring_mask;
	u32			ring_entries;
	u32			overflow;
	struct io_uring_cqe	cqes[];
};
    
```

- [References](#references)

---

## <a id="what-and-why" href="#table-of-contents">What and why</a>
io_uring

## <a id="references" href="#table-of-contents">References</a>
[^1]: https://lwn.net/Articles/776703/
[^2]: https://unixism.net/loti/
[^3]: https://blog.cloudflare.com/missing-manuals-io_uring-worker-pool
