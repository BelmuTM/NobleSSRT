/***********************************************/
/*        Copyright (C) NobleRT - 2022         */
/*   Belmu | GNU General Public License V3.0   */
/*                                             */
/* By downloading this content you have agreed */
/*     to the license and its terms of use.    */
/***********************************************/

//////////////////////////////////////////////////////////
/*--------------- MATRICES OPERATIONS ------------------*/
//////////////////////////////////////////////////////////

vec2 diagonal2(mat4 mat) { return vec2(mat[0].x, mat[1].y); 		   }
vec3 diagonal3(mat4 mat) { return vec3(mat[0].x, mat[1].y, mat[2].z);  }
vec4 diagonal4(mat4 mat) { return vec4(mat[0].x, mat[1].y, mat[2].zw); }

vec2 projectOrtho(mat4 mat, vec2 v) { return diagonal2(mat) * v + mat[3].xy;  }
vec3 projectOrtho(mat4 mat, vec3 v) { return diagonal3(mat) * v + mat[3].xyz; }
vec3 transform   (mat4 mat, vec3 v) { return mat3(mat)      * v + mat[3].xyz; }

//////////////////////////////////////////////////////////
/*--------------------- SHADOWS ------------------------*/
//////////////////////////////////////////////////////////

float getDistortionFactor(vec2 coords) {
	return cubeLength(coords) * SHADOW_DISTORTION + (1.0 - SHADOW_DISTORTION);
}

vec2 distortShadowSpace(vec2 position) {
	return position / getDistortionFactor(position.xy);
}

vec3 distortShadowSpace(vec3 position) {
	position.xy = distortShadowSpace(position.xy);
	position.z *= SHADOW_DEPTH_STRETCH;
	return position;
}

//////////////////////////////////////////////////////////
/*--------------- SPACE CONVERSIONS --------------------*/
//////////////////////////////////////////////////////////

vec3 screenToView(vec3 screenPos) {
	screenPos = screenPos * 2.0 - 1.0;
	return projectOrtho(gbufferProjectionInverse, screenPos) / (gbufferProjectionInverse[2].w * screenPos.z + gbufferProjectionInverse[3].w);
}

vec3 viewToScreen(vec3 viewPos) {
	return (projectOrtho(gbufferProjection, viewPos) / -viewPos.z) * 0.5 + 0.5;
}

vec3 sceneToView(vec3 scenePos) {
	return transform(gbufferModelView, scenePos);
}

vec3 viewToScene(vec3 viewPos) {
	return transform(gbufferModelViewInverse, viewPos);
}

vec3 worldToView(vec3 worldPos) {
	return mat3(gbufferModelView) * (worldPos - cameraPosition);
}

vec3 viewToWorld(vec3 viewPos) {
	return viewToScene(viewPos) + cameraPosition;
}

mat3 constructViewTBN(vec3 viewNormal) {
	vec3 tangent = normalize(cross(gbufferModelViewInverse[1].xyz, viewNormal));
	return mat3(tangent, cross(tangent, viewNormal), viewNormal);
}

vec3 getViewPos0(vec2 coords) {
    return screenToView(vec3(coords, texture(depthtex0, coords).r));
}

vec3 getViewPos1(vec2 coords) {
    return screenToView(vec3(coords, texture(depthtex1, coords).r));
}

// https://wiki.shaderlabs.org/wiki/Shader_tricks#Linearizing_depth
float linearizeDepth(float depth) {
    depth = depth * 2.0 - 1.0;
    return 2.0 * far * near / (far + near - depth * (far - near));
}

float linearizeDepthFast(float depth) {
	return (near * far) / (depth * (near - far) + far);
}

//////////////////////////////////////////////////////////
/*---------------- MATERIAL CONVERSIONS ----------------*/
//////////////////////////////////////////////////////////

float f0ToIOR(float F0) {
	F0 = sqrt(F0) * 0.99999;
	return (1.0 + F0) / (1.0 - F0);
}

vec3 f0ToIOR(vec3 F0) {
	F0 = sqrt(F0) * 0.99999;
	return (1.0 + F0) / (1.0 - F0);
}

float iorToF0(float ior) {
	float a = (ior - airIOR) / (ior + airIOR);
	return a * a;
}

//////////////////////////////////////////////////////////
/*------------------ REPROJECTION ----------------------*/
//////////////////////////////////////////////////////////

vec3 getVelocity(vec3 currPos) {
    vec3 cameraOffset = (cameraPosition - previousCameraPosition) * float(linearizeDepthFast(currPos.z) >= MC_HAND_DEPTH);

    vec3 prevPos = transform(gbufferPreviousModelView, cameraOffset + viewToScene(screenToView(currPos)));
         prevPos = (projectOrtho(gbufferPreviousProjection, prevPos) / -prevPos.z) * 0.5 + 0.5;

    return currPos - prevPos;
}
