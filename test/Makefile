NAME = TestBinds
TARGETS = test

BINDIR = ./

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
    CPPFLAGS += -DDD_WINDOWS -DGLUT_DISABLE_ATEXIT_HACK
    $(error no win32/cygwin implementation yet)
    EXT = .dll
  else
  	CPPFLAGS += -DDD_LINUX -DDD_POSIX
    CPPFLAGS += $(shell pkg-config --cflags OIS OGRE)
    CLINKFLAGS += $(shell pkg-config --libs OIS OGRE)
    EXT = .so
  endif
endif

OUTPUT := lib$(NAME)$(EXT)
FINAL := $(BINDIR)/$(OUTPUT)

all: $(OUTPUT) cp

$(OUTPUT) : $(OBJS)
	$(CXX) $(CLINKFLAGS) -o $@ $^ 

cp : $(FINAL) #alias

$(FINAL) : $(OUTPUT)
	cp $^ $@

clean:
	$(RM) $(OUTPUT) $(FINAL) $(OBJS)

.PHONY: all cp clean
