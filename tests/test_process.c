#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "globvar.h"
#include "process.h"

#define LARGE_INPUT_SIZE (4U * 1024U * 1024U)

static int fail(const char *message)
{
    fprintf(stderr, "test_process: %s\n", message);
    return EXIT_FAILURE;
}

int main(void)
{
    char *large_input;
    char *cat_argv[] = {"/bin/cat", NULL};
    char *true_argv[] = {"/bin/true", NULL};

    g_ctx.logfp = stderr;
    signal(SIGPIPE, SIG_IGN);

    if (fs_execute_command(cat_argv, 1, "test input") < 0) {
        return fail("successful input pipe was rejected");
    }

    large_input = malloc(LARGE_INPUT_SIZE + 1U);
    if (!large_input) {
        return fail("large input allocation failed");
    }
    memset(large_input, 'x', LARGE_INPUT_SIZE);
    large_input[LARGE_INPUT_SIZE] = '\0';

    if (fs_execute_command(true_argv, 1, large_input) == 0) {
        free(large_input);
        return fail("broken input pipe was reported as successful");
    }

    free(large_input);
    return EXIT_SUCCESS;
}
