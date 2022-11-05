//
//  Pogo-BridgingHeader.h
//  Pogo
//
//  Created by Amy While on 12/09/2022.
//

#ifndef weedra1n_BridgingHeader_h
#define weedra1n_BridgingHeader_h

#import "TSUtil.h"
#include <spawn.h>

#define POSIX_SPAWN_PERSONA_FLAGS_OVERRIDE 1
int posix_spawnattr_set_persona_np(const posix_spawnattr_t* __restrict, uid_t, uint32_t);
int posix_spawnattr_set_persona_uid_np(const posix_spawnattr_t* __restrict, uid_t);
int posix_spawnattr_set_persona_gid_np(const posix_spawnattr_t* __restrict, uid_t);


#endif /* weedra1n_BridgingHeader_h */
