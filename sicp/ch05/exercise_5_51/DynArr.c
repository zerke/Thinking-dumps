// a simple self-adjusting array

#include "Common.h"
#include "DynArr.h"

void dynArrInit(DynArr *p, size_t elemSize) {
    // pointer should not be null
    // all fields should be zero
    assert( p
            && !p->base
            && !p->elemSize
            && !p->elemMax
            && !p->elemCap );
    p->elemMax = 0;
    p->elemSize = elemSize;
    p->elemCap = SMALL_BUFFER_SIZE / elemSize;
    p->base = calloc(elemSize, p->elemCap);
}

// adjust the array so that it guarantees
// to contain the next element
// for internal use. no need to expose it
void dynArrAdjust(DynArr *p) {
    // should not be zero
    assert(p->elemCap && "DynArr should not be zero");
    if (p->elemMax+1 >= p->elemCap) {
        p->elemCap *= 2;
        p->base = realloc(p->base, p->elemSize*p->elemCap);
        assert(p->base && "DynArr base should not be NULL");
    }
}

// allocate a new object
void *dynArrNew(DynArr *p) {
    dynArrAdjust(p);
    void *retVal = dynArrEnd(p);
    ++ p->elemMax;
    return retVal;
}

void dynArrFree(DynArr *p) {
    assert( p && "DynArr: freeing NULL" );
    free(p->base);
    memset(p, 0x00, sizeof(DynArr));
}

void *dynArrNth(const DynArr *p, int nth) {
    return p->base + p->elemSize * nth;
}

// return the place pointing to the first element
void *dynArrBegin(const DynArr *p) {
    return dynArrNth(p,0);
}

// return the last element, might not be a valid
// pointer depending on the emptiness.
void *dynArrLast(const DynArr *p) {
    return dynArrNth(p,p->elemMax-1);
}

void *dynArrEnd(const DynArr *p) {
    return dynArrNth(p,p->elemMax);
}

// get next pointer
void *dynArrNext(const DynArr *p, void *ptr) {
    unsigned char *tPtr = ptr;
    return tPtr + p->elemSize;
}

int dynArrCount(const DynArr *p) {
    return p->elemMax;
}

void dynArrVisit(DynArr *p, DynArrVisitor dv) {
    void *it;
    for (it = dynArrBegin(p);
         it != dynArrEnd(p);
         it = dynArrNext(p,it)) {
        dv(it);
    }
}

void * dynArrFoldLeft(DynArr *p, DynArrFoldLeftAccumulator acc, void *init) {
    void *it;
    void *state = init;
    for (it = dynArrBegin(p);
         it != dynArrEnd(p);
         it = dynArrNext(p,it)) {
        state = acc(state,it);
    }
    return state;
}
