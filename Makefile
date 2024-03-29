#
# Originally contributed by Mladen Turk <mturk apache.org>
#
CC = cl.exe
LN = link.exe
AR = lib.exe
RC = rc.exe
SRCDIR = .

_CPU = x64
_LIB = lib

!IF !DEFINED(WINVER) || "$(WINVER)" == ""
WINVER = 0x0601
!ENDIF

!IF DEFINED(_STATIC_MSVCRT)
CRT_CFLAGS = -MT
EXTRA_LIBS =
!ELSE
CRT_CFLAGS = -MD
!ENDIF

CFLAGS = $(CFLAGS) -I$(SRCDIR)\c\include -I$(SRCDIR)\c\common
CFLAGS = $(CFLAGS) -DNDEBUG -DWIN32 -D_WIN32_WINNT=$(WINVER) -DWINVER=$(WINVER)
CFLAGS = $(CFLAGS) -D_CRT_SECURE_NO_DEPRECATE -D_CRT_NONSTDC_NO_DEPRECATE $(EXTRA_CFLAGS)

!IF DEFINED(_STATIC)
TARGET  = lib
PROJECT = brotli-1
ARFLAGS = /nologo /MACHINE:$(_CPU) $(EXTRA_ARFLAGS)
!ELSE
TARGET  = dll
CFLAGS  = $(CFLAGS) -DBROTLI_SHARED_COMPILATION -DBROTLICOMMON_SHARED_COMPILATION -DBROTLIDEC_SHARED_COMPILATION -DBROTLIENC_SHARED_COMPILATION
PROJECT = llibrotli-1
LDFLAGS = /nologo /INCREMENTAL:NO /OPT:REF /DLL /SUBSYSTEM:WINDOWS /MACHINE:$(_CPU) $(EXTRA_LDFLAGS)
!ENDIF

WORKDIR = $(_CPU)-rel-$(TARGET)
OUTPUT  = $(WORKDIR)\$(PROJECT).$(TARGET)
CLOPTS  = /c /nologo $(CRT_CFLAGS) -W3 -O2 -Ob2
RFLAGS  = /l 0x409 /n /d NDEBUG /d WIN32 /d WINNT /d WINVER=$(WINVER)
RFLAGS  = $(RFLAGS) /d _WIN32_WINNT=$(WINVER) $(EXTRA_RFLAGS)
LDLIBS  = kernel32.lib $(EXTRA_LIBS)

!IF DEFINED(_PDB)
PDBNAME = -Fd$(WORKDIR)\$(PROJECT)
OUTPDB  = /pdb:$(WORKDIR)\$(PROJECT).pdb
CLOPTS  = $(CLOPTS) -Zi
LDFLAGS = $(LDFLAGS) /DEBUG
!ENDIF

!IF DEFINED(_VENDOR_SFX)
RFLAGS = $(RFLAGS) /d _VENDOR_SFX=$(_VENDOR_SFX)
!ENDIF

!IF DEFINED(_VENDOR_NUM)
RFLAGS = $(RFLAGS) /d _VENDOR_NUM=$(_VENDOR_NUM)
!ENDIF

OBJECTS_CMN = \
	$(WORKDIR)\constants.obj \
	$(WORKDIR)\context.obj \
	$(WORKDIR)\dictionary.obj \
	$(WORKDIR)\platform.obj \
	$(WORKDIR)\transform.obj

OBJECTS_DEC = \
	$(WORKDIR)\bit_reader.obj \
	$(WORKDIR)\decode.obj \
	$(WORKDIR)\huffman.obj \
	$(WORKDIR)\state.obj

OBJECTS_ENC = \
	$(WORKDIR)\backward_references.obj \
	$(WORKDIR)\backward_references_hq.obj \
	$(WORKDIR)\bit_cost.obj \
	$(WORKDIR)\block_splitter.obj \
	$(WORKDIR)\brotli_bit_stream.obj \
	$(WORKDIR)\cluster.obj \
	$(WORKDIR)\command.obj \
	$(WORKDIR)\compress_fragment.obj \
	$(WORKDIR)\compress_fragment_two_pass.obj \
	$(WORKDIR)\dictionary_hash.obj \
	$(WORKDIR)\encode.obj \
	$(WORKDIR)\encoder_dict.obj \
	$(WORKDIR)\entropy_encode.obj \
	$(WORKDIR)\fast_log.obj \
	$(WORKDIR)\histogram.obj \
	$(WORKDIR)\literal_cost.obj \
	$(WORKDIR)\memory.obj \
	$(WORKDIR)\metablock.obj \
	$(WORKDIR)\static_dict.obj \
	$(WORKDIR)\utf8_util.obj


OBJECTS = \
	$(OBJECTS_CMN) \
	$(OBJECTS_DEC) \
	$(OBJECTS_ENC)

!IF "$(TARGET)" == "dll"
OBJECTS = $(OBJECTS) $(WORKDIR)\llibbrotli.res
!ENDIF

all : $(WORKDIR) $(OUTPUT)

$(WORKDIR):
	@-md $(WORKDIR)

{$(SRCDIR)\c\common}.c{$(WORKDIR)}.obj:
	$(CC) $(CLOPTS) $(CFLAGS) -Fo$(WORKDIR)\ $(PDBNAME) $<

{$(SRCDIR)\c\dec}.c{$(WORKDIR)}.obj:
	$(CC) $(CLOPTS) $(CFLAGS) -I$(SRCDIR)\c\dec -Fo$(WORKDIR)\ $(PDBNAME) $<

{$(SRCDIR)\c\enc}.c{$(WORKDIR)}.obj:
	$(CC) $(CLOPTS) $(CFLAGS) -I$(SRCDIR)\c\enc -Fo$(WORKDIR)\ $(PDBNAME) $<

{$(SRCDIR)}.rc{$(WORKDIR)}.res:
	$(RC) $(RFLAGS) /fo $@ $<

$(OUTPUT): $(OBJECTS)
!IF "$(TARGET)" == "dll"
	$(LN) $(LDFLAGS) $** $(LDLIBS) $(OUTPDB) /out:$(OUTPUT)
!ELSE
	$(AR) $(ARFLAGS) $** /out:$(OUTPUT)
!ENDIF

!IF !DEFINED(PREFIX) || "$(PREFIX)" == ""
install:
	@echo PREFIX is not defined
	@echo Use `nmake install PREFIX=directory`
	@echo.
	@exit /B 1
!ELSE
install: all
	@-md "$(PREFIX)" 2>NUL
!IF "$(TARGET)" == "dll"
	@xcopy /I /Y /Q "$(WORKDIR)\*.dll" "$(PREFIX)\bin"
!IF DEFINED(_PDB)
	@xcopy /I /Y /Q "$(WORKDIR)\*.pdb" "$(PREFIX)\bin"
!ENDIF
!ELSE
!IF DEFINED(_PDB)
	@xcopy /I /Y /Q "$(WORKDIR)\*.pdb" "$(PREFIX)\$(_LIB)"
!ENDIF
!ENDIF
	@xcopy /I /Y /Q "$(WORKDIR)\*.lib" "$(PREFIX)\$(_LIB)"
	@xcopy /I /Y /Q "$(SRCDIR)\c\include\brotli\*.h" "$(PREFIX)\include\brotli"
!ENDIF

clean:
	@-rd /S /Q $(WORKDIR) 2>NUL
