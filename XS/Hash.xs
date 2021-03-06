#include "ppport.h"

## we want hv_fetch but with the U32 hash argument of hv_fetch_ent, so do it ourselves...
#ifdef hv_common_key_len
#define CXSA_HASH_FETCH(hv, key, len, hash) hv_common_key_len((hv), (key), (len), HV_FETCH_JUST_SV, NULL, (hash))
#else
#define CXSA_HASH_FETCH(hv, key, len, hash) hv_fetch(hv, key, len, 0)
#endif

#ifndef croak_xs_usage
#define croak_xs_usage(cv,msg) croak(aTHX_ "Usage: %s(%s)", GvNAME(CvGV(cv)), msg)
#endif

MODULE = Class::XSAccessor        PACKAGE = Class::XSAccessor
PROTOTYPES: DISABLE

void
getter_init(self)
    SV* self;
  ALIAS:
  INIT:
    /* Get the const hash key struct from the global storage */
    /* ix is the magic integer variable that is set by the perl guts for us.
     * We uses it to identify the currently running alias of the accessor. Gollum! */
    const autoxs_hashkey readfrom = CXSAccessor_hashkeys[ix];
    SV** svp;
  PPCODE:
    CXA_CHECK_HASH(self);
    CXAH_OPTIMIZE_ENTERSUB(getter);
    if ((svp = CXSA_HASH_FETCH((HV *)SvRV(self), readfrom.key, readfrom.len, readfrom.hash)))
      PUSHs(*svp);
    else
      XSRETURN_UNDEF;

void
getter(self)
    SV* self;
  ALIAS:
  INIT:
    /* Get the const hash key struct from the global storage */
    /* ix is the magic integer variable that is set by the perl guts for us.
     * We uses it to identify the currently running alias of the accessor. Gollum! */
    const autoxs_hashkey readfrom = CXSAccessor_hashkeys[ix];
    SV** svp;
  PPCODE:
    CXA_CHECK_HASH(self);
    if ((svp = CXSA_HASH_FETCH((HV *)SvRV(self), readfrom.key, readfrom.len, readfrom.hash)))
      PUSHs(*svp);
    else
      XSRETURN_UNDEF;


void
lvalue_accessor_init(self)
    SV* self;
  ALIAS:
  INIT:
    /* Get the const hash key struct from the global storage */
    /* ix is the magic integer variable that is set by the perl guts for us.
     * We uses it to identify the currently running alias of the accessor. Gollum! */
    const autoxs_hashkey readfrom = CXSAccessor_hashkeys[ix];
    SV** svp;
    SV* sv;
  PPCODE:
    CXA_CHECK_HASH(self);
    CXAH_OPTIMIZE_ENTERSUB(lvalue_accessor);
    if ((svp = CXSA_HASH_FETCH((HV *)SvRV(self), readfrom.key, readfrom.len, readfrom.hash))) {
      sv = *svp;
      sv_upgrade(sv, SVt_PVLV);
      sv_magic(sv, 0, PERL_MAGIC_ext, Nullch, 0);
      SvSMAGICAL_on(sv);
      LvTYPE(sv) = '~';
      LvTARG(sv) = SvREFCNT_inc(sv);
      SvMAGIC(sv)->mg_virtual = &cxsa_lvalue_acc_magic_vtable;
      ST(0) = sv;
      XSRETURN(1);
    }
    else
      XSRETURN_UNDEF;

void
lvalue_accessor(self)
    SV* self;
  ALIAS:
  INIT:
    /* Get the const hash key struct from the global storage */
    /* ix is the magic integer variable that is set by the perl guts for us.
     * We uses it to identify the currently running alias of the accessor. Gollum! */
    const autoxs_hashkey readfrom = CXSAccessor_hashkeys[ix];
    SV** svp;
    SV* sv;
  PPCODE:
    CXA_CHECK_HASH(self);
    if ((svp = CXSA_HASH_FETCH((HV *)SvRV(self), readfrom.key, readfrom.len, readfrom.hash))) {
      sv = *svp;
      sv_upgrade(sv, SVt_PVLV);
      sv_magic(sv, 0, PERL_MAGIC_ext, Nullch, 0);
      SvSMAGICAL_on(sv);
      LvTYPE(sv) = '~';
      SvREFCNT_inc(sv);
      LvTARG(sv) = SvREFCNT_inc(sv);
      SvMAGIC(sv)->mg_virtual = &cxsa_lvalue_acc_magic_vtable;
      ST(0) = sv;
      XSRETURN(1);
    }
    else
      XSRETURN_UNDEF;

void
setter_init(self, newvalue)
    SV* self;
    SV* newvalue;
  ALIAS:
  INIT:
    /* Get the const hash key struct from the global storage */
    /* ix is the magic integer variable that is set by the perl guts for us.
     * We uses it to identify the currently running alias of the accessor. Gollum! */
    const autoxs_hashkey readfrom = CXSAccessor_hashkeys[ix];
  PPCODE:
    CXA_CHECK_HASH(self);
    CXAH_OPTIMIZE_ENTERSUB(setter);
    if (NULL == hv_store((HV*)SvRV(self), readfrom.key, readfrom.len, newSVsv(newvalue), readfrom.hash))
      croak("Failed to write new value to hash.");
    PUSHs(newvalue);

void
setter(self, newvalue)
    SV* self;
    SV* newvalue;
  ALIAS:
  INIT:
    /* Get the const hash key struct from the global storage */
    /* ix is the magic integer variable that is set by the perl guts for us.
     * We uses it to identify the currently running alias of the accessor. Gollum! */
    const autoxs_hashkey readfrom = CXSAccessor_hashkeys[ix];
  PPCODE:
    CXA_CHECK_HASH(self);
    if (NULL == hv_store((HV*)SvRV(self), readfrom.key, readfrom.len, newSVsv(newvalue), readfrom.hash))
      croak("Failed to write new value to hash.");
    PUSHs(newvalue);

void
array_setter_init(self, ...)
    SV* self;
  ALIAS:
  INIT:
    /* NOTE: This method is for Class::Accessor compatibility only. It's not
     *       part of the normal API! */
    /* Get the const hash key struct from the global storage */
    /* ix is the magic integer variable that is set by the perl guts for us.
     * We uses it to identify the currently running alias of the accessor. Gollum! */
    SV* newvalue = NULL; /* squelch may-be-used-uninitialized warning that doesn't apply */
    SV ** hashAssignRes;
    const autoxs_hashkey readfrom = CXSAccessor_hashkeys[ix];
  PPCODE:
    CXA_CHECK_HASH(self);
    CXAH_OPTIMIZE_ENTERSUB(array_setter);
    if (items == 2) {
      newvalue = newSVsv(ST(1));
    }
    else if (items > 2) {
      I32 i;
      AV* tmp = newAV();
      av_extend(tmp, items-1);
      for (i = 1; i < items; ++i) {
        newvalue = newSVsv(ST(i));
        if (!av_store(tmp, i-1, newvalue)) {
          SvREFCNT_dec(newvalue);
          croak("Failure to store value in array");
        }
      }
      newvalue = newRV_noinc((SV*) tmp);
    }
    else {
      croak_xs_usage(cv, "self, newvalue(s)");
    }

    if ((hashAssignRes = hv_store((HV*)SvRV(self), readfrom.key, readfrom.len, newvalue, readfrom.hash))) {
      PUSHs(*hashAssignRes);
    }
    else {
      SvREFCNT_dec(newvalue);
      croak("Failed to write new value to hash.");
    }

void
array_setter(self, ...)
    SV* self;
  ALIAS:
  INIT:
    /* NOTE: This method is for Class::Accessor compatibility only. It's not
     *       part of the normal API! */
    /* Get the const hash key struct from the global storage */
    /* ix is the magic integer variable that is set by the perl guts for us.
     * We uses it to identify the currently running alias of the accessor. Gollum! */
    SV* newvalue = NULL; /* squelch may-be-used-uninitialized warning that doesn't apply */
    SV ** hashAssignRes;
    const autoxs_hashkey readfrom = CXSAccessor_hashkeys[ix];
  PPCODE:
    CXA_CHECK_HASH(self);
    if (items == 2) {
      newvalue = newSVsv(ST(1));
    }
    else if (items > 2) {
      I32 i;
      AV* tmp = newAV();
      av_extend(tmp, items-1);
      for (i = 1; i < items; ++i) {
        newvalue = newSVsv(ST(i));
        if (!av_store(tmp, i-1, newvalue)) {
          SvREFCNT_dec(newvalue);
          croak("Failure to store value in array");
        }
      }
      newvalue = newRV_noinc((SV*) tmp);
    }
    else {
      croak_xs_usage(cv, "self, newvalue(s)");
    }

    if ((hashAssignRes = hv_store((HV*)SvRV(self), readfrom.key, readfrom.len, newvalue, readfrom.hash))) {
      PUSHs(*hashAssignRes);
    }
    else {
      SvREFCNT_dec(newvalue);
      croak("Failed to write new value to hash.");
    }

void
chained_setter_init(self, newvalue)
    SV* self;
    SV* newvalue;
  ALIAS:
  INIT:
    /* Get the const hash key struct from the global storage */
    /* ix is the magic integer variable that is set by the perl guts for us.
     * We uses it to identify the currently running alias of the accessor. Gollum! */
    const autoxs_hashkey readfrom = CXSAccessor_hashkeys[ix];
  PPCODE:
    CXA_CHECK_HASH(self);
    CXAH_OPTIMIZE_ENTERSUB(chained_setter);
    if (NULL == hv_store((HV*)SvRV(self), readfrom.key, readfrom.len, newSVsv(newvalue), readfrom.hash))
      croak("Failed to write new value to hash.");
    PUSHs(self);

void
chained_setter(self, newvalue)
    SV* self;
    SV* newvalue;
  ALIAS:
  INIT:
    /* Get the const hash key struct from the global storage */
    /* ix is the magic integer variable that is set by the perl guts for us.
     * We uses it to identify the currently running alias of the accessor. Gollum! */
    const autoxs_hashkey readfrom = CXSAccessor_hashkeys[ix];
  PPCODE:
    CXA_CHECK_HASH(self);
    if (NULL == hv_store((HV*)SvRV(self), readfrom.key, readfrom.len, newSVsv(newvalue), readfrom.hash))
      croak("Failed to write new value to hash.");
    PUSHs(self);

void
accessor_init(self, ...)
    SV* self;
  ALIAS:
  INIT:
    /* Get the const hash key struct from the global storage */
    /* ix is the magic integer variable that is set by the perl guts for us.
     * We uses it to identify the currently running alias of the accessor. Gollum! */
    const autoxs_hashkey readfrom = CXSAccessor_hashkeys[ix];
    SV** svp;
  PPCODE:
    CXA_CHECK_HASH(self);
    CXAH_OPTIMIZE_ENTERSUB(accessor);
    if (items > 1) {
      SV* newvalue = ST(1);
      if (NULL == hv_store((HV*)SvRV(self), readfrom.key, readfrom.len, newSVsv(newvalue), readfrom.hash))
        croak("Failed to write new value to hash.");
      PUSHs(newvalue);
    }
    else {
      if ((svp = CXSA_HASH_FETCH((HV *)SvRV(self), readfrom.key, readfrom.len, readfrom.hash)))
        PUSHs(*svp);
      else
        XSRETURN_UNDEF;
    }

void
accessor(self, ...)
    SV* self;
  ALIAS:
  INIT:
    /* Get the const hash key struct from the global storage */
    /* ix is the magic integer variable that is set by the perl guts for us.
     * We uses it to identify the currently running alias of the accessor. Gollum! */
    const autoxs_hashkey readfrom = CXSAccessor_hashkeys[ix];
    SV** svp;
  PPCODE:
    CXA_CHECK_HASH(self);
    if (items > 1) {
      SV* newvalue = ST(1);
      if (NULL == hv_store((HV*)SvRV(self), readfrom.key, readfrom.len, newSVsv(newvalue), readfrom.hash))
        croak("Failed to write new value to hash.");
      PUSHs(newvalue);
    }
    else {
      if ((svp = CXSA_HASH_FETCH((HV *)SvRV(self), readfrom.key, readfrom.len, readfrom.hash)))
        PUSHs(*svp);
      else
        XSRETURN_UNDEF;
    }

void
array_accessor_init(self, ...)
    SV* self;
  ALIAS:
  INIT:
    /* NOTE: This method is for Class::Accessor compatibility only. It's not
     *       part of the normal API! */
    /* Get the const hash key struct from the global storage */
    /* ix is the magic integer variable that is set by the perl guts for us.
     * We uses it to identify the currently running alias of the accessor. Gollum! */
    SV ** hashAssignRes;
    const autoxs_hashkey readfrom = CXSAccessor_hashkeys[ix];
  PPCODE:
    CXA_CHECK_HASH(self);
    CXAH_OPTIMIZE_ENTERSUB(array_accessor);
    if (items == 1) {
      SV** svp;
      if ((svp = CXSA_HASH_FETCH((HV *)SvRV(self), readfrom.key, readfrom.len, readfrom.hash)))
        PUSHs(*svp);
      else
        XSRETURN_UNDEF;
    }
    else { /* writing branch */
      SV* newvalue;
      if (items == 2) {
        newvalue = newSVsv(ST(1));
      }
      else { /* items > 2 */
        I32 i;
        AV* tmp = newAV();
        av_extend(tmp, items-1);
        for (i = 1; i < items; ++i) {
          newvalue = newSVsv(ST(i));
          if (!av_store(tmp, i-1, newvalue)) {
            SvREFCNT_dec(newvalue);
            croak("Failure to store value in array");
          }
        }
        newvalue = newRV_noinc((SV*) tmp);
      }

      if ((hashAssignRes = hv_store((HV*)SvRV(self), readfrom.key, readfrom.len, newvalue, readfrom.hash))) {
        PUSHs(*hashAssignRes);
      }
      else {
        SvREFCNT_dec(newvalue);
        croak("Failed to write new value to hash.");
      }
    } /* end writing branch */

void
array_accessor(self, ...)
    SV* self;
  ALIAS:
  INIT:
    /* NOTE: This method is for Class::Accessor compatibility only. It's not
     *       part of the normal API! */
    /* Get the const hash key struct from the global storage */
    /* ix is the magic integer variable that is set by the perl guts for us.
     * We uses it to identify the currently running alias of the accessor. Gollum! */
    SV ** hashAssignRes;
    const autoxs_hashkey readfrom = CXSAccessor_hashkeys[ix];
  PPCODE:
    CXA_CHECK_HASH(self);
    if (items == 1) {
      SV** svp;
      if ((svp = CXSA_HASH_FETCH((HV *)SvRV(self), readfrom.key, readfrom.len, readfrom.hash)))
        PUSHs(*svp);
      else
        XSRETURN_UNDEF;
    }
    else { /* writing branch */
      SV* newvalue;
      if (items == 2) {
        newvalue = newSVsv(ST(1));
      }
      else { /* items > 2 */
        I32 i;
        AV* tmp = newAV();
        av_extend(tmp, items-1);
        for (i = 1; i < items; ++i) {
          newvalue = newSVsv(ST(i));
          if (!av_store(tmp, i-1, newvalue)) {
            SvREFCNT_dec(newvalue);
            croak("Failure to store value in array");
          }
        }
        newvalue = newRV_noinc((SV*) tmp);
      }

      if ((hashAssignRes = hv_store((HV*)SvRV(self), readfrom.key, readfrom.len, newvalue, readfrom.hash))) {
        PUSHs(*hashAssignRes);
      }
      else {
        SvREFCNT_dec(newvalue);
        croak("Failed to write new value to hash.");
      }
    } /* end writing branch */

void
chained_accessor_init(self, ...)
    SV* self;
  ALIAS:
  INIT:
    /* Get the const hash key struct from the global storage */
    /* ix is the magic integer variable that is set by the perl guts for us.
     * We uses it to identify the currently running alias of the accessor. Gollum! */
    const autoxs_hashkey readfrom = CXSAccessor_hashkeys[ix];
    SV** svp;
  PPCODE:
    CXA_CHECK_HASH(self);
    CXAH_OPTIMIZE_ENTERSUB(chained_accessor);
    if (items > 1) {
      SV* newvalue = ST(1);
      if (NULL == hv_store((HV*)SvRV(self), readfrom.key, readfrom.len, newSVsv(newvalue), readfrom.hash))
        croak("Failed to write new value to hash.");
      PUSHs(self);
    }
    else {
      if ((svp = CXSA_HASH_FETCH((HV *)SvRV(self), readfrom.key, readfrom.len, readfrom.hash)))
        PUSHs(*svp);
      else
        XSRETURN_UNDEF;
    }

void
chained_accessor(self, ...)
    SV* self;
  ALIAS:
  INIT:
    /* Get the const hash key struct from the global storage */
    /* ix is the magic integer variable that is set by the perl guts for us.
     * We uses it to identify the currently running alias of the accessor. Gollum! */
    const autoxs_hashkey readfrom = CXSAccessor_hashkeys[ix];
    SV** svp;
  PPCODE:
    CXA_CHECK_HASH(self);
    if (items > 1) {
      SV* newvalue = ST(1);
      if (NULL == hv_store((HV*)SvRV(self), readfrom.key, readfrom.len, newSVsv(newvalue), readfrom.hash))
        croak("Failed to write new value to hash.");
      PUSHs(self);
    }
    else {
      if ((svp = CXSA_HASH_FETCH((HV *)SvRV(self), readfrom.key, readfrom.len, readfrom.hash)))
        PUSHs(*svp);
      else
        XSRETURN_UNDEF;
    }

void
predicate_init(self)
    SV* self;
  ALIAS:
  INIT:
    /* Get the const hash key struct from the global storage */
    /* ix is the magic integer variable that is set by the perl guts for us.
     * We uses it to identify the currently running alias of the accessor. Gollum! */
    const autoxs_hashkey readfrom = CXSAccessor_hashkeys[ix];
    SV** svp;
  PPCODE:
    CXA_CHECK_HASH(self);
    CXAH_OPTIMIZE_ENTERSUB(predicate);
    if ( ((svp = CXSA_HASH_FETCH((HV *)SvRV(self), readfrom.key, readfrom.len, readfrom.hash))) && SvOK(*svp) )
      XSRETURN_YES;
    else
      XSRETURN_NO;

void
predicate(self)
    SV* self;
  ALIAS:
  INIT:
    /* Get the const hash key struct from the global storage */
    /* ix is the magic integer variable that is set by the perl guts for us.
     * We uses it to identify the currently running alias of the accessor. Gollum! */
    const autoxs_hashkey readfrom = CXSAccessor_hashkeys[ix];
    SV** svp;
  PPCODE:
    CXA_CHECK_HASH(self);
    if ( ((svp = CXSA_HASH_FETCH((HV *)SvRV(self), readfrom.key, readfrom.len, readfrom.hash))) && SvOK(*svp) )
      XSRETURN_YES;
    else
      XSRETURN_NO;

void
constructor_init(class, ...)
    SV* class;
  PREINIT:
    int iStack;
    HV* hash;
    SV* obj;
    const char* classname;
  PPCODE:
    CXAH_OPTIMIZE_ENTERSUB(constructor);

    classname = SvROK(class) ? sv_reftype(SvRV(class), 1) : SvPV_nolen_const(class);
    hash = newHV();
    obj = sv_bless(newRV_noinc((SV *)hash), gv_stashpv(classname, 1));

    if (items > 1) {
      /* if @_ - 1 (for $class) is even: most compilers probably convert items % 2 into this, but just in case */
      if (items & 1) {
        for (iStack = 1; iStack < items; iStack += 2) {
          /* we could check for the hv_store_ent return value, but perl doesn't in this situation (see pp_anonhash) */
          (void)hv_store_ent(hash, ST(iStack), newSVsv(ST(iStack+1)), 0);
        }
      } else {
        croak("Uneven number of arguments to constructor.");
      }
    }

    PUSHs(sv_2mortal(obj));

void
constructor(class, ...)
    SV* class;
  PREINIT:
    int iStack;
    HV* hash;
    SV* obj;
    const char* classname;
  PPCODE:
    classname = SvROK(class) ? sv_reftype(SvRV(class), 1) : SvPV_nolen_const(class);
    hash = newHV();
    obj = sv_bless(newRV_noinc((SV *)hash), gv_stashpv(classname, 1));

    if (items > 1) {
      /* if @_ - 1 (for $class) is even: most compilers probably convert items % 2 into this, but just in case */
      if (items & 1) {
        for (iStack = 1; iStack < items; iStack += 2) {
          /* we could check for the hv_store_ent return value, but perl doesn't in this situation (see pp_anonhash) */
          (void)hv_store_ent(hash, ST(iStack), newSVsv(ST(iStack+1)), 0);
        }
      } else {
        croak("Uneven number of arguments to constructor.");
      }
    }

    PUSHs(sv_2mortal(obj));

void
constant_false_init(self)
  SV *self;
  PPCODE:
    PERL_UNUSED_VAR(self);
    CXAH_OPTIMIZE_ENTERSUB(constant_false);
    {
      XSRETURN_NO;
    }

void
constant_false(self)
  SV *self;
  PPCODE:
    PERL_UNUSED_VAR(self);
    {
      XSRETURN_NO;
    }
   
void
constant_true_init(self)
    SV* self;
  PPCODE:
    PERL_UNUSED_VAR(self);
    CXAH_OPTIMIZE_ENTERSUB(constant_true);
    {
      XSRETURN_YES;
    }

void
constant_true(self)
    SV* self;
  PPCODE:
    PERL_UNUSED_VAR(self);
    {
      XSRETURN_YES;
    }

void
test_init(self, ...)
    SV* self;
  ALIAS:
  INIT:
    /* Get the const hash key struct from the global storage */
    /* ix is the magic integer variable that is set by the perl guts for us.
     * We uses it to identify the currently running alias of the accessor. Gollum! */
    const autoxs_hashkey readfrom = CXSAccessor_hashkeys[ix];
    SV** svp;
  PPCODE:
    CXA_CHECK_HASH(self);
    warn("cxah: accessor: inside test_init");
    CXAH_OPTIMIZE_ENTERSUB_TEST(test);
    if (items > 1) {
      SV* newvalue = ST(1);
      if (NULL == hv_store((HV*)SvRV(self), readfrom.key, readfrom.len, newSVsv(newvalue), readfrom.hash))
        croak("Failed to write new value to hash.");
      PUSHs(newvalue);
    }
    else {
      if ((svp = CXSA_HASH_FETCH((HV *)SvRV(self), readfrom.key, readfrom.len, readfrom.hash)))
        PUSHs(*svp);
      else
        XSRETURN_UNDEF;
    }

void
test(self, ...)
    SV* self;
  ALIAS:
  INIT:
    /* Get the const hash key struct from the global storage */
    /* ix is the magic integer variable that is set by the perl guts for us.
     * We uses it to identify the currently running alias of the accessor. Gollum! */
    const autoxs_hashkey readfrom = CXSAccessor_hashkeys[ix];
    SV** svp;
  PPCODE:
    CXA_CHECK_HASH(self);
    warn("cxah: accessor: inside test");
    if (items > 1) {
      SV* newvalue = ST(1);
      if (NULL == hv_store((HV*)SvRV(self), readfrom.key, readfrom.len, newSVsv(newvalue), readfrom.hash))
        croak("Failed to write new value to hash.");
      PUSHs(newvalue);
    }
    else {
      if ((svp = CXSA_HASH_FETCH((HV *)SvRV(self), readfrom.key, readfrom.len, readfrom.hash)))
        PUSHs(*svp);
      else
        XSRETURN_UNDEF;
    }

void
newxs_getter(name, key)
  char* name;
  char* key;
  PPCODE:
    INSTALL_NEW_CV_HASH_OBJ(name, CXAH(getter_init), key);

void
newxs_lvalue_accessor(name, key)
    char* name;
    char* key;
  INIT:
    CV *cv;
  PPCODE:
    INSTALL_NEW_CV_HASH_OBJ(name, CXAH(lvalue_accessor_init), key);
    /* Make the CV lvalue-able. "cv" was set by the previous macro */
    CvLVALUE_on(cv);

void
newxs_setter(name, key, chained)
  char* name;
  char* key;
  bool chained;
  PPCODE:
    if (chained)
      INSTALL_NEW_CV_HASH_OBJ(name, CXAH(chained_setter_init), key);
    else
      INSTALL_NEW_CV_HASH_OBJ(name, CXAH(setter_init), key);

void
newxs_accessor(name, key, chained)
  char* name;
  char* key;
  bool chained;
  PPCODE:
    if (chained)
      INSTALL_NEW_CV_HASH_OBJ(name, CXAH(chained_accessor_init), key);
    else
      INSTALL_NEW_CV_HASH_OBJ(name, CXAH(accessor_init), key);

void
newxs_predicate(name, key)
  char* name;
  char* key;
  PPCODE:
    INSTALL_NEW_CV_HASH_OBJ(name, CXAH(predicate_init), key);

void
newxs_constructor(name)
  char* name;
  PPCODE:
    INSTALL_NEW_CV(name, CXAH(constructor_init));

void
newxs_boolean(name, truth)
  char* name;
  bool truth;
  PPCODE:
    if (truth)
      INSTALL_NEW_CV(name, CXAH(constant_true_init));
    else
      INSTALL_NEW_CV(name, CXAH(constant_false_init));

void
newxs_test(name, key)
  char* name;
  char* key;
  PPCODE:
      INSTALL_NEW_CV_HASH_OBJ(name, CXAH(test_init), key);


void
_newxs_compat_setter(name, key)
  char* name;
  char* key;
  PPCODE:
    /* WARNING: If this is called in your code, you're doing it WRONG! */
    INSTALL_NEW_CV_HASH_OBJ(name, CXAH(array_setter_init), key);

void
_newxs_compat_accessor(name, key)
  char* name;
  char* key;
  PPCODE:
    /* WARNING: If this is called in your code, you're doing it WRONG! */
    INSTALL_NEW_CV_HASH_OBJ(name, CXAH(array_accessor_init), key);

