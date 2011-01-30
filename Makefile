PATH_BIN	=	bin
PATH_SRC	=	src
PATH_INCLUDE	=	include

NAME		=	jambi

INCLUDES	=	/I..\$(PATH_INCLUDE) /Ic:\masm32\include
LIBRARIES	=	/LIBPATH:c:\masm32\lib

$(PATH_BIN)\$(NAME).exe	:	$(PATH_SRC)/$(NAME).obj
				@echo "Linking..."
				Link /SUBSYSTEM:CONSOLE $(LIBRARIES) /OUT:$(PATH_BIN)\$(NAME).exe $(PATH_SRC)\$(NAME).obj

all	:	$(PATH_BIN)\$(NAME).exe

$(PATH_SRC)\$(NAME).obj	:	$(PATH_SRC)/injection.asm
				@echo "Assembling"
				cd $(PATH_SRC)
			        ml /c /coff /Cp $(INCLUDES) $(NAME).asm
				cd ..

clean	:
		del /Q $(PATH_SRC)\*.obj

fclean	:	clean
		del /Q $(PATH_BIN)\*.exe

re	:	fclean $(PATH_BIN)\$(NAME).exe 

