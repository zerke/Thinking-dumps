macro run_backwards(xs)
    # xs is supposed to be a block of statements
    # so simply reversing it does the trick
    # however, there are LineNumberNode elements in the AST
    # which is put backwards after the transformation
    # I don't really like this LineNumberNode stuff because
    # naturally it makes more sense attaching it to expressions
    # rather than making itself some AST component
    # if this macro does something wrong because of this LineNumberNode stuff
    # don't blame me.
    reverse!(xs.args)
    xs
end

@run_backwards begin
    println(3)
    println(2)
    println(1)
end

# note: the exercise asks us about effects of modification on
# *frequencies*, make sure to operate on a frequency domain (after DCT)

push!(LOAD_PATH, pwd())
using TestImages, ImageView
using Codec

img = testimage("cameraman")

function view_with_noise(img,noise_scale)
    freqs = blockdct6_with_noise(img,noise_scale)
    img2 = blockidct(freqs)
    view(img2)
end

map( x-> view_with_noise(img,x), [0,0.1,1,10])

readline(STDIN)
