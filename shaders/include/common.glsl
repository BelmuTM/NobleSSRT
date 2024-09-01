/***********************************************/
/*          Copyright (C) 2024 Belmu           */
/*       GNU General Public License V3.0       */
/***********************************************/

#include "/include/uniforms.glsl"

#include "/include/utility/rng.glsl"
#include "/include/utility/math.glsl"
#include "/include/utility/color.glsl"

#include "/include/utility/transforms.glsl"

#include "/include/utility/material.glsl"

/*
const vec2 hiZOffsets[] = vec2[](
	vec2(0.0, 0.0  ),
	vec2(0.5, 0.0  ),
    vec2(0.5, 0.25 ),
    vec2(0.5, 0.375)
);

float find2x2MinimumDepth(vec2 coords, int scale) {
    coords *= viewSize;

    return minOf(vec4(
        texelFetch(depthtex0, ivec2(coords)                      , 0).r,
        texelFetch(depthtex0, ivec2(coords) + ivec2(1, 0) * scale, 0).r,
        texelFetch(depthtex0, ivec2(coords) + ivec2(0, 1) * scale, 0).r,
        texelFetch(depthtex0, ivec2(coords) + ivec2(1, 1) * scale, 0).r
    ));
}

vec2 getDepthTile(vec2 coords, int lod) {
	return coords / exp2(lod) + hiZOffsets[lod - 1];
}
*/
