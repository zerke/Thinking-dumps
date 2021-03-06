#ifndef JAVEV_ENVIRONMENT_H
#define JAVEV_ENVIRONMENT_H

#include "Common.h"
#include "SExp.h"
#include "Frame.h"

struct Environment;

typedef struct Environment {
    // INVARIANT:
    // * frame is never NULL
    // * following parent recursively should
    //   not get stuck in a loop
    Frame *frame;
    const struct Environment *parent;
} Environment;

void envInit(Environment *);
void envSetParent(Environment *, const Environment *);
FrameEntry *envLookup(const Environment *, const char *);
void envInsert(Environment *, const char *, const SExp *);
void envFree(Environment *);

#endif
