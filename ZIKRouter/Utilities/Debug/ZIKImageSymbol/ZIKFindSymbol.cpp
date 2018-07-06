//
//  ZIKFindSymbol.cpp
//  ZIKRouter
//
//  Created by zuik on 2017/12/22.
//  Copyright © 2017 zuik. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

//https://github.com/r-plus/substrate/blob/master/DarwinFindSymbol.cpp

#if DEBUG

#include "ZIKFindSymbol.h"

#ifdef __APPLE__
#include <TargetConditionals.h>
#endif

#include <mach/mach.h>
#include <mach/mach_init.h>

#include <mach-o/dyld.h>
#include <mach-o/fat.h>
#include <mach-o/loader.h>

extern "C" {
#include <mach-o/nlist.h>
}

#define BSD_KERNEL_PRIVATE
#include <machine/types.h>
#include <sys/sysctl.h>

#include "exec.h"

#include <stdio.h>
#include <stdlib.h>

#include <dlfcn.h>

#define _trace() do { \
MSLog(MSLogLevelNotice, "_trace(%u)", __LINE__); \
} while (false)


struct MSSymbolData {
    const char *name_;
    uint8_t type_;
    uint8_t sect_;
    int16_t desc_;
    uintptr_t value_;
};

#ifdef __LP64__
typedef struct mach_header_64 mach_header_xx;
typedef struct nlist_64 nlist_xx;
typedef struct segment_command_64 segment_command_xx;

static const uint32_t LC_SEGMENT_XX = LC_SEGMENT_64;
static const uint32_t MH_MAGIC_XX = MH_MAGIC_64;
#else
typedef struct mach_header mach_header_xx;
typedef struct nlist nlist_xx;
typedef struct segment_command segment_command_xx;

static const uint32_t LC_SEGMENT_XX = LC_SEGMENT;
static const uint32_t MH_MAGIC_XX = MH_MAGIC;
#endif

static ssize_t MSMachONameList_(const void *stuff, struct MSSymbolData *list, size_t nreq, bool(^matching)(const char *)) {
    //get slide
    size_t slide(0);
    for (uint32_t image(0), images(_dyld_image_count()); image != images; ++image)
        if (_dyld_get_image_header(image) == stuff) {
            slide = _dyld_get_image_vmaddr_slide(image);
            goto fat;
        }
    
    return -1;
    
fat:
    //find corresponding arch in fat binary
    const uint8_t *base(reinterpret_cast<const uint8_t *>(stuff));
    const struct exec *buf(reinterpret_cast<const struct exec *>(base));
    
    if (OSSwapBigToHostInt32(buf->a_magic) == FAT_MAGIC) {
        cpu_type_t cpu_type;
#if !TARGET_OS_TV && !TARGET_OS_WATCH
        struct host_basic_info hbi; {
            host_t host(mach_host_self());
            mach_msg_type_number_t count(HOST_BASIC_INFO_COUNT);
            if (host_info(host, HOST_BASIC_INFO, reinterpret_cast<host_info_t>(&hbi), &count) != KERN_SUCCESS)
                return -1;
            mach_port_deallocate(mach_task_self(), host);
            cpu_type = hbi.cpu_type;
        }
#else
        size_t size;
        size = sizeof(cpu_type);
        sysctlbyname("hw.cputype", &cpu_type, &size, NULL, 0);
#endif
        
        const struct fat_header *fh(reinterpret_cast<const struct fat_header *>(base));
        uint32_t nfat_arch(OSSwapBigToHostInt32(fh->nfat_arch));
        const struct fat_arch *fat_archs(reinterpret_cast<const struct fat_arch *>(fh + 1));
        
        for (uint32_t i(0); i != nfat_arch; ++i)
            if (static_cast<cpu_type_t>(OSSwapBigToHostInt32(fat_archs[i].cputype)) == cpu_type) {
                buf = reinterpret_cast<const struct exec *>(base + OSSwapBigToHostInt32(fat_archs[i].offset));
                goto thin;
            }
        
        return -1;
    }
    
thin:
    //find load command of LC_SYMTAB
    const nlist_xx *symbols;
    const char *strings;
    size_t n;
    
    // XXX: this check looks really scary when it fails
    if (buf->a_magic == MH_MAGIC_XX) {
        const mach_header_xx *mh(reinterpret_cast<const mach_header_xx *>(base));
        const struct load_command *load_commands(reinterpret_cast<const struct load_command *>(mh + 1));
        
        const struct symtab_command *stp(NULL);
        const struct load_command *lcp;
        
        /* forlc (command, mh, LC_SYMTAB, struct symtab_command) {
         stp = command;
         goto found;
         } */
        
        lcp = load_commands;
        for (uint32_t i(0); i != mh->ncmds; ++i) {
            if (
                lcp->cmdsize % sizeof(long) != 0 || lcp->cmdsize <= 0 ||
                reinterpret_cast<const uint8_t *>(lcp) + lcp->cmdsize > reinterpret_cast<const uint8_t *>(load_commands) + mh->sizeofcmds
                )
                return -1;
            
            if (lcp->cmd == LC_SYMTAB) {
                if (lcp->cmdsize != sizeof(struct symtab_command))
                    return -1;
                stp = reinterpret_cast<const struct symtab_command *>(lcp);
                goto found;
            }
            
            lcp = reinterpret_cast<const struct load_command *>(reinterpret_cast<const uint8_t *>(lcp) + lcp->cmdsize);
        }
        
        return -1;
        
    found:
        n = stp->nsyms;
        
        //find symbol table and string table from __LINKEDIT segment command
        symbols = NULL;
        strings = NULL;
        
        /* forlc (command, mh, LC_SEGMENT_XX, segment_command_xx) {
         stp = command;
         goto found;
         } */
        
        lcp = load_commands;
        for (uint32_t i(0); i != mh->ncmds; ++i) {
            if (
                lcp->cmdsize % sizeof(long) != 0 || lcp->cmdsize <= 0 ||
                reinterpret_cast<const uint8_t *>(lcp) + lcp->cmdsize > reinterpret_cast<const uint8_t *>(load_commands) + mh->sizeofcmds
                )
                return -1;
            
            if (lcp->cmd == LC_SEGMENT_XX) {
                if (lcp->cmdsize < sizeof(segment_command_xx))
                    return -1;
                const segment_command_xx *segment(reinterpret_cast<const segment_command_xx *>(lcp));
                if (strcmp(segment->segname, SEG_LINKEDIT) == 0) {
                    if (stp->symoff >= segment->fileoff && stp->symoff < segment->fileoff + segment->filesize)
                        //symbol table's address = segment's address (slide + segment's virtual memory address) + symbol table's offset in segment (symbol table's offset in mach-o file - segment's offset in file)
                        symbols = reinterpret_cast<const nlist_xx *>(stp->symoff - segment->fileoff + segment->vmaddr + slide);
                    if (stp->stroff >= segment->fileoff && stp->stroff < segment->fileoff + segment->filesize)
                        strings = reinterpret_cast<const char *>(stp->stroff - segment->fileoff + segment->vmaddr + slide);
                    break;
                }
            }
            lcp = reinterpret_cast<const struct load_command *>(reinterpret_cast<const uint8_t *>(lcp) + lcp->cmdsize);
        }
        
        if (symbols == NULL || strings == NULL)
            return -1;
        // XXX: detect a.out somehow?
    } else if (false) {
        /* XXX: is this right anymore?!? */
//        symbols = reinterpret_cast<const nlist_xx *>(base + N_SYMOFF(*buf));
//        strings = reinterpret_cast<const char *>(reinterpret_cast<const uint8_t *>(symbols) + buf->a_syms);
//        n = buf->a_syms / sizeof(nlist_xx);
    } else return -1;
    
    //find symbols with names
    size_t result(nreq);
    
    for (size_t m(0); m != n; ++m) {
        const nlist_xx *q(&symbols[m]);
        if (q->n_un.n_strx == 0 || (q->n_type & N_STAB) != 0)
            continue;
        
        //name of the symbol in string table
        const char *nambuf(strings + q->n_un.n_strx);
//        fprintf(stderr, " == %s\n", nambuf);
        
        for (size_t item(0); item != nreq; ++item) {
            struct MSSymbolData *p(list + item);
            if (matching) {
                if (!matching(nambuf)) {
                    continue;
                }
            } else {
                if (p->name_ == NULL) {
                    continue;
                }
                if (strcmp(p->name_, nambuf) != 0) {
                    continue;
                }
            }
            
            p->name_ = NULL;
            
            p->value_ = q->n_value;
            if (p->value_ != 0)
                p->value_ += slide;
            
            p->type_ = q->n_type;
            p->desc_ = q->n_desc;
            p->sect_ = q->n_sect;
            
            if (--result == 0)
                return 0;
            break;
        }
    }
    
    return result;
}

static bool string_ends_with(const char * str, const char * suffix) {
    if (str == NULL || suffix == NULL) {
        return false;
    }
    size_t str_len = strlen(str);
    size_t suffix_len = strlen(suffix);
    
    return
    (str_len >= suffix_len) &&
    (0 == strcmp(str + (str_len-suffix_len), suffix));
}

 ZIKImageRef ZIKGetImageByName(const char *file) {
    for (uint32_t image(0), images(_dyld_image_count()); image != images; ++image)
        if (string_ends_with(_dyld_get_image_name(image), file)) {
            return _dyld_get_image_header(image);
        }
            
    return NULL;
}

static void ZIKFindSymbols(ZIKImageRef image, size_t count, const char *names[], void *values[], bool(^matching)(const char *)) {
    MSSymbolData items[count];
    
    for (size_t index(0); index != count; ++index) {
        MSSymbolData &item(items[index]);
        
        if (names) {
            item.name_ = names[index];
        }
        item.type_ = 0;
        item.sect_ = 0;
        item.desc_ = 0;
        item.value_ = 0;
    }
    
    if (image != NULL)
        MSMachONameList_(image, items, count, matching);
    else {
        size_t remain(count);
        
        for (uint32_t image(0), images(_dyld_image_count()); image != images; ++image) {
            //fprintf(stderr, ":: %s\n", _dyld_get_image_name(image));
            
            ssize_t result(MSMachONameList_(_dyld_get_image_header(image), items, count, matching));
            if (result == -1)
                continue;
            
            // XXX: maybe avoid this happening at all? a flag to NSMachONameList_?
            for (size_t index(0); index != count; ++index) {
                MSSymbolData &item(items[index]);
                if (item.name_ == NULL && item.value_ == 0) {
                    ++result;
                    if (names) {
                        item.name_ = names[index];
                    }
                }
            }
            
            remain -= count - result;
            if (remain == 0)
                break;
        }
    }
    
    for (size_t index(0); index != count; ++index) {
        MSSymbolData &item(items[index]);
        uintptr_t value(item.value_);
#ifdef __arm__
        if ((item.desc_ & N_ARM_THUMB_DEF) != 0)
            value |= 0x00000001;
#endif
        values[index] = reinterpret_cast<void *>(value);
    }
}

void *ZIKFindSymbol(ZIKImageRef image, const char *name) {
    void *value;
    ZIKFindSymbols(image, 1, &name, &value, NULL);
    return value;
}

void *ZIKFindSymbol(ZIKImageRef image, bool(^matchingBlock)(const char *)) {
    void *value;
    ZIKFindSymbols(image, 1, NULL, &value, matchingBlock);
    return value;
}

const char *ZIKSymbolNameForAddress(void *address) {
    Dl_info dlinfo;
    dladdr(address, &dlinfo);
    return dlinfo.dli_sname;
}

const char *ZIKImagePathForAddress(void *address) {
    Dl_info dlinfo;
    dladdr(address, &dlinfo);
    return dlinfo.dli_fname;
}

#endif
