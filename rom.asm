%define stackpointer 0x1000
%define stackbottom 0x0fff
lit stackbottom
b sp

start:
lit ret01
b a
push
lit loadSlide
b pc
ret01:

a a
a a
a a
a a

lit start
b pc

loadSlide:
a a
a a
a a
a a

lit ret02
b a
push
lit doThing
b pc
ret02:

a a
a a
a a
a a

pop
b pc
 
doThing:
a a
a a
a a
a a

pop
b pc
