%define slide_size 600
%define btnio 0x0fff
%define returnpointer 0x0ffe
%define slide_src 0x0ffd
%define slide_dest 0x0ffc
%define slide_end 0x10ffb
%define slide_index 0x0ffa
%define vram 0x1000

// fake button input
b a 1
lit btnio
xch b
st

// set slide_index to 0
b a 0
lit slide_index
xch b
st

// load slide 0
lit slides
b a
//lit 600
//add a 
lit slide_src
xch b
st // store slide address

lit returnpointer
xch b
lit button_loop
b a
st // return address
lit loadSlide
b pc

// read buttons
button_loop:
lit returnpointer
xch b
lit ret02
b a
st // return address
lit btnio
xch b
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
xch b
lit button_loop // return to loop
b a
st // return address
lit loadSlide
b pc

// should never get here
lit end
end: b pc

loadSlide:
// set slide_dest
lit vram
b a
lit slide_dest
xch b
st
// set slide_end
lit slide_src
xch b
ld
b a
lit slide_size
add a
lit slide_end
xch b
st

lit slide_dest
xch b
ld // b=&dest
xch b
xch sp' // sp'=&dest
lit slide_src
xch b
ld // b=&source
b a 
sub b 1 // pop pre-increments
xch b // sp=&source, sp'=&dest

copy_loop:
pop add 1
xch sp'
b a
push add 1
xch sp' // a=word, sp=&source++, sp'=&dest++

xch b
b a // a=&source
lit slide_end
xch b // a=&source, sp=slide_end, sp'=&dest
ld // a=&source, b=&end, sp'=&dest
eq a
lit copy_loop_end
b pcc // break loop if &source=&end
a b
xch b // sp=&source, sp'=&dest
lit copy_loop
b pc // loop

copy_loop_end:
lit returnpointer
xch b
ld
b pc

nextSlide:
lit slide_index
xch b
ld
b a // a=slide_index
lit slide_size
add a // a=idx+size
lit slide_index
xch b
st // store slide_index
lit slides
add a // a=slides+idx+size
lit slide_src
xch b
st // store slide_src
lit returnpointer
xch b
ld
b pc

prevSlide:
lit slide_index
xch b
ld
b a // a=slide_index
lit slide_size
sub a // a=idx-size
lit slide_index
xch b
st // store slide_index
lit slides
add a // a=slides+idx+size
lit slide_src
xch b
st // store slide_src
lit returnpointer
xch b
ld
b pc

slides:
