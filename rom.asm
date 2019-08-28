%define stackpointer 0x1000
%define stackbottom 0x0fff
%define vram 0x2000
%define slide_src 0x1001
%define slide_dest 0x1002
%define slide_counter 0x1003
%define slide_size 10

lit slides
b a
lit slide_src
b sp
st // store slide address

lit stackbottom
b sp
lit ret01
b a
push // return address
lit loadSlide
b pc
ret01:

lit end
end: b pc

loadSlide:
popa add 0 // a=sp
lit stackpointer
b sp
st // save sp
lit vram
b a
lit slide_dest
b sp
st // set slide_dest
lit slide_size
b a
lit slide_counter
b sp
st // initiate counter

copy_loop:
lit slide_src
b sp
ld // b=*source
b sp
ld // b=word
b a
lit slide_dest
b sp
ld // b=*dest
b sp
pusha add 1 // copy word do dest, a=sp++
lit slide_dest
b sp
st // slide_dest=*dest++
lit slide_src
b sp
ld // b=*src
b a
add a 1
lit slide_src
st // slide_src=*src++
lit slide_counter
b sp
ld // b=counter
b a
sub a 1
st
gt a 0 // if counter > 0
lit copy_loop
b pcc // jump to copy_loop

pop // return address
b pc



slides:
lit 0
lit 1
lit 2
lit 3
lit 4
lit 5
lit 6
lit 7
lit 8
lit 9
