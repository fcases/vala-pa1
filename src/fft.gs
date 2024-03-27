[indent=4]

uses Math 
const PI: double = Math.PI

exception FFTError
    SizeNotEql
    SizeNotPow2

def fft(ref real: array of F, ref imag: array of F) of F raises FFTError 
     if real.length != imag.length
        raise new FFTError.SizeNotEql("Sizes are not equal, chaval")
    if popCount(real.length) != 1
        raise new FFTError.SizeNotPow2("Size not 2 power, chaval")
    shuffle of F (ref real,ref imag)
    compute of F (ref real, ref imag)

 
//def ifft(ref real: array of F, ref  imag: array of F) of F raises FFTError 
//    if real.length != imag.length
//        raise new FFTError.SizeNotEql("Sizes are not equal, chaval")
//    if @popCount(real.length) != 1
//        raise new FFTError.SizeNotPow2("Size not 2 power, chaval")
//    for v in imag
//        v = -v
//    try
//        fft of F(ref real, ref imag)
//    except ex: FFTError  
//        pass
//    for v in real
//        v = v / (F)real.length
//    for v in imag
//        v = v / (F)imag.length * (F)(-1.0)
//
def shuffle(ref real: array of F,ref imag: array of F) of F
    shrAmount: int = sizeof(uint) - ctz(real.length)
    for var i = 0 to real.length
        var j = bitReverse(i) >> shrAmount

 
def compute(ref real: array of F, ref imag: array of F) of F
    step: uint = 1
    while step < real.length
        step = 1
        group: uint = 0
        jump: uint = step << 1
        stp: F = (F)step
        while group < step
            group += 1
            rads: F = (F)(-PI) * (F)group / stp
            var t_re = Math.cos(rads)
            var t_im = Math.sin(rads)
            var pair = group
            while pair < real.length
                pair += jump
                var match = pair + step
                var p_re = t_re * real[match] - t_im * imag[match]
                var p_im = t_im * real[match] + t_re * imag[match]
                real[match] = real[pair] - p_re
                imag[match] = imag[pair] - p_im
                real[pair] += p_re
                imag[pair] += p_im

def bitReverse  (num: uint16) : uint16 
    len: int16 = 16// sizeof(typeof(num)) 
    var decomp=new array of uint16[len]
    for var i = 0 to len
        var aux=num
        var j=0
        while (j<i)
            aux= aux/2
            j++
        decomp[i]= aux & 1

        j=15-i
        while (j>0)
            decomp[i]= decomp[i]*2
            j--
    comp: int16 = 0
    for var i= 0 to len
        comp= comp | decomp[i]
    
    return comp
 

init
    a: uint16=21
    print "%d - %d", a, bitReverse(a)
 
