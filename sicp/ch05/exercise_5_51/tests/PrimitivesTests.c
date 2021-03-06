#include <stdlib.h>
#include <check.h>
#include "../Evaluate.h"
#include "../EvalApp.h"
#include "../PointerManager.h"
#include "../InitEnv.h"

// this file is for testing:
//
// * primitive functions (Primitives.c)
// * initial environment (InitEnv.c)
//
// As it is easier to set up testcases
// for primitive applications with initial environment,
// it doesn't hurt to put them together.

// primitive "+"
START_TEST (test_Primitives_plus) {
    DynArr *pSExpList = parseSExps("(+ 1 2 3 4 5 6 7)", stderr);
    ck_assert_ptr_ne(pSExpList, NULL);
    ck_assert_int_eq(dynArrCount(pSExpList), 1);

    SExp expect = { sexpInteger, { .integerContent = 28 } };
    SExp **pExp = dynArrBegin(pSExpList);
    pointerManagerInit();
    Environment *penv = newInitEnv();
    const SExp *actual = evApplication(*pExp, penv);
    ck_assert(isSExpEqual(actual, &expect));

    envFree(penv);
    free(penv);
    pointerManagerFinalize();
    freeSExps(pSExpList);
} END_TEST

// primitive "-"
START_TEST (test_Primitives_minus) {
    DynArr *pSExpList = parseSExps("(- 3333 765 543)", stderr);
    ck_assert_ptr_ne(pSExpList, NULL);
    ck_assert_int_eq(dynArrCount(pSExpList), 1);

    SExp expect = { sexpInteger, { .integerContent = 2025 } };
    SExp **pExp = dynArrBegin(pSExpList);
    pointerManagerInit();
    Environment *penv = newInitEnv();
    const SExp *actual = evApplication(*pExp, penv);
    ck_assert(isSExpEqual(actual, &expect));
    envFree(penv);
    free(penv);
    pointerManagerFinalize();
    freeSExps(pSExpList);
} END_TEST

// primitive "*"
START_TEST (test_Primitives_mult) {
    DynArr *pSExpList = parseSExps("(* 2 57 89)", stderr);
    ck_assert_ptr_ne(pSExpList, NULL);
    ck_assert_int_eq(dynArrCount(pSExpList), 1);

    SExp expect = { sexpInteger, { .integerContent = 10146 } };
    SExp **pExp = dynArrBegin(pSExpList);
    pointerManagerInit();
    Environment *penv = newInitEnv();
    const SExp *actual = evApplication(*pExp, penv);
    ck_assert(isSExpEqual(actual, &expect));
    envFree(penv);
    free(penv);
    pointerManagerFinalize();
    freeSExps(pSExpList);
} END_TEST

// primitive "cons"
START_TEST (test_Primitives_cons) {
    DynArr *pSExpList = parseSExps("(cons 'a '(b c d)) (a b c d)", stderr);
    ck_assert_ptr_ne(pSExpList, NULL);
    ck_assert_int_eq(dynArrCount(pSExpList), 2);

    SExp **pExp = dynArrBegin(pSExpList);
    SExp *exp = *pExp;
    SExp **pExpect = dynArrNext(pSExpList, pExp);
    pointerManagerInit();
    Environment *penv = newInitEnv();

    const SExp *actual = evApplication(exp,penv);
    ck_assert(isSExpEqual(actual, *pExpect));
    envFree(penv);
    free(penv);
    pointerManagerFinalize();
    freeSExps(pSExpList);
} END_TEST

// primitive "car"
START_TEST (test_Primitives_car) {
    DynArr *pSExpList = parseSExps("(car '(a c d))", stderr);
    ck_assert_ptr_ne(pSExpList, NULL);
    ck_assert_int_eq(dynArrCount(pSExpList), 1);

    SExp **pExp = dynArrBegin(pSExpList);
    SExp *exp = *pExp;
    pointerManagerInit();
    Environment *penv = newInitEnv();
    const SExp *actual = evApplication(exp,penv);
    SExp expect = { sexpSymbol, { .symbolName = "a" } };

    ck_assert(isSExpEqual(&expect,actual));
    envFree(penv);
    free(penv);
    pointerManagerFinalize();
    freeSExps(pSExpList);
} END_TEST

// primitive "cdr"
START_TEST (test_Primitives_cdr) {
    DynArr *pSExpList = parseSExps("(cdr '(b c d)) (c d)", stderr);
    ck_assert_ptr_ne(pSExpList, NULL);
    ck_assert_int_eq(dynArrCount(pSExpList), 2);

    SExp **pExp = dynArrBegin(pSExpList);
    SExp *exp = *pExp;
    SExp **pExpect = dynArrNext(pSExpList, pExp);
    pointerManagerInit();
    Environment *penv = newInitEnv();

    const SExp *actual = evApplication(exp,penv);
    ck_assert(isSExpEqual(actual, *pExpect));
    envFree(penv);
    free(penv);
    pointerManagerFinalize();
    freeSExps(pSExpList);
} END_TEST

START_TEST (test_Primitives_list) {
    DynArr *pSExpList = parseSExps("(list 'a (+ 1 2) (* 3 4)) (a 3 12)", stderr);
    ck_assert_ptr_ne(pSExpList, NULL);
    ck_assert_int_eq(dynArrCount(pSExpList), 2);

    SExp **pExp = dynArrBegin(pSExpList);
    SExp *exp = *pExp;
    SExp **pExpect = dynArrNext(pSExpList, pExp);
    pointerManagerInit();
    Environment *penv = newInitEnv();

    const SExp *actual = evApplication(exp,penv);
    ck_assert(isSExpEqual(actual, *pExpect));
    envFree(penv);
    free(penv);
    pointerManagerFinalize();
    freeSExps(pSExpList);
} END_TEST

// primitive predicate test 1
START_TEST (test_Primitives_primPred1) {
    DynArr *pSExpList =
        parseSExps("(begin"
                   "  (define x 'a)"
                   "  (list (symbol? x) (string? x) (integer? x)"
                   "        (boolean? x) (null? x) (pair? x))"
                   ")"
                   "(#t #f #f #f #f #f)", stderr);
    ck_assert_ptr_ne(pSExpList, NULL);
    ck_assert_int_eq(dynArrCount(pSExpList), 2);

    SExp **pExp = dynArrBegin(pSExpList);
    SExp *exp = *pExp;
    SExp **pExpect = dynArrNext(pSExpList, pExp);
    pointerManagerInit();
    Environment *penv = newInitEnv();
    const SExp *actual = evalDispatch(exp,penv);
    ck_assert(isSExpEqual(actual, *pExpect));
    envFree(penv);
    free(penv);
    pointerManagerFinalize();
    freeSExps(pSExpList);
} END_TEST

// primitive predicate test 2
START_TEST (test_Primitives_primPred2) {
    DynArr *pSExpList =
        parseSExps("(begin"
                   "  (define x \"st\")"
                   "  (list (symbol? x) (string? x) (integer? x)"
                   "        (boolean? x) (null? x) (pair? x))"
                   ")"
                   "(#f #t #f #f #f #f)", stderr);
    ck_assert_ptr_ne(pSExpList, NULL);
    ck_assert_int_eq(dynArrCount(pSExpList), 2);

    SExp **pExp = dynArrBegin(pSExpList);
    SExp *exp = *pExp;
    SExp **pExpect = dynArrNext(pSExpList, pExp);
    pointerManagerInit();
    Environment *penv = newInitEnv();
    const SExp *actual = evalDispatch(exp,penv);
    ck_assert(isSExpEqual(actual, *pExpect));
    envFree(penv);
    free(penv);
    pointerManagerFinalize();
    freeSExps(pSExpList);
} END_TEST

// primitive predicate test 3
START_TEST (test_Primitives_primPred3) {
    DynArr *pSExpList =
        parseSExps("(begin"
                   "  (define x 100)"
                   "  (list (symbol? x) (string? x) (integer? x)"
                   "        (boolean? x) (null? x) (pair? x))"
                   ")"
                   "(#f #f #t #f #f #f)", stderr);
    ck_assert_ptr_ne(pSExpList, NULL);
    ck_assert_int_eq(dynArrCount(pSExpList), 2);

    SExp **pExp = dynArrBegin(pSExpList);
    SExp *exp = *pExp;
    SExp **pExpect = dynArrNext(pSExpList, pExp);
    pointerManagerInit();
    Environment *penv = newInitEnv();
    const SExp *actual = evalDispatch(exp,penv);
    ck_assert(isSExpEqual(actual, *pExpect));
    envFree(penv);
    free(penv);
    pointerManagerFinalize();
    freeSExps(pSExpList);
} END_TEST

// primitive predicate test 4
START_TEST (test_Primitives_primPred4) {
    DynArr *pSExpList =
        parseSExps("(begin"
                   "  (define x #f)"
                   "  (list (symbol? x) (string? x) (integer? x)"
                   "        (boolean? x) (null? x) (pair? x))"
                   ")"
                   "(#f #f #f #t #f #f)", stderr);
    ck_assert_ptr_ne(pSExpList, NULL);
    ck_assert_int_eq(dynArrCount(pSExpList), 2);

    SExp **pExp = dynArrBegin(pSExpList);
    SExp *exp = *pExp;
    SExp **pExpect = dynArrNext(pSExpList, pExp);
    pointerManagerInit();
    Environment *penv = newInitEnv();
    const SExp *actual = evalDispatch(exp,penv);
    ck_assert(isSExpEqual(actual, *pExpect));
    envFree(penv);
    free(penv);
    pointerManagerFinalize();
    freeSExps(pSExpList);
} END_TEST

// primitive predicate test 5
START_TEST (test_Primitives_primPred5) {
    DynArr *pSExpList =
        parseSExps("(begin"
                   "  (define x '())"
                   "  (list (symbol? x) (string? x) (integer? x)"
                   "        (boolean? x) (null? x) (pair? x))"
                   ")"
                   "(#f #f #f #f #t #f)", stderr);
    ck_assert_ptr_ne(pSExpList, NULL);
    ck_assert_int_eq(dynArrCount(pSExpList), 2);

    SExp **pExp = dynArrBegin(pSExpList);
    SExp *exp = *pExp;
    SExp **pExpect = dynArrNext(pSExpList, pExp);
    pointerManagerInit();
    Environment *penv = newInitEnv();
    const SExp *actual = evalDispatch(exp,penv);
    ck_assert(isSExpEqual(actual, *pExpect));
    envFree(penv);
    free(penv);
    pointerManagerFinalize();
    freeSExps(pSExpList);
} END_TEST

// primitive predicate test 6
START_TEST (test_Primitives_primPred6) {
    DynArr *pSExpList =
        parseSExps("(begin"
                   "  (define x '(a b))"
                   "  (list (symbol? x) (string? x) (integer? x)"
                   "        (boolean? x) (null? x) (pair? x))"
                   ")"
                   "(#f #f #f #f #f #t)", stderr);
    ck_assert_ptr_ne(pSExpList, NULL);
    ck_assert_int_eq(dynArrCount(pSExpList), 2);

    SExp **pExp = dynArrBegin(pSExpList);
    SExp *exp = *pExp;
    SExp **pExpect = dynArrNext(pSExpList, pExp);
    pointerManagerInit();
    Environment *penv = newInitEnv();
    const SExp *actual = evalDispatch(exp,penv);
    ck_assert(isSExpEqual(actual, *pExpect));
    envFree(penv);
    free(penv);
    pointerManagerFinalize();
    freeSExps(pSExpList);
} END_TEST

// primitive "="
START_TEST (test_Primitives_primEQ1) {
    DynArr *pSExpList = parseSExps("(= 10 (+ 2 8))", stderr);
    ck_assert_ptr_ne(pSExpList, NULL);
    ck_assert_int_eq(dynArrCount(pSExpList), 1);

    SExp **pExp = dynArrBegin(pSExpList);
    SExp *exp = *pExp;
    pointerManagerInit();
    Environment *penv = newInitEnv();
    const SExp *actual = evApplication(exp,penv);
    const SExp *expect = newBool(1);
    ck_assert(isSExpEqual(expect,actual));
    envFree(penv);
    free(penv);
    pointerManagerFinalize();
    freeSExps(pSExpList);
} END_TEST

START_TEST (test_Primitives_primEQ2) {
    DynArr *pSExpList = parseSExps("(= 11 (+ 2 8))", stderr);
    ck_assert_ptr_ne(pSExpList, NULL);
    ck_assert_int_eq(dynArrCount(pSExpList), 1);

    SExp **pExp = dynArrBegin(pSExpList);
    SExp *exp = *pExp;
    pointerManagerInit();
    Environment *penv = newInitEnv();
    const SExp *actual = evApplication(exp,penv);
    const SExp *expect = newBool(0);
    ck_assert(isSExpEqual(expect,actual));
    envFree(penv);
    free(penv);
    pointerManagerFinalize();
    freeSExps(pSExpList);
} END_TEST

Suite * primitivesSuite(void) {
    Suite *s;
    TCase *tc_core;

    tc_core = tcase_create("Core");

    tcase_add_test(tc_core, test_Primitives_plus);
    tcase_add_test(tc_core, test_Primitives_minus);
    tcase_add_test(tc_core, test_Primitives_mult);
    tcase_add_test(tc_core, test_Primitives_cons);
    tcase_add_test(tc_core, test_Primitives_car);
    tcase_add_test(tc_core, test_Primitives_cdr);
    tcase_add_test(tc_core, test_Primitives_list);

    tcase_add_test(tc_core, test_Primitives_primPred1);
    tcase_add_test(tc_core, test_Primitives_primPred2);
    tcase_add_test(tc_core, test_Primitives_primPred3);
    tcase_add_test(tc_core, test_Primitives_primPred4);
    tcase_add_test(tc_core, test_Primitives_primPred5);
    tcase_add_test(tc_core, test_Primitives_primPred6);

    tcase_add_test(tc_core, test_Primitives_primEQ1);
    tcase_add_test(tc_core, test_Primitives_primEQ2);

    s = suite_create("Primitives");
    suite_add_tcase(s, tc_core);
    return s;
}
