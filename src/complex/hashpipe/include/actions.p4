#ifndef __ACTIONS__
#define __ACTIONS__

#include "headers.p4"

action _drop() {
    mark_to_drop();
}

#endif