make cpu_rtl.il
yosys -p "tee -o timing.txt ltp t:*DFF* %n" cpu_rtl.il
selection=$(gawk 'match($0, "\\(via (.*)\\)", ary) {print ary[1] " %co2"}' timing.txt | tr '\n' ' ')
yosys -p "show $selection" cpu_rtl.il
