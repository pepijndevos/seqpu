%define slide_size 10
%define returnpointer 0x1000
%define slide_src 0x1001
%define slide_dest 0x1002
%define slide_counter 0x1003
%define slide_index 0x1004
%define vram 0x2000
// sign-extended
%define btnio 0x1ff

// fake button input
b a 1
b sp btnio
st

// set slide_index to 0
b a 0
lit slide_index
b sp
st

// load slide 0
lit slides
b a
lit slide_src
b sp
st // store slide address

lit returnpointer
b sp
lit button_loop
b a
st // return address
lit loadSlide
b pc

// read buttons
button_loop:
lit returnpointer
b sp
lit ret02
b a
st // return address
b sp btnio
ld
b a
eq a 0b01 // button 1
lit nextSlide
b pcc // nextSlide if button 1
eq a 0b10 // button 2
lit prevSlide
b pcc // prevSlide if button 1
lit button_loop
b pc // else loop
ret02:

lit returnpointer
b sp
lit button_loop // return to loop
b a
st // return address
lit loadSlide
b pc

// should never get here
lit end
end: b pc

loadSlide:
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
st // slide_dest=&dest++
lit slide_src
b sp
ld // b=*src
b a
add a 1
lit slide_src
st // slide_src=&src++
lit slide_counter
b sp
ld // b=counter
b a
sub a 1
st
gt a 0 // if counter > 0
lit copy_loop
b pcc // jump to copy_loop

lit returnpointer
b sp
ld
b pc

nextSlide:
lit slide_index
b sp
ld
b a // a=slide_index
lit slide_size
add a // a=idx+size
lit slide_index
b sp
st // store slide_index
lit slides
add a // a=slides+idx+size
lit slide_src
b sp
st // store slide_src
lit returnpointer
b sp
ld
b pc

prevSlide:
lit slide_index
b sp
ld
b a // a=slide_index
lit slide_size
sub a // a=idx-size
lit slide_index
b sp
st // store slide_index
lit slides
add a // a=slides+idx+size
lit slide_src
b sp
st // store slide_src
lit returnpointer
b sp
ld
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
lit 10
lit 11
lit 12
lit 13
lit 14
lit 15
lit 16
lit 17
lit 18
lit 19
