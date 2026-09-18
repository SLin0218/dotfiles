#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <dlfcn.h>
#include <stdint.h>

typedef uintptr_t RimeSessionId;
typedef int Bool;

#define RIME_STRUCT_INIT(Type, var) \
  ((var).data_size = sizeof(Type) - sizeof((var).data_size))

typedef struct rime_traits_t {
  int data_size;
  const char* shared_data_dir;
  const char* user_data_dir;
  const char* distribution_name;
  const char* distribution_code_name;
  const char* distribution_version;
  const char* app_name;
  const char** modules;
  int min_log_level;
  const char* log_dir;
  const char* prebuilt_data_dir;
  const char* staging_dir;
} RimeTraits;

typedef struct {
  int length;
  int cursor_pos;
  int sel_start;
  int sel_end;
  char* preedit;
} RimeComposition;

typedef struct rime_candidate_t {
  char* text;
  char* comment;
  void* reserved;
} RimeCandidate;

typedef struct {
  int page_size;
  int page_no;
  Bool is_last_page;
  int highlighted_candidate_index;
  int num_candidates;
  RimeCandidate* candidates;
  char* select_keys;
} RimeMenu;

typedef struct rime_commit_t {
  int data_size;
  char* text;
} RimeCommit;

typedef struct rime_context_t {
  int data_size;
  RimeComposition composition;
  RimeMenu menu;
  char* commit_text_preview;
  char** select_labels;
} RimeContext;

typedef struct rime_status_t {
  int data_size;
  char* schema_id;
  char* schema_name;
  Bool is_disabled;
  Bool is_composing;
  Bool is_ascii_mode;
  Bool is_full_shape;
  Bool is_simplified;
  Bool is_traditional;
  Bool is_ascii_punct;
} RimeStatus;

typedef struct rime_api_t {
  int data_size;
  void (*setup)(RimeTraits* traits);
  void (*set_notification_handler)(void* handler, void* context_object);
  void (*initialize)(RimeTraits* traits);
  void (*finalize)(void);
  Bool (*start_maintenance)(Bool full_check);
  Bool (*is_maintenance_mode)(void);
  void (*join_maintenance_thread)(void);
  void (*deployer_initialize)(RimeTraits* traits);
  Bool (*prebuild)(void);
  Bool (*deploy)(void);
  Bool (*deploy_schema)(const char* schema_file);
  Bool (*deploy_config_file)(const char* file_name, const char* version_key);
  Bool (*sync_user_data)(void);
  RimeSessionId (*create_session)(void);
  Bool (*find_session)(RimeSessionId session_id);
  Bool (*destroy_session)(RimeSessionId session_id);
  void (*cleanup_stale_sessions)(void);
  void (*cleanup_all_sessions)(void);
  Bool (*process_key)(RimeSessionId session_id, int keycode, int mask);
  Bool (*commit_composition)(RimeSessionId session_id);
  void (*clear_composition)(RimeSessionId session_id);
  Bool (*get_commit)(RimeSessionId session_id, RimeCommit* commit);
  Bool (*free_commit)(RimeCommit* commit);
  Bool (*get_context)(RimeSessionId session_id, RimeContext* context);
  Bool (*free_context)(RimeContext* ctx);
  Bool (*get_status)(RimeSessionId session_id, RimeStatus* status);
  Bool (*free_status)(RimeStatus* status);
  void (*set_option)(RimeSessionId session_id, const char* option, Bool value);
  Bool (*get_option)(RimeSessionId session_id, const char* option);
  void (*set_property)(RimeSessionId session_id, const char* prop, const char* value);
  Bool (*get_property)(RimeSessionId session_id, const char* prop, char* value, size_t buffer_size);
  void* get_schema_list;
  void* free_schema_list;
  Bool (*get_current_schema)(RimeSessionId session_id, char* schema_id, size_t buffer_size);
  Bool (*select_schema)(RimeSessionId session_id, const char* schema_id);
} RimeApi;

typedef RimeApi* (*RimeGetApiFunc)(void);

int main(int argc, char** argv) {
    if (argc < 3) {
        fprintf(stderr, "Usage: %s <schema_id> <input_keys...>\n", argv[0]);
        return 1;
    }
    const char* schema_id = argv[1];

    void* handle = dlopen("/Library/Input Methods/Squirrel.app/Contents/Frameworks/librime.1.dylib", RTLD_LAZY);
    if (!handle) {
        fprintf(stderr, "Cannot load librime: %s\n", dlerror());
        return 1;
    }

    RimeGetApiFunc rime_get_api = (RimeGetApiFunc)dlsym(handle, "rime_get_api");
    if (!rime_get_api) {
        fprintf(stderr, "Cannot find rime_get_api\n");
        return 1;
    }

    RimeApi* api = rime_get_api();
    if (!api) {
        fprintf(stderr, "api is null\n");
        return 1;
    }

    char cwd[1024];
    getcwd(cwd, sizeof(cwd));

    RimeTraits traits = {0};
    RIME_STRUCT_INIT(RimeTraits, traits);
    traits.shared_data_dir = cwd;
    traits.user_data_dir = cwd;
    traits.distribution_name = "Rime";
    traits.distribution_code_name = "Squirrel";
    traits.distribution_version = "test";
    traits.app_name = "rime.test";

    api->setup(&traits);
    api->initialize(&traits);

    if (api->start_maintenance(0)) {
        api->join_maintenance_thread();
    }

    RimeSessionId session = api->create_session();
    if (!session) {
        fprintf(stderr, "Failed to create session\n");
        return 1;
    }

    if (!api->select_schema(session, schema_id)) {
        fprintf(stderr, "Failed to select schema: %s\n", schema_id);
        return 1;
    }

    char cur_schema[64] = {0};
    api->get_current_schema(session, cur_schema, sizeof(cur_schema));
    printf("Active schema: %s\n", cur_schema);

    for (int i = 2; i < argc; i++) {
        const char* seq = argv[i];
        api->clear_composition(session);

        printf("\n--- Test Input [%s] ---\n", seq);
        for (const char* p = seq; *p; p++) {
            api->process_key(session, (int)*p, 0);
        }

        RimeCommit commit = {0};
        RIME_STRUCT_INIT(RimeCommit, commit);
        if (api->get_commit(session, &commit) && commit.text) {
            printf("  Direct Commit: %s\n", commit.text);
            api->free_commit(&commit);
        }

        RimeContext ctx = {0};
        RIME_STRUCT_INIT(RimeContext, ctx);
        if (api->get_context(session, &ctx)) {
            if (ctx.composition.preedit) {
                printf("  Preedit: %s\n", ctx.composition.preedit);
            }
            printf("  Candidates count: %d\n", ctx.menu.num_candidates);
            for (int j = 0; j < ctx.menu.num_candidates && j < 10; j++) {
                printf("    %d. %s  %s\n", j + 1,
                       ctx.menu.candidates[j].text ? ctx.menu.candidates[j].text : "",
                       ctx.menu.candidates[j].comment ? ctx.menu.candidates[j].comment : "");
            }
            api->free_context(&ctx);
        }
    }

    api->destroy_session(session);
    api->finalize();
    dlclose(handle);
    return 0;
}
