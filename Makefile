SOURCES = $(shell echo VP8L/*.cs)

VP8L.exe: $(SOURCES)
	mcs $^ -out:$@ -debug -r:System.Drawing
