#include "Environment.h"

void envInit(Environment *env) {
    // all env fields should be zero.
    assert( env
            && !env->frame
            && !env->parent );
    env->frame = calloc(1, sizeof(Frame));
    frameInit(env->frame);
}

// set or unset parent
void envSetParent(Environment *env, const Environment *parent) {
    env->parent = parent;
}

FrameEntry *envLookup(const Environment *env, const char *keyword) {
    if (NULL == env) return NULL;
    FrameEntry *result = frameLookup(env->frame,keyword);
    return result
        ? result
        : envLookup(env->parent, keyword);
}

void envInsert(Environment *env, const char *key, void *val) {
    frameInsert(env->frame,key,val);
}

void envFree(Environment *env) {
    assert( env->frame );
    frameFree( env->frame );
    free( env->frame );
    env->frame = NULL;
}