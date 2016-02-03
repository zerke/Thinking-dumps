module Codec

using Images

export
    blockdct6_with_noise_and_high_freq, 
    blockdct6_with_noise, 
    blockdct6, blockidct

function make_noise(block, scale)
    scale * rand( size(block) )
end

function blockdct6_with_noise_and_high_freq(img, noise_scale, hf_flag)
    pixels = convert(Array{Float32}, img.data)
    y,x = size(pixels)

    # break into parts
    outx, outy = floor(Integer, x/8), floor(Integer, y/8)
    bx, by = 1:8:outx*8, 1:8:outy*8

    mask = zeros(8,8)
    mask[1:3, 1:3] = [1 1 1; 1 1 0; 1 0 0]
    freqs = Array(Float32, (outy*8, outx*8))

    for i = bx, j = by
        tmp = pixels[j:j+7, i:i+7]
        tmp = dct(tmp)
        # adding noise to frequencies
        if noise_scale > 0
            if hf_flag
                # only make noise to high freq parts
                mask2 = ones(8,8) - mask
                noise = make_noise(tmp, noise_scale)
                tmp .+= noise .* mask2
            else
                tmp .+= make_noise(tmp, noise_scale)
            end
        end
        tmp .*= mask
        freqs[j:j+7, i:i+7] = tmp
    end

    freqs
end

function blockdct6_with_noise(img, noise_scale)
    blockdct6_with_noise_and_high_freq(img, noise_scale, false)
end

function blockdct6(img)
    blockdct6_with_noise(img,0)
end

function blockidct(freqs)
    y,x = size(freqs)
    bx, by = 1:8:x, 1:8:y
    
    pixels = Array(Float32, size(freqs))
    for i = bx, j = by
        # https://forums.pragprog.com/forums/351/topics/13474
        pixels[j:j+7,i:i+7] = idct(freqs[j:j+7,i:i+7])
    end
    grayim(pixels)
end


end
