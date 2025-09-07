#pragma once

/* --- Console arguments parser --- */
#define __BeginParseConsoleArguments__(printHelpFunction) \
  if (argc < 1 || (argc == 2 && (!strcmp(argv[1], "--help") || !strcmp(argv[1], "/?") \
  || !strcmp(argv[1], "/h")))) { printHelpFunction(); return 1; } \
  for (int ArgID = 1; ArgID < argc; ArgID++) { const char* Arg = argv[ArgID];

#define __OnArgument(Name) if (!strcmp(Arg, Name))
#define __ArgValue (argc > ArgID + 1 ? argv[++ArgID] : "")
#define __EndParseConsoleArguments__ else { printf("ERROR: Unknown argument\n"); return 1; } }