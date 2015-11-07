# Makefile for sysdig-simulator by Théophile Bastian <contact@tobast.fr>

CMP=ocamlopt
YACC=menhir
LEX=ocamllex
CMPFLAGS=
CMPLIBS=-I netlist
TARGET=simcomp
OBJS= netlist/netlist_ast.cmx \
	netlist/netlist_parser.mly.cmx \
	netlist/netlist_lexer.mll.cmx \
	netlist/netlist.cmx \
	netlist/netlist_printer.cmx \
	unionFind.cmx \
	checkNetlist.cmx \
	parameters.cmx \
	cpp.cmx \
	depGraph.cmx \
	transformNetlist.cmx \
	genCode.cmx \
	skeleton.cmx \
	main.cmx

#########################################################################

OBJS_OUT1= $(OBJS:.mly.cmx=.cmx)
OBJS_OUT2= $(OBJS_OUT1:.mll.cmx=.cmx)
OBJS_OUT3= $(OBJS_OUT2:.mll.cmo=.cmx)
OBJS_OUT= $(OBJS_OUT3:.mly.cmo=.cmo)

all: $(TARGET)

$(TARGET): $(YACCOBJS) $(OBJS)
	$(CMP) $(CMPLIBS) $(CMPFLAGS) -o $@ $(OBJS_OUT)
	@rm cpp.ml # Not regenerated if not deleted

%.cmx: %.ml
	([ -f "$<i" ] && $(CMP) $(CMPLIBS) $(CMPFLAGS) -c "$<i" ; /usr/bin/true)
	$(CMP) $(CMPLIBS) $(CMPFLAGS) -c $<

cpp.ml: genCpp.sh
	bash ./genCpp.sh > cpp.ml

%.mly.cmx: %.mly
	$(YACC) $<
	$(CMP) $(CMPLIBS) $(CMPFLAGS) -c $*.mli
	$(CMP) $(CMPLIBS) $(CMPFLAGS) -c $*.ml

%.mll.cmx: %.mll
	$(LEX) $<
	$(CMP) $(CMPLIBS) $(CMPFLAGS) -c $*.ml

.PHONY: clean

clean:
	rm -f *.cmi *.cmx *.cmo *.mly.ml *.mly.mli *.o cpp.ml
	@make -C netlist clean

mrproper: clean
	rm -f $(TARGET)

