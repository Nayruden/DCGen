NAME = simple
TARGETS = simple

BINDIR = .

UNAME := $(shell uname)

SRCS = $(TARGETS:=.cpp)
OBJS = $(SRCS:.cpp=.o)

CXX = g++
CPPFLAGS += -Wall

ifeq ($(UNAME), Darwin)
  CPPFLAGS += -DDD_DARWIN -DDD_POSIX
  CLINKFLAGS += -dynamiclib
  EXT = .dylib
else
  CLINKFLAGS += -shared
  ifeq ($(findstring CYGWIN, $(UNAME)), CYGWIN)
    CPPFLAGS += -DDD_WINDOWS
    EXT = .dll
  else
  	CPPFLAGS += -DDD_LINUX -DDD_POSIX
    EXT = .so
  endif
endif

OUTPUT := lib$(NAME)$(EXT)
FINAL := $(BINDIR)/$(OUTPUT)

all: $(OUTPUT)

$(OUTPUT) : $(OBJS)
	$(CXX) $(CLINKFLAGS) -o $@ $^ 

clean:
	$(RM) $(OUTPUT) $(FINAL) $(OBJS)

.PHONY: all clean
