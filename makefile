CHARTTYPE = enroute

ORIGINALDIR =./original
LINKDIR =./sourceRasters/$(CHARTTYPE)
SHAPEDIR =./clippingShapes/$(CHARTTYPE)
EXPANDEDDIR =./expandedRasters/$(CHARTTYPE)
CLIPPEDDIR =./clippedRasters/$(CHARTTYPE)
MBTILESDIR =./mbtiles/$(CHARTTYPE)

#Root of downloaded chart info
chartsRoot=/media/sf_Shared_Folder/charts/

#Where the original .tif files are from aeronav
originalHeliDirectory="$(chartsRoot)/aeronav.faa.gov/content/aeronav/heli_files/"
originalTacDirectory="$(chartsRoot)/aeronav.faa.gov/content/aeronav/tac_files/"
originalWacDirectory="$(chartsRoot)/aeronav.faa.gov/content/aeronav/wac_files/"
originalSectionalDirectory="$(chartsRoot)/aeronav.faa.gov/content/aeronav/sectional_files/"
originalGrandCanyonDirectory="$(chartsRoot)/aeronav.faa.gov/content/aeronav/grand_canyon_files/"
originalEnrouteDirectory="$(chartsRoot)/aeronav.faa.gov/enroute/01-08-2015/"

#Root of directories where our processed images etc will be saved
destinationRoot=/home/jlmcgraw/Documents/myPrograms/mergedCharts


LINKS    = $(wildcard $(LINKDIR)/*.tif)
SHAPES   = $(patsubst $(LINKDIR)/%.tif,$(SHAPEDIR)/%.shp,$(LINKS)) 
EXPANDED = $(patsubst $(LINKDIR)/%.tif,$(EXPANDEDDIR)/expanded-%.tif,$(LINKS)) 
CLIPPED  = $(patsubst $(LINKDIR)/%.tif,$(CLIPPEDDIR)/clipped-expanded-%.tif,$(LINKS)) 

all: FRESHEN LINKS $(CLIPPED)
# 	@echo $(LINKS)
# 	@echo $(SHAPES)
# 	@echo $(EXPANDED)
# 	@echo $(CLIPPED)
	
$(CLIPPED): $(CLIPPEDDIR)/clipped-expanded-%.tif: $(SHAPEDIR)/%.shp $(EXPANDEDDIR)/expanded-%.tif
# $(CLIPPED): $(SHAPES) $(EXPANDED)
	@echo Build CLIPPED: $@
	@echo Changed Dendencies: $?
	@echo Current Dependency: $< 
# 	touch $@
	echo ./enroute.sh     $(originalEnrouteDirectory)     $(destinationRoot)
	@echo ----------------------------------------------------------------------------------------
	
$(EXPANDED):  $(EXPANDEDDIR)/expanded-%.tif: $(LINKDIR)/%.tif
# $(EXPANDED):  $(LINKDIR)/%.tif
	@echo Build EXPAND: $@
	@echo Changed Dendencies: $?
	@echo Current Dependency: $<
	touch $@

$(SHAPES):  $(SHAPEDIR)/%.shp: $(LINKDIR)/%.tif
	@echo Build SHAPE: $@
	@echo Changed Dendencies: $?
	@echo Current Dependency: $< 
	touch $@

$(LINKS):  
	@echo Build LINK: $@
	@echo Changed Dendencies: $?
	@echo Current Dependency: $< 
# 	@touch $@
	
FRESHEN:
	echo ./freshenLocalCharts.sh $(chartsRoot)

LINKS:
# 	./updateLinks.sh $(originalEnrouteDirectory) $(destinationRoot) $(CHARTTYPE)
# .PHONY: $(SHAPES) $(LINKS)

# $(CLIPPEDDIR)/%.tif: $(SHAPEDIR)/%.shp $(EXPANDEDDIR)/%.tif
# # 	$(CC) -c -o $@ $< $(CFLAGS)
# 	echo $@ $< $
# 	echo $(LINKS)
# 	echo $(SHAPES)
	
# hellomake: $(OBJ)
# 	gcc -o $@ $^ $(CFLAGS) $(LIBS)
# 
# .PHONY: clean
# 
# clean:
# 	rm -f $(ODIR)/*.o *~ core $(INCDIR)/*~ 