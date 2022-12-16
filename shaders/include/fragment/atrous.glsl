/***********************************************/
/*        Copyright (C) NobleRT - 2022         */
/*   Belmu | GNU General Public License V3.0   */
/*                                             */
/* By downloading this content you have agreed */
/*     to the license and its terms of use.    */
/***********************************************/

/* 
    SOURCES / CREDITS:
    Jakemichie97:                               - jakemichie97#7237
    Samuel:       https://github.com/swr06      - swr#1793
    L4mbads:                                    - L4mbads#6227
    SixthSurge:   https://github.com/sixthsurge - SixthSurge#3922
    Alain Galvan: https://alain.xyz/blog/ray-tracing-denoising
    Jan Dundr:    https://cescg.org/wp-content/uploads/2018/04/Dundr-Progressive-Spatiotemporal-Variance-Guided-Filtering-2.pdf
*/

const float aTrous[3] = float[3](1.0, 2.0 / 3.0, 1.0 / 6.0);
const float steps[5]  = float[5](
    ATROUS_STEP_SIZE * 0.0625,
    ATROUS_STEP_SIZE * 0.125,
    ATROUS_STEP_SIZE * 0.25,
    ATROUS_STEP_SIZE * 0.5,
    ATROUS_STEP_SIZE
);

float getATrousNormalWeight(vec3 normal, vec3 sampleNormal) {
    return pow(max0(dot(normal, sampleNormal)), NORMAL_WEIGHT_SIGMA);
}

float getATrousDepthWeight(float depth, float sampleDepth, vec2 dgrad, vec2 offset) {
    return exp(-abs(depth - sampleDepth) / (abs(DEPTH_WEIGHT_SIGMA * dot(dgrad, offset)) + EPS));
}

float getATrousLuminanceWeight(float luminance, float sampleLuminance, float luminancePhi) {
    return exp(-abs(luminance - sampleLuminance) * luminancePhi);
}

void aTrousFilter(inout vec3 color, sampler2D tex, vec2 coords, inout vec4 moments, int passIndex) {
    Material mat = getMaterial(coords);
    if(mat.depth0 == 1.0) return;

    float totalWeight = 1.0, totalWeightSquared = 1.0;
    vec2 stepSize     = steps[passIndex] * pixelSize;

    float frames = float(texture(colortex5, coords).a > 4.0);
    vec2 dgrad   = vec2(dFdx(mat.depth0), dFdy(mat.depth0));

    float centerLuma   = luminance(color);
    float variance     = texture(colortex11, coords).b;
    float luminancePhi = 1.0 / (LUMA_WEIGHT_SIGMA * sqrt(variance) + EPS);

    moments = texture(colortex11, texCoords);

    for(int x = -1; x <= 1; x++) {
        for(int y = -1; y <= 1; y++) {
            if(all(equal(ivec2(x,y), ivec2(0)))) continue;

            vec2 offset        = vec2(x, y) * stepSize;
            vec2 sampleCoords  = coords + offset;

            if(clamp01(sampleCoords) != sampleCoords) continue;

            Material sampleMat = getMaterial(sampleCoords);
            vec3 sampleColor   = texelFetch(tex, ivec2(sampleCoords * viewSize), 0).rgb;

            float normalWeight = getATrousNormalWeight(mat.normal, sampleMat.normal);
            float depthWeight  = getATrousDepthWeight(mat.depth0, sampleMat.depth0, dgrad, offset);
            float lumaWeight   = mix(1.0, getATrousLuminanceWeight(centerLuma, luminance(sampleColor), luminancePhi), frames);

            float weight  = clamp01(normalWeight * depthWeight * lumaWeight);
                  weight *= aTrous[abs(x)] * aTrous[abs(y)];
           
            color              += sampleColor * weight;
            totalWeight        += weight;
            totalWeightSquared += weight * weight;
        }
    }
    color      = color / totalWeight;
    moments.b *= totalWeightSquared;
}
