#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>
typedef struct _Dart_Handle* Dart_Handle;

typedef struct DartCObject DartCObject;

typedef int64_t DartPort;

typedef bool (*DartPostCObjectFnType)(DartPort port_id, void *message);

typedef struct wire_uint_8_list {
  uint8_t *ptr;
  int32_t len;
} wire_uint_8_list;

typedef struct wire_KeyPair {
  const void *ptr;
} wire_KeyPair;

typedef struct wire_XelisKeyPair {
  struct wire_KeyPair key_pair;
} wire_XelisKeyPair;

typedef struct wire_Signature {
  const void *ptr;
} wire_Signature;

typedef struct DartCObject *WireSyncReturn;

void store_dart_post_cobject(DartPostCObjectFnType ptr);

Dart_Handle get_dart_object(uintptr_t ptr);

void drop_dart_object(uintptr_t ptr);

uintptr_t new_dart_opaque(Dart_Handle handle);

intptr_t init_frb_dart_api_dl(void *obj);

void wire_create_key_pair(int64_t port_, struct wire_uint_8_list *seed);

void wire_set_network_to_mainnet(int64_t port_);

void wire_set_network_to_testnet(int64_t port_);

void wire_set_network_to_dev(int64_t port_);

void wire_get_address__method__XelisKeyPair(int64_t port_, struct wire_XelisKeyPair *that);

void wire_get_seed__method__XelisKeyPair(int64_t port_,
                                         struct wire_XelisKeyPair *that,
                                         uintptr_t language_index);

void wire_sign__method__XelisKeyPair(int64_t port_,
                                     struct wire_XelisKeyPair *that,
                                     struct wire_uint_8_list *data);

void wire_verify_signature__method__XelisKeyPair(int64_t port_,
                                                 struct wire_XelisKeyPair *that,
                                                 struct wire_uint_8_list *hash,
                                                 struct wire_Signature signature);

void wire_get_estimated_fees__method__XelisKeyPair(int64_t port_,
                                                   struct wire_XelisKeyPair *that,
                                                   struct wire_uint_8_list *address,
                                                   uint64_t amount,
                                                   struct wire_uint_8_list *asset,
                                                   uint64_t nonce);

void wire_create_tx__method__XelisKeyPair(int64_t port_,
                                          struct wire_XelisKeyPair *that,
                                          struct wire_uint_8_list *address,
                                          uint64_t amount,
                                          struct wire_uint_8_list *asset,
                                          uint64_t balance,
                                          uint64_t nonce);

struct wire_KeyPair new_KeyPair(void);

struct wire_Signature new_Signature(void);

struct wire_XelisKeyPair *new_box_autoadd_xelis_key_pair_0(void);

struct wire_uint_8_list *new_uint_8_list_0(int32_t len);

void drop_opaque_KeyPair(const void *ptr);

const void *share_opaque_KeyPair(const void *ptr);

void drop_opaque_Signature(const void *ptr);

const void *share_opaque_Signature(const void *ptr);

void free_WireSyncReturn(WireSyncReturn ptr);

static int64_t dummy_method_to_enforce_bundling(void) {
    int64_t dummy_var = 0;
    dummy_var ^= ((int64_t) (void*) wire_create_key_pair);
    dummy_var ^= ((int64_t) (void*) wire_set_network_to_mainnet);
    dummy_var ^= ((int64_t) (void*) wire_set_network_to_testnet);
    dummy_var ^= ((int64_t) (void*) wire_set_network_to_dev);
    dummy_var ^= ((int64_t) (void*) wire_get_address__method__XelisKeyPair);
    dummy_var ^= ((int64_t) (void*) wire_get_seed__method__XelisKeyPair);
    dummy_var ^= ((int64_t) (void*) wire_sign__method__XelisKeyPair);
    dummy_var ^= ((int64_t) (void*) wire_verify_signature__method__XelisKeyPair);
    dummy_var ^= ((int64_t) (void*) wire_get_estimated_fees__method__XelisKeyPair);
    dummy_var ^= ((int64_t) (void*) wire_create_tx__method__XelisKeyPair);
    dummy_var ^= ((int64_t) (void*) new_KeyPair);
    dummy_var ^= ((int64_t) (void*) new_Signature);
    dummy_var ^= ((int64_t) (void*) new_box_autoadd_xelis_key_pair_0);
    dummy_var ^= ((int64_t) (void*) new_uint_8_list_0);
    dummy_var ^= ((int64_t) (void*) drop_opaque_KeyPair);
    dummy_var ^= ((int64_t) (void*) share_opaque_KeyPair);
    dummy_var ^= ((int64_t) (void*) drop_opaque_Signature);
    dummy_var ^= ((int64_t) (void*) share_opaque_Signature);
    dummy_var ^= ((int64_t) (void*) free_WireSyncReturn);
    dummy_var ^= ((int64_t) (void*) store_dart_post_cobject);
    dummy_var ^= ((int64_t) (void*) get_dart_object);
    dummy_var ^= ((int64_t) (void*) drop_dart_object);
    dummy_var ^= ((int64_t) (void*) new_dart_opaque);
    return dummy_var;
}