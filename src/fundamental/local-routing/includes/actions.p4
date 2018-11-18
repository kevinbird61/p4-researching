#ifndef __ACTIONS__
#define __ACTIONS__

#include "headers.p4"

action drop() {
    mark_to_drop();
}

#endif